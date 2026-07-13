import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' show Colors, Icons;
import 'package:shinjuu_league/config/app_config.dart';
import 'package:shinjuu_league/data/mecha_catalog.dart';
import 'package:shinjuu_league/game/impact_line.dart';
import 'package:shinjuu_league/game/isometric_projection.dart';
import 'package:shinjuu_league/game/kill_burst.dart';
import 'package:shinjuu_league/game/lane_floor.dart';
import 'package:shinjuu_league/game/mecha_token.dart';
import 'package:shinjuu_league/services/battle_engine_service.dart';

/// 参加者の状態（位置・生死）だけを受け取って描画するレンダラー。
/// 対戦のシミュレーションロジックは持たない（BattleEngine が唯一の正）。
class BattlefieldGame extends FlameGame {
  static const _projection = IsometricProjection();
  static const _laneCenterYs = [-1.8, 1.8];

  final Map<String, MechaToken> _tokens = {};
  final _random = Random();
  double _shakeMagnitude = 0.0;
  double _flashAlpha = 0.0;

  @override
  Color backgroundColor() => const Color(0xFF14171F);

  @override
  Future<void> onLoad() async {
    for (var lane = 0; lane < AppConfig.teamsCount; lane++) {
      final color = lane.isEven
          ? const Color(0xFF1E2536)
          : const Color(0xFF241B2E);
      add(LaneFloor(laneCenterY: _laneCenterYs[lane], color: color));
    }
    camera.viewfinder.anchor = Anchor.center;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    const desiredWorldWidth = 500.0;
    const desiredWorldHeight = 280.0;
    final zoom = min(
      size.x / desiredWorldWidth,
      size.y / desiredWorldHeight,
    ).clamp(0.6, 2.5);
    camera.viewfinder.zoom = zoom;
    camera.viewfinder.position = Vector2.zero();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_shakeMagnitude > 0) {
      _shakeMagnitude = (_shakeMagnitude - dt * 6).clamp(0.0, 1.0);
      final offsetX = (_random.nextDouble() * 2 - 1) * _shakeMagnitude * 14;
      final offsetY = (_random.nextDouble() * 2 - 1) * _shakeMagnitude * 14;
      camera.viewfinder.position = Vector2(offsetX, offsetY);
    } else {
      camera.viewfinder.position = Vector2.zero();
    }
    if (_flashAlpha > 0) {
      _flashAlpha = (_flashAlpha - dt * 4).clamp(0.0, 1.0);
    }
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
        final newToken = MechaToken(
          userId: p.userId,
          team: p.team,
          isSelf: p.isSelf,
          icon: icon,
          basePosition: _projection.toScreen(gridX, gridY),
        );
        add(newToken);
        return newToken;
      });

      token.setAlive(p.isAlive);
    }
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
}
