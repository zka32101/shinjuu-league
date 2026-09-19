import 'package:flutter/material.dart' show Color;
import 'package:shinjuu_league/data/models/stage_model.dart';

/// バトルステージカタログ（表示用マスタデータ）。神獣リーグの「東西」世界観に沿って
/// 5種のテーマを用意し、マッチングのたびにランダムで選ばれる（[MatchmakingService]参照）。
/// 実背景素材は未着手のため、mechaCatalog等と同様にコード内の静的データを正とする。
final stageCatalog = <Stage>[
  Stage(
    stageId: 'stage_twin_valley',
    name: '二極の谷',
    description: '東西の神獣が最初に相まみえたとされる、青と紫が拮抗する定番ステージ。',
    laneColors: const [Color(0xFF1E2536), Color(0xFF241B2E)],
    voidColor: const Color(0xFF181B24),
    backgroundColor: const Color(0xFF14171F),
  ),
  Stage(
    stageId: 'stage_volcano_ridge',
    name: '火山稜線',
    description: '東の炎の神獣を育んだ灼熱の稜線。溶岩の赤が戦場を照らす。',
    laneColors: const [Color(0xFF3A1A12), Color(0xFF44140F)],
    voidColor: const Color(0xFF1F0F0B),
    backgroundColor: const Color(0xFF190D09),
  ),
  Stage(
    stageId: 'stage_frost_plateau',
    name: '氷雪高原',
    description: '西の氷の神獣が住まう極寒の高原。青白い輝きが視界を支配する。',
    laneColors: const [Color(0xFF17303D), Color(0xFF1B2A3F)],
    voidColor: const Color(0xFF0E1D26),
    backgroundColor: const Color(0xFF0A1620),
  ),
  Stage(
    stageId: 'stage_ancient_shrine',
    name: '古代神殿',
    description: '神獣信仰の起源とされる遺跡群。金と翡翠が神秘的な戦場を彩る。',
    laneColors: const [Color(0xFF2B2416), Color(0xFF1D2B22)],
    voidColor: const Color(0xFF17131C),
    backgroundColor: const Color(0xFF120F17),
  ),
  Stage(
    stageId: 'stage_twilight_plains',
    name: '黄昏の草原',
    description: '陽が沈みかけた広大な草原。琥珀と藍のコントラストが美しいステージ。',
    laneColors: const [Color(0xFF33271A), Color(0xFF1E2733)],
    voidColor: const Color(0xFF1C1826),
    backgroundColor: const Color(0xFF16131F),
  ),
];

const defaultStageId = 'stage_twin_valley';

Stage stageById(String stageId) {
  return stageCatalog.firstWhere(
    (s) => s.stageId == stageId,
    orElse: () => stageCatalog.first,
  );
}
