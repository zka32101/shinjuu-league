import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show ValueNotifier, visibleForTesting;
import 'package:flutter/material.dart' show Colors, EdgeInsets, Icons;
import 'package:shinjuu_league/config/app_config.dart';
import 'package:shinjuu_league/services/performance_service.dart';
import 'package:shinjuu_league/data/mecha_catalog.dart';
import 'package:shinjuu_league/data/models/stage_model.dart';
import 'package:shinjuu_league/data/stage_catalog.dart';
import 'package:shinjuu_league/game/impact_line.dart';
import 'package:shinjuu_league/game/isometric_projection.dart';
import 'package:shinjuu_league/game/jungle_monster_token.dart';
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
import 'package:shinjuu_league/game/rendering_optimization.dart';
import 'package:shinjuu_league/ui/widgets/minimap.dart';

/// 攻撃ボタンが対象とする相手（敵プレイヤー or 中立モンスター）を表す。
class AttackTarget {
  final String id;
  final bool isMonster;
  const AttackTarget({required this.id, required this.isMonster});
}

/// 参加者の状態（位置・生死）だけを受け取って描画するレンダラー。
/// 対戦のシミュレーションロジックは持たない（BattleEngine が唯一の正）。
///
/// 自キャラのみジョイスティックでフリー移動できる（Pokémon UNITE風の接近戦）。
/// 味方/Botの位置もこのクラス内で緩やかに動かすが、あくまで見た目上の移動演出であり、
/// 撃破判定・勝敗などのシミュレーションはBattleEngineが引き続き唯一の正。
class BattlefieldGame extends FlameGame {
  BattlefieldGame({String mapId = defaultStageId}) : stage = stageById(mapId);

  /// バトルのテーマ（配色）。mapId から解決される（[stageCatalog]参照）。
  final Stage stage;

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
  final Map<String, JungleMonsterToken> _monsterTokens = {};
  final _random = Random();
  double _shakeMagnitude = 0.0;
  double _flashAlpha = 0.0;
  // キル演出の「重み」を出すためのヒットストップ（一瞬だけ動きをほぼ静止させる）
  double _hitStopRemaining = 0.0;
  // カメラのズームパンチ（キル時に一瞬寄ってから戻る）。onGameResizeで決まる基準ズームに乗算する。
  double _baseZoom = 1.0;
  double _zoomPunch = 0.0;
  final Vector2 _cameraFollowPos = Vector2.zero();
  late final PerformanceService _performanceService = PerformanceService();
  late final FrustumCuller _frustumCuller = FrustumCuller();
  late final RenderingStats _renderingStats = RenderingStats();

  JoystickComponent? _joystick;
  MechaToken? _selfToken;
  double _targetScanTimer = 0.0;
  double _wanderRetargetTimer = 0.0;
  final Map<String, Vector2> _wanderTargets = {};

  /// 攻撃可能な射程内に敵/モンスターがいる場合、その対象を保持する。UIの攻撃ボタン有効化に使う。
  final ValueNotifier<AttackTarget?> attackTargetId = ValueNotifier(null);

  /// ミニマップ表示用のエントリ一覧（自分・味方・敵・モンスター）。
  final ValueNotifier<List<MinimapEntry>> minimapEntries = ValueNotifier(const []);

  /// テスト専用：ジョイスティック入力を経由せず自キャラをグリッド座標へ直接移動する。
  /// ユニットテストでは実タッチ入力によるジョイスティック操作を再現できないため、
  /// 攻撃対象検出ロジックの検証にのみ使用する。
  @visibleForTesting
  void debugSetSelfGridPosition(double gridX, double gridY) {
    final self = _selfToken;
    if (self == null) return;
    final screenPos = _projection.toScreen(gridX, gridY);
    self.position.setFrom(screenPos);
    self.priority = screenPos.y.round();
  }

  @override
  Color backgroundColor() => stage.backgroundColor;

  @override
  Future<void> onLoad() async {
    add(
      OpenField(
        halfWidth: _playfieldHalfWidth,
        halfHeight: _playfieldHalfHeight,
        color: stage.voidColor,
      )..priority = -1000,
    );
    for (var lane = 0; lane < AppConfig.teamsCount; lane++) {
      final color = stage.laneColors[lane % stage.laneColors.length];
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
    _baseZoom = zoom;
    camera.viewfinder.zoom = zoom;

    // ビューポート（カメラ表示範囲）をフラスタムカラーに設定
    _frustumCuller.setViewport(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y / 2),
        width: size.x,
        height: size.y,
      ),
    );
  }

  @override
  void update(double dt) {
    // ヒットストップ中は実時間でカウントダウンしつつ、演出以外のシミュレーション速度を
    // 大きく落として「一瞬止まった」ような重みを出す（完全停止はFlame内部処理に
    // 影響しうるため避け、極端なスローモーションに留める）
    var effectiveDt = dt;
    if (_hitStopRemaining > 0) {
      _hitStopRemaining = (_hitStopRemaining - dt).clamp(0.0, double.infinity);
      effectiveDt = dt * 0.04;
    }

    super.update(effectiveDt);

    // フレームレート計測
    _performanceService.recordFrame();

    // カメラは自キャラの位置へ滑らかに追従する
    final followTarget = _selfToken?.position ?? Vector2.zero();
    final followLerp = (effectiveDt * 4).clamp(0.0, 1.0);
    _cameraFollowPos.setFrom(
      _cameraFollowPos + (followTarget - _cameraFollowPos) * followLerp,
    );

    Vector2 shakeOffset = Vector2.zero();
    if (_shakeMagnitude > 0) {
      _shakeMagnitude = (_shakeMagnitude - effectiveDt * 4.5).clamp(0.0, 1.0);
      shakeOffset = Vector2(
        (_random.nextDouble() * 2 - 1) * _shakeMagnitude * 26,
        (_random.nextDouble() * 2 - 1) * _shakeMagnitude * 26,
      );
    }
    camera.viewfinder.position = _cameraFollowPos + shakeOffset;

    // カメラのズームパンチ（キル瞬間に一瞬寄って、すぐ戻る）
    if (_zoomPunch > 0) {
      _zoomPunch = (_zoomPunch - effectiveDt * 5.5).clamp(0.0, 1.0);
    }
    camera.viewfinder.zoom = _baseZoom * (1.0 + _zoomPunch * 0.15);

    if (_flashAlpha > 0) {
      _flashAlpha = (_flashAlpha - effectiveDt * 3.2).clamp(0.0, 1.0);
    }

    _updateSelfMovement(effectiveDt);
    _updateBotWander(effectiveDt);

    _targetScanTimer += effectiveDt;
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

  /// 同じレーンの生存中モンスターのうち最も近いものを返す。
  JungleMonsterToken? _findNearestAliveMonster(MechaToken from) {
    JungleMonsterToken? nearest;
    var nearestDist = double.infinity;
    for (final monster in _monsterTokens.values) {
      if (!monster.isAlive) continue;
      if (monster.lane != from.lane) continue;
      final dist = _gridDistance(monster.position, from.position);
      if (dist < nearestDist) {
        nearestDist = dist;
        nearest = monster;
      }
    }
    return nearest;
  }

  /// 自キャラの射程内にいる最も近い攻撃対象（敵プレイヤー優先、次点でモンスター）を公開する。
  void _updateAttackTarget() {
    final self = _selfToken;
    if (self == null || !self.isAlive) {
      attackTargetId.value = null;
      return;
    }

    final nearestEnemy = _findNearestAliveEnemy(self);
    if (nearestEnemy != null) {
      final dist = _gridDistance(nearestEnemy.position, self.position);
      if (dist <= _attackRangeGrid) {
        attackTargetId.value = AttackTarget(id: nearestEnemy.userId, isMonster: false);
        return;
      }
    }

    final nearestMonster = _findNearestAliveMonster(self);
    if (nearestMonster != null) {
      final dist = _gridDistance(nearestMonster.position, self.position);
      if (dist <= _attackRangeGrid) {
        attackTargetId.value = AttackTarget(id: nearestMonster.monsterId, isMonster: true);
        return;
      }
    }

    attackTargetId.value = null;
  }

  /// ミニマップ表示用のエントリ一覧を再構築する。プレイヤー・モンスター双方の
  /// 同期処理の後に呼び出し、常に最新の位置を反映する。
  void _rebuildMinimap() {
    final entries = <MinimapEntry>[];
    final self = _selfToken;
    for (final token in _tokens.values) {
      final type = token.isSelf
          ? MinimapEntryType.self
          : (self != null && token.team == self.team
                ? MinimapEntryType.ally
                : MinimapEntryType.enemy);
      entries.add(
        MinimapEntry(
          id: token.userId,
          x: token.position.x / _playfieldHalfWidth,
          y: token.position.y / _playfieldHalfHeight,
          type: type,
          isAlive: token.isAlive,
        ),
      );
    }
    for (final monster in _monsterTokens.values) {
      entries.add(
        MinimapEntry(
          id: monster.monsterId,
          x: monster.position.x / _playfieldHalfWidth,
          y: monster.position.y / _playfieldHalfHeight,
          type: MinimapEntryType.monster,
          isAlive: monster.isAlive,
        ),
      );
    }
    minimapEntries.value = entries;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_flashAlpha > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = Colors.white.withValues(alpha: _flashAlpha * 0.45),
      );
    }
  }

  /// バトルエンジンの参加者一覧を反映する。tick 毎に呼んでよい（位置は初回のみ確定）。
  void sync(List<BattleParticipantState> participants) {
    _renderingStats.reset(); // フレーム開始時に統計をリセット
    final slotIndexByLaneTeam = <String, int>{};
    int visibleCount = 0;

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
                mechaId: p.mechaId,
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

      // フラスタムカリング：画面外のトークンをカウント
      final tokenBounds = Rect.fromCircle(
        center: Offset(token.position.x, token.position.y),
        radius: 24,
      );
      if (_frustumCuller.isVisible(tokenBounds)) {
        visibleCount++;
      } else {
        _renderingStats.culledObjectCount++;
      }
    }

    _renderingStats.visibleObjectCount = visibleCount;
    _rebuildMinimap();
  }

  /// ジャングルモンスターの状態を反映する。sync() と同様 tick 毎に呼んでよい。
  void syncMonsters(List<JungleMonster> monsters) {
    for (final m in monsters) {
      final token = _monsterTokens.putIfAbsent(m.id, () {
        final gridY = _laneCenterYs[m.lane];
        final screenPos = _projection.toScreen(0, gridY);
        final newToken =
            JungleMonsterToken(monsterId: m.id, lane: m.lane, basePosition: screenPos)
              ..priority = screenPos.y.round() - 1; // プレイヤーよりわずかに奥に描画
        add(newToken);
        return newToken;
      });
      token.setAlive(m.isAlive);
      token.updateHp(m.currentHp, m.maxHp);
    }
    _rebuildMinimap();
  }

  /// 撃破に至らない被弾（HPが削れただけ）の軽い反応。キル演出ほど強くしない。
  void onHitEvent(String victimId) {
    _tokens[victimId]?.triggerHitFlash();
    _monsterTokens[victimId]?.triggerHitFlash();
  }

  /// ジャングルモンスター討伐時の演出：討伐者の位置に大きめのキルバースト+バフ表示。
  void onMonsterKillEvent(String killerId, String monsterId) {
    final killer = _tokens[killerId];
    final monster = _monsterTokens[monsterId];
    if (monster != null) {
      add(KillBurst(worldPosition: monster.position.clone()));
    }
    if (killer != null) {
      killer.triggerKillFlash();
      add(
        BuffIndicator(
          buffType: BuffType.atkBoost,
          duration: 1.4,
          tokenPosition: killer.position.clone(),
        ),
      );
    }
    _shakeMagnitude = 0.6;
    _zoomPunch = 0.6;
    _hitStopRemaining = 0.05;
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
    _zoomPunch = 1.0;
    _hitStopRemaining = 0.08;
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
