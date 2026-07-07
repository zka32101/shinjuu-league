import 'package:shinjuu_league/data/models/mecha_model.dart';

/// 神獣カタログ（表示用マスタデータ）。
/// 実Firebaseプロジェクトが未接続のため、当面はコード内の静的データを正とする。
/// Firestore運用に移行する際は [FirestoreService.getAllMechas] の呼び出し元を
/// 差し替えるだけで済むよう、Mecha モデル自体はFirestore schemaと共通にしてある。
final mechaCatalog = <Mecha>[
  Mecha(
    mechaId: 'mecha_east_flame',
    name: '緋焔虎',
    rarity: 'COMMON',
    origin: 'EAST',
    baseStats: BaseStats(hp: 120, atk: 55, spd: 35),
    iconUrl: '',
    skins: const [],
    description: '攻守のバランスに優れた東の神獣。初心者にも扱いやすい。',
  ),
  Mecha(
    mechaId: 'mecha_east_thunder',
    name: '雷鳴鷲',
    rarity: 'RARE',
    origin: 'EAST',
    baseStats: BaseStats(hp: 90, atk: 70, spd: 50),
    iconUrl: '',
    skins: const [],
    description: '高速で攻め立てる俊敏な神獣。攻撃特化。',
  ),
  Mecha(
    mechaId: 'mecha_east_stone',
    name: '岩嶽亀',
    rarity: 'RARE',
    origin: 'EAST',
    baseStats: BaseStats(hp: 160, atk: 40, spd: 20),
    iconUrl: '',
    skins: const [],
    description: '圧倒的な耐久力を誇る防御特化の神獣。',
  ),
  Mecha(
    mechaId: 'mecha_west_frost',
    name: '蒼氷狼',
    rarity: 'COMMON',
    origin: 'WEST',
    baseStats: BaseStats(hp: 110, atk: 55, spd: 40),
    iconUrl: '',
    skins: const [],
    description: 'バランス型の西の神獣。あらゆる戦術に対応。',
  ),
  Mecha(
    mechaId: 'mecha_west_storm',
    name: '嵐翼隼',
    rarity: 'EPIC',
    origin: 'WEST',
    baseStats: BaseStats(hp: 85, atk: 65, spd: 60),
    iconUrl: '',
    skins: const [],
    description: '圧倒的な速度でレーンを支配する神獣。',
  ),
  Mecha(
    mechaId: 'mecha_west_gold',
    name: '黄金獅子',
    rarity: 'LEGEND',
    origin: 'WEST',
    baseStats: BaseStats(hp: 130, atk: 60, spd: 40),
    iconUrl: '',
    skins: const [],
    description: '伝説級の神獣。全ステータスが高水準。',
  ),
];

const defaultMechaId = 'mecha_east_flame';

Mecha mechaById(String mechaId) {
  return mechaCatalog.firstWhere(
    (m) => m.mechaId == mechaId,
    orElse: () => mechaCatalog.first,
  );
}
