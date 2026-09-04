import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/material.dart' show Colors, EdgeInsets, Icons;
import 'package:shinjuu_league/config/app_config.dart';
import 'package:shinjuu_league/services/performance_service.dart';
import 'package:shinjuu_league/data/mecha_catalog.dart';
import 'package:shinjuu_league/game/impact_line.dart';
import 'package:shinjuu_league/game/isometric_projection.dart';
import 'package:shinjuu_league/game/kill_burst.dart';
import 'package:shinjuu_league/game/lane_floor.dart';
import 'package:shinjuu_league/game/mecha_token.dart';
import 'package:shinjuu_league/game/open_field.dart';
import 'package:shinjuu_league/game/skill_burst.dart';
import 'package:shinjuu_league/game/damage_number.dart';
import 'package:shinjuu_league/game/skill_visual_effect.dart';
import 'package:shinjuu_league/game/buff_indicator.dart';
import 'package:shinjuu_league/data/models/skill_model.dart';
import 'package:shinjuu_league/services/battle_engine_service.dart';

/// 参加者の状態（位置・生死）だけを受け取って描画するレンダラー。
/// 対戦のシミュレーションロジックは持たない（BattleEngine が唯一の正）。
///
/// 自キャラのみジョイスティックでフリー移動できる（Pokémon UNITE風の接近戦）。
/// 味方/Botの位置もこのクラス内で緩やかに動かすが、あくまで見た目上の移動演出であり、
/// 撃破判定・勝敗などのシミュレーションはBattleEngineが引き続き唯一の正。
class BattlefieldGame extends FlameGame {
  static const _projection = IsometricProjection();
  static const _laneCenterYs = [-1.8, 1.8];
  static const _selfMoveSpeed = 90.0; // world px/sec
  static const _botWanderSpeed = 22.0; // world px/sec（自キャラより控えめ）
  // 等角投影はtileWidth(96)とtileHeight(48)が異なるため、画面座標上の距離は
  // 縦横で伸縮する（等方ではない）。射程判定は必ずグリッド空間（toGrid変換後）の
  // 真の距離で行い、画面上で歪んだ楕円形の間合いにならないようにする。
  static const _attackRangeGrid = 1.0;
  static const _skillRadiusGrid = 2.0;
  static const _attackRange = 46.0; // Bot徘徊の見た目上の距離判定にのみ使用
  static const _skillRadius = 90.0; // SkillBurstの描画半径（画面ピクセル）
  static const _playfieldHalfWidth = 900.0;
  static const _playfieldHalfHeight = 560.0;

  final Map<String, MechaToken> _tokens = {};
  final _random = Random();
  double _shakeMagnitude = 0.0;
  double _flashAlpha = 0.0;
  final Vector2 _cameraFollowPos = Vector2.zero();
  late final PerformanceService _performanceService = PerformanceService();

  JoystickComponent? _joystick;
  MechaToken? _selfToken;
  double _targetScanTimer = 0.0;
  double _wanderRetargetTimer = 0.0;
  final Map<String, Vector2> _wanderTargets = {};

  /// 攻撃可能な射程内に敵がいる場合、そのuserIdを保持する。UIの攻撃ボタン有効化に使う。
  final ValueNotifier<String?> attackTargetId = ValueNotifier(null);

  @override
  Color backgroundColor() => const Color(0xFF14171F);

  @override
  Future<void> onLoad() async {
    add(
      OpenField(
        halfWidth: _playfieldHalfWidth,
        halfHeight: _playfieldHalfHeight,
      )..priority = -1000,
    );
    for (var lane = 0; lane < AppConfig.teamsCount; lane++) {
      final color = lane.isEven
          ? const Color(0xFF1E2536)
          : const Color(0xFF241B2E);
      add(LaneFloor(laneCenterY: _laneCenterYs[lane], color: color));
    }
    camera.viewfinder.anchor = Anchor.center;

    final joystick = JoystickComponent(
      knob: CircleComponent(
        radius: 14,
        paint: Paint()..color = Colors.white.withValues(alpha: 0.75),
      ),
      background: CircleComponent(
        radius: 36,
        paint: Paint()..color = Colors.white.withValues(alpha: 0.2),
      ),
      margin: const EdgeInsets.only(left: 24, bottom: 24),
    );
    _joystick = joystick;
    // カメラシェイク/ズームの影響を受けないHUD空間に配置
    camera.viewport.add(joystick);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // マップ全体ではなく「プレイヤー周辺の視界窓」に合わせてズームを固定する
    // （自由に歩き回れるようになったため、常に自キャラを画面中央付近に収める設計）
    const viewWindowWidth = 420.0;
    const viewWindowHeight = 260.0;
    final zoom = min(
      size.x / viewWindowWidth,
      size.y / viewWindowHeight,
    ).clamp(0.6, 2.5);
    camera.viewfinder.zoom = zoom;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // フレームレート計測
    _performanceService.recordFrame(dt);

    // カメラは自キャラの位置へ滑らかに追従する
    final followTarget = _selfToken?.position ?? Vector2.zero();
    final followLerp = (dt * 4).clamp(0.0, 1.0);
    _cameraFollowPos.setFrom(
      _cameraFollowPos + (followTarget - _cameraFollowPos) * followLerp,
    );

    Vector2 shakeOffset = Vector2.zero();
    if (_shakeMagnitude > 0) {
      _shakeMagnitude = (_shakeMagnitude - dt * 6).clamp(0.0, 1.0);
      shakeOffset = Vector2(
        (_random.nextDouble() * 2 - 1) * _shakeMagnitude * 14,
        (_random.nextDouble() * 2 - 1) * _shakeMagnitude * 14,
      );
    }
    camera.viewfinder.position = _cameraFollowPos + shakeOffset;

    if (_flashAlpha > 0) {
      _flashAlpha = (_flashAlpha - dt * 4).clamp(0.0, 1.0);
    }

    _updateSelfMovement(dt);
    _updateBotWander(dt);

    _targetScanTimer += dt;
    if (_targetScanTimer >= 0.15) {
      _targetScanTimer = 0.0;
      _updateAttackTarget();
    }
  }

  /// ジョイスティックの入力方向へ自キャラを毎フレーム移動させる。
  void _updateSelfMovement(double dt) {
    final self = _selfToken;
    final joystick = _joystick;
    if (self == null || joystick == null || !self.isAlive) return;
    if (joystick.direction == JoystickDirection.idle) return;

    final delta = joystick.relativeDelta;
    self.position += delta * _selfMoveSpeed * dt;
    self.position.x = self.position.x.clamp(
      -_playfieldHalfWidth,
      _playfieldHalfWidth,
    );
    self.position.y = self.position.y.clamp(
      -_playfieldHalfHeight,
      _playfieldHalfHeight,
    );
    // 奥/手前関係をリアルタイムに更新（移動に伴い前後の重なりが変わるため）
    self.priority = self.position.y.round();
  }

  /// 味方/Botを最寄りの生存中の敵へ向けて緩やかに近づける視覚的な移動演出。
  /// BattleEngineのシミュレーション（撃破判定・勝敗）には一切影響しない、描画専用の位置更新。
  void _updateBotWander(double dt) {
    _wanderRetargetTimer += dt;
    final shouldRetarget = _wanderRetargetTimer >= 1.5;
    if (shouldRetarget) _wanderRetargetTimer = 0.0;

    for (final token in _tokens.values) {
      if (token.isSelf || !token.isAlive) continue;

      if (shouldRetarget || !_wanderTargets.containsKey(token.userId)) {
        final nearestEnemy = _findNearestAliveEnemy(token);
        if (nearestEnemy != null) {
          // 敵の手前で足を止める（重なって描画されないよう射程の8割手前を目標にする）
          final toEnemy = nearestEnemy.position - token.position;
          final stopShort = toEnemy.length > _attackRange
              ? toEnemy.normalized() * (toEnemy.length - _attackRange * 0.8)
              : Vector2.zero();
          _wanderTargets[token.userId] = token.position + stopShort;
        }
      }

      final target = _wanderTargets[token.userId];
      if (target == null) continue;

      final toTarget = target - token.position;
      if (toTarget.length < 4) continue;

      final step = toTarget.normalized() * _botWanderSpeed * dt;
      token.position += step.length2 < toTarget.length2 ? step : toTarget;
      token.priority = token.position.y.round();
    }
  }

  /// 画面座標上の2点間の「真の」距離をグリッド空間で測る（等角投影の歪みを除去）。
  double _gridDistance(Vector2 screenA, Vector2 screenB) {
    final gridA = _projection.toGrid(screenA);
    final gridB = _projection.toGrid(screenB);
    return (gridA - gridB).length;
  }

  /// 同じレーンの生存中の敵のみを対象にする（BattleEngineの自動交戦がレーン限定なのと
  /// 揃えないと、自由に歩き回れる自キャラが本来交戦できないレーンの敵を攻撃できてしまう）。
  MechaToken? _findNearestAliveEnemy(MechaToken from) {
    MechaToken? nearest;
    var nearestDist = double.infinity;
    for (final other in _tokens.values) {
      if (other.userId == from.userId) continue;
      if (other.team == from.team) continue;
      if (other.lane != from.lane) continue;
      if (!other.isAlive) continue;
      final dist = _gridDistance(other.position, from.position);
      if (dist < nearestDist) {
        nearestDist = dist;
        nearest = other;
      }
    }
    return nearest;
  }

  /// 自キャラの射程内にいる最も近い敵を探し、攻撃可能対象として公開する。
  void _updateAttackTarget() {
    final self = _selfToken;
    if (self == null || !self.isAlive) {
      attackTargetId.value = null;
      return;
    }

    final nearest = _findNearestAliveEnemy(self);
    if (nearest == null) {
      attackTargetId.value = null;
      return;
    }

    final dist = _gridDistance(nearest.position, self.position);
    attackTargetId.value = dist <= _attackRangeGrid ? nearest.userId : null;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_flashAlpha > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = Colors.white.withValues(alpha: _flashAlpha * 0.35),
      );
    }
  }

  /// バトルエンジンの参加者一覧を反映する。tick 毎に呼んでよい（位置は初回のみ確定）。
  void sync(List<BattleParticipantState> participants) {
    final slotIndexByLaneTeam = <String, int>{};

    for (final p in participants) {
      final slotKey = '${p.lane}_${p.team}';
      final slotIndex = slotIndexByLaneTeam[slotKey] ?? 0;
      slotIndexByLaneTeam[slotKey] = slotIndex + 1;

      final token = _tokens.putIfAbsent(p.userId, () {
        final origin = mechaById(p.mechaId).origin;
        final icon = origin == 'EAST'
            ? Icons.local_fire_department
            : Icons.ac_unit;
        final gridX = p.team == 0 ? -1.8 : 1.8;
        final gridY =
            _laneCenterYs[p.lane] +
            (slotIndex - (AppConfig.maxPlayersPerTeam - 1) / 2) * 0.5;
        final screenPos = _projection.toScreen(gridX, gridY);
        final newToken =
            MechaToken(
                userId: p.userId,
                team: p.team,
                lane: p.lane,
                isSelf: p.isSelf,
                icon: icon,
                basePosition: screenPos,
              )
              // 奥（画面上=Y小）ほど先に描き、手前（Y大）を上に重ねる正しい前後関係
              ..priority = screenPos.y.round();
        add(newToken);
        if (p.isSelf) _selfToken = newToken;
        return newToken;
      });

      final wasAlive = token.isAlive;
      token.setAlive(p.isAlive);

      // リスポーン（死亡→生存）した瞬間、出撃地点へ位置を戻す。
      // これをしないと死んだ場所（敵陣のど真ん中など）でそのまま復活してしまう。
      if (!wasAlive && p.isAlive) {
        token.position.setFrom(token.spawnPosition);
        token.priority = token.spawnPosition.y.round();
        _wanderTargets.remove(p.userId);
      }

      token.updateHp(p.currentHp, p.effectiveHp);
    }
  }

  /// 撃破に至らない被弾（HPが削れただけ）の軽い反応。キル演出ほど強くしない。
  void onHitEvent(String victimId) {
    _tokens[victimId]?.triggerHitFlash();
  }

  /// 自キャラ周囲のスキル範囲内にいる敵のuserIdを列挙する（発動時に1回だけ呼ばれる想定）。
  /// レーンが異なる相手は対象外（BattleEngine側の自動交戦・manualDuel/manualSkillと揃える）。
  List<String> enemiesWithinSkillRadius() {
    final self = _selfToken;
    if (self == null || !self.isAlive) return [];

    return _tokens.values
        .where(
          (t) =>
              t.userId != self.userId &&
              t.team != self.team &&
              t.lane == self.lane &&
              t.isAlive,
        )
        .where(
          (t) => _gridDistance(t.position, self.position) <= _skillRadiusGrid,
        )
        .map((t) => t.userId)
        .toList();
  }

  /// スキル発動の視覚演出（スキルタイプ別カラーのリング + カメラシェイク）。
  void onSkillActivate({SkillType? skillType}) {
    final self = _selfToken;
    if (self == null) return;

    // スキルタイプが指定されていればSkillVisualEffectを使用、なければSkillBurst（後方互換性）
    if (skillType != null) {
      add(
        SkillVisualEffect(
          position: self.position.clone(),
          skillType: skillType,
          maxRadius: _skillRadius,
        ),
      );
    } else {
      add(SkillBurst(worldPosition: self.position.clone(), radius: _skillRadius));
    }
    _shakeMagnitude = 1.0;
  }

  void onKillEvent(String attackerId, String victimId) {
    final attacker = _tokens[attackerId];
    final victim = _tokens[victimId];

    attacker?.triggerKillFlash();

    if (attacker != null && victim != null) {
      final knockbackDir = victim.position - attacker.position;
      victim.triggerHitFlash(knockbackDirection: knockbackDir);
      add(
        ImpactLine(
          from: attacker.position.clone(),
          to: victim.position.clone(),
        ),
      );
      add(KillBurst(worldPosition: victim.position.clone()));
    } else {
      victim?.triggerHitFlash();
    }

    _shakeMagnitude = 1.0;
    _flashAlpha = 1.0;
  }

  /// ダメージ数値表示を画面上に追加。クリティカル時は拡張バースト演出も同時実行。
  void onDamageEvent(String victimId, int damage, bool isCritical) {
    final victim = _tokens[victimId];
    if (victim == null) return;

    // ダメージ数値は被弾者の上部に表示
    final damagePos = victim.position + Vector2(0, -victim.size.y / 2 - 10);
    add(
      DamageNumber(
        position: damagePos,
        damage: damage,
        isCritical: isCritical,
        color: isCritical ? Colors.red : Colors.white,
      ),
    );

    // クリティカルヒット時は追加の視覚演出
    if (isCritical) {
      add(CriticalBurst(position: victim.position.clone()));
    }
  }

  /// 攻撃側のバフを一時的に表示（攻撃UPなど）。
  void showAttackerBuff(String attackerId, BuffType buffType, {double duration = 1.0}) {
    final attacker = _tokens[attackerId];
    if (attacker != null) {
      add(
        BuffIndicator(
          buffType: buffType,
          duration: duration,
          tokenPosition: attacker.position.clone(),
        ),
      );
    }
  }

  /// 被弾側のデバフを一時的に表示（防御ダウンなど）。
  void showVictimDebuff(String victimId, BuffType debuffType, {double duration = 1.0}) {
    final victim = _tokens[victimId];
    if (victim != null) {
      add(
        BuffIndicator(
          buffType: debuffType,
          duration: duration,
          tokenPosition: victim.position.clone(),
        ),
      );
    }
  }

  /// 自キャラの位置にスキル範囲インジケーターを表示（視認性向上用）。
  void showSkillRangeIndicator({SkillType skillType = SkillType.offensive, bool isActive = true}) {
    final self = _selfToken;
    if (self == null) return;

    add(
      SkillAreaIndicator(
        position: self.position.clone(),
        radius: _skillRadius,
        skillType: skillType,
        isActive: isActive,
      ),
    );
  }
}
