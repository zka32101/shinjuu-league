import 'package:flutter/material.dart' show Color;

/// バトルステージ（マップ）のテーマ設定。
/// mapId はBattle/MatchResultの既存フィールドを流用し、対応する見た目を
/// [stageById] で解決する。実背景素材は未着手のため、当面は配色のみで
/// テーマの違いを表現する（プレースホルダー方針は他のビジュアル要素と同様）。
class Stage {
  final String stageId;
  final String name;
  final String description;

  /// 2レーン分の地面色（インデックス0/1がそれぞれのレーンに対応）
  final List<Color> laneColors;

  /// レーン外の開けたエリア（自由に歩き回れる範囲）の地面色
  final Color voidColor;

  /// FlameGameの背景色
  final Color backgroundColor;

  const Stage({
    required this.stageId,
    required this.name,
    required this.description,
    required this.laneColors,
    required this.voidColor,
    required this.backgroundColor,
  });
}
