import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:shinjuu_league/config/app_config.dart';
import 'package:shinjuu_league/data/mecha_catalog.dart';
import 'package:shinjuu_league/game/isometric_projection.dart';
import 'package:shinjuu_league/game/lane_floor.dart';
import 'package:shinjuu_league/game/mecha_token.dart';
import 'package:shinjuu_league/services/battle_engine_service.dart';

/// 参加者の状態（位置・生死）だけを受け取って描画するレンダラー。
/// 対戦のシミュレーションロジックは持たない（BattleEngine が唯一の正）。
class BattlefieldGame extends FlameGame {
  static const _projection = IsometricProjection();
  static const _laneCenterYs = [-1.8, 1.8];

  final Map<String, MechaToken> _tokens = {};

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

  void onKillEvent(String attackerId) {
    _tokens[attackerId]?.triggerKillFlash();
  }
}
