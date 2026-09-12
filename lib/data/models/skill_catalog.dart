// スキルカタログ - 全6キャラ × Q/R/E/ULT の完全定義

import 'package:freezed_annotation/freezed_annotation.dart';

part 'skill_catalog.freezed.dart';
part 'skill_catalog.g.dart';

enum SkillSlot { q, r, e, ult }

enum EvolutionType { offensive, defensive, support }

/// スキルレベルでの数値（ダメージ、効果値など）
@freezed
class SkillLevelData with _$SkillLevelData {
  const factory SkillLevelData({
    required int level,
    required int damage, // Q/R/ULT のダメージ、またはEの効果値（%）
    required double cooldown, // 秒単位
    String? description,
  }) = _SkillLevelData;

  factory SkillLevelData.fromJson(Map<String, dynamic> json) =>
      _$SkillLevelDataFromJson(json);
}

/// スキル定義（キャラ × スロット）
@freezed
class SkillDefinition with _$SkillDefinition {
  const factory SkillDefinition({
    required String skillId, // e.g. 'leon_q', 'dragoon_ult'
    required String name,
    required SkillSlot slot,
    required Map<int, SkillLevelData> levelData, // Lv → 数値マッピング
    String? baseDescription,
  }) = _SkillDefinition;

  /// 指定レベルでのスキル数値を取得
  SkillLevelData? getAtLevel(int level) => levelData[level];

  factory SkillDefinition.fromJson(Map<String, dynamic> json) =>
      _$SkillDefinitionFromJson(json);
}

/// キャラ進化状態
@freezed
class CharacterEvolution with _$CharacterEvolution {
  const factory CharacterEvolution({
    required String mechaId,
    required EvolutionType? evolutionAtLv3, // null = 未選択
    required EvolutionType? evolutionAtLv6, // Lv6で変更可能
    required int lastEvolutionLevel, // 最後に進化した時のレベル
  }) = _CharacterEvolution;

  factory CharacterEvolution.initial(String mechaId) => CharacterEvolution(
    mechaId: mechaId,
    evolutionAtLv3: null,
    evolutionAtLv6: null,
    lastEvolutionLevel: 0,
  );

  factory CharacterEvolution.fromJson(Map<String, dynamic> json) =>
      _$CharacterEvolutionFromJson(json);
}

/// スキルカタログ本体（全キャラのスキル定義保持）
class SkillCatalog {
  static final Map<String, Map<SkillSlot, SkillDefinition>> _skills = {
    // ═══════════════════════════════════════════════════════════════════
    // 火炎獅子 レオン (COMMON・タンク)
    // ═══════════════════════════════════════════════════════════════════
    'leon': {
      SkillSlot.q: SkillDefinition(
        skillId: 'leon_q',
        name: '火炎突進',
        slot: SkillSlot.q,
        baseDescription: '前方へ炎をまとって突進。敵にダメージ。',
        levelData: {
          1: const SkillLevelData(level: 1, damage: 200, cooldown: 4.0),
          3: const SkillLevelData(level: 3, damage: 200, cooldown: 4.0),
          4: const SkillLevelData(level: 4, damage: 250, cooldown: 4.0),
          5: const SkillLevelData(level: 5, damage: 250, cooldown: 4.0),
          6: const SkillLevelData(level: 6, damage: 280, cooldown: 4.0),
          7: const SkillLevelData(level: 7, damage: 280, cooldown: 4.0),
          8: const SkillLevelData(level: 8, damage: 350, cooldown: 4.0),
        },
      ),
      SkillSlot.r: SkillDefinition(
        skillId: 'leon_r',
        name: '炎壁展開',
        slot: SkillSlot.r,
        baseDescription: '周囲に炎の壁を展開。敵にダメージ & 防御UP。',
        levelData: {
          2: const SkillLevelData(level: 2, damage: 120, cooldown: 8.0),
          3: const SkillLevelData(level: 3, damage: 120, cooldown: 8.0),
          4: const SkillLevelData(level: 4, damage: 150, cooldown: 8.0),
          5: const SkillLevelData(level: 5, damage: 150, cooldown: 8.0),
          6: const SkillLevelData(level: 6, damage: 180, cooldown: 8.0),
          7: const SkillLevelData(level: 7, damage: 180, cooldown: 8.0),
          8: const SkillLevelData(level: 8, damage: 200, cooldown: 8.0),
        },
      ),
      SkillSlot.e: SkillDefinition(
        skillId: 'leon_e',
        name: '進化スキル (E)',
        slot: SkillSlot.e,
        baseDescription: 'Lv3で進化選択。攻撃/防御/支援型から選択。',
        levelData: {
          3: const SkillLevelData(level: 3, damage: 0, cooldown: 0),
          6: const SkillLevelData(level: 6, damage: 0, cooldown: 0),
          8: const SkillLevelData(level: 8, damage: 0, cooldown: 0),
        },
      ),
      SkillSlot.ult: SkillDefinition(
        skillId: 'leon_ult',
        name: '火龍皇牙',
        slot: SkillSlot.ult,
        baseDescription: '全方向に炎を放出。敵を強烈にスタン。',
        levelData: {
          5: const SkillLevelData(level: 5, damage: 0, cooldown: 45.0, description: 'チャージ開始'),
          7: const SkillLevelData(level: 7, damage: 1200, cooldown: 45.0, description: 'ULT解放: 全敵スタン1.5s'),
          8: const SkillLevelData(level: 8, damage: 1500, cooldown: 45.0, description: '強化版: ダメージ+25%'),
        },
      ),
    },

    // ═══════════════════════════════════════════════════════════════════
    // 烈風鷲 ウルフ (RARE・DPS)
    // ═══════════════════════════════════════════════════════════════════
    'wolf': {
      SkillSlot.q: SkillDefinition(
        skillId: 'wolf_q',
        name: '爪撃',
        slot: SkillSlot.q,
        baseDescription: '素早い連撃で敵にダメージ。複数敵も対応。',
        levelData: {
          1: const SkillLevelData(level: 1, damage: 180, cooldown: 4.0),
          3: const SkillLevelData(level: 3, damage: 180, cooldown: 4.0),
          4: const SkillLevelData(level: 4, damage: 240, cooldown: 4.0),
          5: const SkillLevelData(level: 5, damage: 240, cooldown: 4.0),
          6: const SkillLevelData(level: 6, damage: 300, cooldown: 4.0),
          7: const SkillLevelData(level: 7, damage: 300, cooldown: 4.0),
          8: const SkillLevelData(level: 8, damage: 400, cooldown: 4.0),
        },
      ),
      SkillSlot.r: SkillDefinition(
        skillId: 'wolf_r',
        name: '風切り',
        slot: SkillSlot.r,
        baseDescription: '前方へ風の刃を放出。敵に命中で移動速度UP。',
        levelData: {
          2: const SkillLevelData(level: 2, damage: 150, cooldown: 8.0),
          3: const SkillLevelData(level: 3, damage: 150, cooldown: 8.0),
          4: const SkillLevelData(level: 4, damage: 200, cooldown: 8.0),
          5: const SkillLevelData(level: 5, damage: 200, cooldown: 8.0),
          6: const SkillLevelData(level: 6, damage: 280, cooldown: 8.0),
          7: const SkillLevelData(level: 7, damage: 280, cooldown: 8.0),
          8: const SkillLevelData(level: 8, damage: 350, cooldown: 8.0),
        },
      ),
      SkillSlot.e: SkillDefinition(
        skillId: 'wolf_e',
        name: '進化スキル (E)',
        slot: SkillSlot.e,
        baseDescription: 'Lv3で進化選択。攻撃/防御/支援型から選択。',
        levelData: {
          3: const SkillLevelData(level: 3, damage: 0, cooldown: 0),
          6: const SkillLevelData(level: 6, damage: 0, cooldown: 0),
          8: const SkillLevelData(level: 8, damage: 0, cooldown: 0),
        },
      ),
      SkillSlot.ult: SkillDefinition(
        skillId: 'wolf_ult',
        name: '連続斬撃',
        slot: SkillSlot.ult,
        baseDescription: '敵単体へ超高速連撃。敵が逃げられない。',
        levelData: {
          5: const SkillLevelData(level: 5, damage: 0, cooldown: 45.0, description: 'チャージ開始'),
          7: const SkillLevelData(level: 7, damage: 1100, cooldown: 45.0, description: 'ULT解放: 連撃12回'),
          8: const SkillLevelData(level: 8, damage: 1400, cooldown: 45.0, description: '強化版: 連撃15回'),
        },
      ),
    },

    // ═══════════════════════════════════════════════════════════════════
    // 地煞龍 ドラグーン (LEGENDARY・キャリー)
    // ═══════════════════════════════════════════════════════════════════
    'dragoon': {
      SkillSlot.q: SkillDefinition(
        skillId: 'dragoon_q',
        name: '竜巻斬',
        slot: SkillSlot.q,
        baseDescription: '竜の力で回転斬撃。範囲内の敵全てに命中。',
        levelData: {
          1: const SkillLevelData(level: 1, damage: 250, cooldown: 4.0),
          3: const SkillLevelData(level: 3, damage: 250, cooldown: 4.0),
          4: const SkillLevelData(level: 4, damage: 320, cooldown: 4.0),
          5: const SkillLevelData(level: 5, damage: 320, cooldown: 4.0),
          6: const SkillLevelData(level: 6, damage: 380, cooldown: 4.0),
          7: const SkillLevelData(level: 7, damage: 380, cooldown: 4.0),
          8: const SkillLevelData(level: 8, damage: 450, cooldown: 4.0),
        },
      ),
      SkillSlot.r: SkillDefinition(
        skillId: 'dragoon_r',
        name: 'メテオ落下',
        slot: SkillSlot.r,
        baseDescription: '空から隕石群を落下させ、敵にダメージ。',
        levelData: {
          2: const SkillLevelData(level: 2, damage: 540, cooldown: 8.0), // 180×3
          3: const SkillLevelData(level: 3, damage: 540, cooldown: 8.0),
          4: const SkillLevelData(level: 4, damage: 900, cooldown: 8.0), // 180×5
          5: const SkillLevelData(level: 5, damage: 900, cooldown: 8.0),
          6: const SkillLevelData(level: 6, damage: 1000, cooldown: 8.0), // 200×5
          7: const SkillLevelData(level: 7, damage: 1000, cooldown: 8.0),
          8: const SkillLevelData(level: 8, damage: 1100, cooldown: 8.0), // 220×5
        },
      ),
      SkillSlot.e: SkillDefinition(
        skillId: 'dragoon_e',
        name: '進化スキル (E)',
        slot: SkillSlot.e,
        baseDescription: 'Lv3で進化選択。攻撃/防御/支援型から選択。真龍状態へ。',
        levelData: {
          3: const SkillLevelData(level: 3, damage: 0, cooldown: 0),
          6: const SkillLevelData(level: 6, damage: 0, cooldown: 0),
          8: const SkillLevelData(level: 8, damage: 0, cooldown: 0),
        },
      ),
      SkillSlot.ult: SkillDefinition(
        skillId: 'dragoon_ult',
        name: '次元断裂',
        slot: SkillSlot.ult,
        baseDescription: 'ドラグーン最強の必殺技。次元を割いて攻撃。',
        levelData: {
          5: const SkillLevelData(level: 5, damage: 0, cooldown: 45.0, description: 'チャージ開始'),
          7: const SkillLevelData(level: 7, damage: 1600, cooldown: 45.0, description: 'ULT解放'),
          8: const SkillLevelData(level: 8, damage: 2000, cooldown: 45.0, description: '強化版: ダメージ+25% + 敵スロー'),
        },
      ),
    },

    // ═══════════════════════════════════════════════════════════════════
    // 氷盾熊 フロスト (COMMON・サポート)
    // ═══════════════════════════════════════════════════════════════════
    'frost': {
      SkillSlot.q: SkillDefinition(
        skillId: 'frost_q',
        name: '氷壁',
        slot: SkillSlot.q,
        baseDescription: '前方に氷の壁を展開。敵を押し返す。',
        levelData: {
          1: const SkillLevelData(level: 1, damage: 100, cooldown: 4.0),
          3: const SkillLevelData(level: 3, damage: 100, cooldown: 4.0),
          4: const SkillLevelData(level: 4, damage: 140, cooldown: 4.0),
          5: const SkillLevelData(level: 5, damage: 140, cooldown: 4.0),
          6: const SkillLevelData(level: 6, damage: 180, cooldown: 4.0),
          7: const SkillLevelData(level: 7, damage: 180, cooldown: 4.0),
          8: const SkillLevelData(level: 8, damage: 220, cooldown: 4.0),
        },
      ),
      SkillSlot.r: SkillDefinition(
        skillId: 'frost_r',
        name: '寒冷域',
        slot: SkillSlot.r,
        baseDescription: '周囲に寒冷領域を展開。敵の移動速度を低下。',
        levelData: {
          2: const SkillLevelData(level: 2, damage: 80, cooldown: 8.0),
          3: const SkillLevelData(level: 3, damage: 80, cooldown: 8.0),
          4: const SkillLevelData(level: 4, damage: 120, cooldown: 8.0),
          5: const SkillLevelData(level: 5, damage: 120, cooldown: 8.0),
          6: const SkillLevelData(level: 6, damage: 160, cooldown: 8.0),
          7: const SkillLevelData(level: 7, damage: 160, cooldown: 8.0),
          8: const SkillLevelData(level: 8, damage: 200, cooldown: 8.0),
        },
      ),
      SkillSlot.e: SkillDefinition(
        skillId: 'frost_e',
        name: '進化スキル (E)',
        slot: SkillSlot.e,
        baseDescription: 'Lv3で進化選択。攻撃/防御/支援型から選択。',
        levelData: {
          3: const SkillLevelData(level: 3, damage: 0, cooldown: 0),
          6: const SkillLevelData(level: 6, damage: 0, cooldown: 0),
          8: const SkillLevelData(level: 8, damage: 0, cooldown: 0),
        },
      ),
      SkillSlot.ult: SkillDefinition(
        skillId: 'frost_ult',
        name: '氷結守護',
        slot: SkillSlot.ult,
        baseDescription: 'チーム全体を氷で包み込む。敵の攻撃を無効化。',
        levelData: {
          5: const SkillLevelData(level: 5, damage: 0, cooldown: 45.0, description: 'チャージ開始'),
          7: const SkillLevelData(level: 7, damage: 0, cooldown: 45.0, description: 'ULT解放: 味方全員防御+50% 3s'),
          8: const SkillLevelData(level: 8, damage: 0, cooldown: 45.0, description: '強化版: 防御+60% 4s'),
        },
      ),
    },

    // ═══════════════════════════════════════════════════════════════════
    // 烈火鷲 フェニックス (RARE・DPS)
    // ═══════════════════════════════════════════════════════════════════
    'phoenix': {
      SkillSlot.q: SkillDefinition(
        skillId: 'phoenix_q',
        name: '氷槍',
        slot: SkillSlot.q,
        baseDescription: '冷気を纏った槍を放出。敵に命中で鈍化。',
        levelData: {
          1: const SkillLevelData(level: 1, damage: 170, cooldown: 4.0),
          3: const SkillLevelData(level: 3, damage: 170, cooldown: 4.0),
          4: const SkillLevelData(level: 4, damage: 230, cooldown: 4.0),
          5: const SkillLevelData(level: 5, damage: 230, cooldown: 4.0),
          6: const SkillLevelData(level: 6, damage: 300, cooldown: 4.0),
          7: const SkillLevelData(level: 7, damage: 300, cooldown: 4.0),
          8: const SkillLevelData(level: 8, damage: 380, cooldown: 4.0),
        },
      ),
      SkillSlot.r: SkillDefinition(
        skillId: 'phoenix_r',
        name: '吹雪',
        slot: SkillSlot.r,
        baseDescription: '前方へ吹雪を放出。敵全てにダメージ。',
        levelData: {
          2: const SkillLevelData(level: 2, damage: 160, cooldown: 8.0),
          3: const SkillLevelData(level: 3, damage: 160, cooldown: 8.0),
          4: const SkillLevelData(level: 4, damage: 220, cooldown: 8.0),
          5: const SkillLevelData(level: 5, damage: 220, cooldown: 8.0),
          6: const SkillLevelData(level: 6, damage: 300, cooldown: 8.0),
          7: const SkillLevelData(level: 7, damage: 300, cooldown: 8.0),
          8: const SkillLevelData(level: 8, damage: 360, cooldown: 8.0),
        },
      ),
      SkillSlot.e: SkillDefinition(
        skillId: 'phoenix_e',
        name: '進化スキル (E)',
        slot: SkillSlot.e,
        baseDescription: 'Lv3で進化選択。攻撃/防御/支援型から選択。',
        levelData: {
          3: const SkillLevelData(level: 3, damage: 0, cooldown: 0),
          6: const SkillLevelData(level: 6, damage: 0, cooldown: 0),
          8: const SkillLevelData(level: 8, damage: 0, cooldown: 0),
        },
      ),
      SkillSlot.ult: SkillDefinition(
        skillId: 'phoenix_ult',
        name: '連射氷槍',
        slot: SkillSlot.ult,
        baseDescription: 'フェニックスが氷槍を連射。敵陣を掃射。',
        levelData: {
          5: const SkillLevelData(level: 5, damage: 0, cooldown: 45.0, description: 'チャージ開始'),
          7: const SkillLevelData(level: 7, damage: 1250, cooldown: 45.0, description: 'ULT解放: 連射20回'),
          8: const SkillLevelData(level: 8, damage: 1600, cooldown: 45.0, description: '強化版: 連射25回'),
        },
      ),
    },

    // ═══════════════════════════════════════════════════════════════════
    // 星魔姫 クリスタル (LEGENDARY・コントローラー)
    // ═══════════════════════════════════════════════════════════════════
    'crystal': {
      SkillSlot.q: SkillDefinition(
        skillId: 'crystal_q',
        name: '氷晶',
        slot: SkillSlot.q,
        baseDescription: '敵を一瞬氷漬けにする。短時間スタン。',
        levelData: {
          1: const SkillLevelData(level: 1, damage: 120, cooldown: 4.0),
          3: const SkillLevelData(level: 3, damage: 120, cooldown: 4.0),
          4: const SkillLevelData(level: 4, damage: 180, cooldown: 4.0),
          5: const SkillLevelData(level: 5, damage: 180, cooldown: 4.0),
          6: const SkillLevelData(level: 6, damage: 240, cooldown: 4.0),
          7: const SkillLevelData(level: 7, damage: 240, cooldown: 4.0),
          8: const SkillLevelData(level: 8, damage: 300, cooldown: 4.0),
        },
      ),
      SkillSlot.r: SkillDefinition(
        skillId: 'crystal_r',
        name: '時間停止準備',
        slot: SkillSlot.r,
        baseDescription: 'CC魔法を準備。敵の行動を妨害する。',
        levelData: {
          2: const SkillLevelData(level: 2, damage: 100, cooldown: 8.0),
          3: const SkillLevelData(level: 3, damage: 100, cooldown: 8.0),
          4: const SkillLevelData(level: 4, damage: 150, cooldown: 8.0),
          5: const SkillLevelData(level: 5, damage: 150, cooldown: 8.0),
          6: const SkillLevelData(level: 6, damage: 200, cooldown: 8.0),
          7: const SkillLevelData(level: 7, damage: 200, cooldown: 8.0),
          8: const SkillLevelData(level: 8, damage: 250, cooldown: 8.0),
        },
      ),
      SkillSlot.e: SkillDefinition(
        skillId: 'crystal_e',
        name: '進化スキル (E)',
        slot: SkillSlot.e,
        baseDescription: 'Lv3で進化選択。攻撃/防御/支援型から選択。',
        levelData: {
          3: const SkillLevelData(level: 3, damage: 0, cooldown: 0),
          6: const SkillLevelData(level: 6, damage: 0, cooldown: 0),
          8: const SkillLevelData(level: 8, damage: 0, cooldown: 0),
        },
      ),
      SkillSlot.ult: SkillDefinition(
        skillId: 'crystal_ult',
        name: '次元裂き',
        slot: SkillSlot.ult,
        baseDescription: 'クリスタル最高のCC技。敵の時間を止める。',
        levelData: {
          5: const SkillLevelData(level: 5, damage: 0, cooldown: 45.0, description: 'チャージ開始'),
          7: const SkillLevelData(level: 7, damage: 0, cooldown: 45.0, description: 'ULT解放: 敵全員CC 3s'),
          8: const SkillLevelData(level: 8, damage: 0, cooldown: 45.0, description: '強化版: CC 4s + 敵ダメージ-50%'),
        },
      ),
    },
  };

  /// キャラクターのスキルセットを取得
  static Map<SkillSlot, SkillDefinition>? getCharacterSkills(String mechaId) {
    return _skills[mechaId];
  }

  /// 特定のスキルを取得
  static SkillDefinition? getSkill(String mechaId, SkillSlot slot) {
    return _skills[mechaId]?[slot];
  }

  /// キャラのスキルセットが存在するか
  static bool hasCharacter(String mechaId) => _skills.containsKey(mechaId);

  /// 全キャラのID一覧
  static List<String> getAllCharacterIds() => _skills.keys.toList();
}
