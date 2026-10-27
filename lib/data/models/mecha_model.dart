/// Pokémon UNITE的なロール区分。単なるフレーバーではなく、
/// BattleEngine.manualSkill()がこの値で分岐し実際に異なる挙動を取る
/// （defender=自己シールド、supporter=自己+味方回復、その他=従来通りの範囲攻撃）。
enum MechaRole { attacker, defender, speedster, supporter, allRounder }

MechaRole mechaRoleFromString(String? value) {
  switch (value) {
    case 'defender':
      return MechaRole.defender;
    case 'speedster':
      return MechaRole.speedster;
    case 'supporter':
      return MechaRole.supporter;
    case 'allRounder':
      return MechaRole.allRounder;
    case 'attacker':
    default:
      return MechaRole.attacker;
  }
}

class BaseStats {
  final int hp;
  final int atk;
  final int spd;

  BaseStats({required this.hp, required this.atk, required this.spd});

  factory BaseStats.fromJson(Map<String, dynamic> json) {
    return BaseStats(
      hp: json['hp'] as int? ?? 100,
      atk: json['atk'] as int? ?? 50,
      spd: json['spd'] as int? ?? 40,
    );
  }

  Map<String, dynamic> toJson() => {'hp': hp, 'atk': atk, 'spd': spd};
}

class Skin {
  final String skinId;
  final String name;
  final String imageUrl;
  final int priceGems;

  Skin({
    required this.skinId,
    required this.name,
    required this.imageUrl,
    required this.priceGems,
  });

  factory Skin.fromJson(Map<String, dynamic> json) {
    return Skin(
      skinId: json['skinId'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      priceGems: json['priceGems'] as int? ?? 300,
    );
  }

  Map<String, dynamic> toJson() => {
    'skinId': skinId,
    'name': name,
    'imageUrl': imageUrl,
    'priceGems': priceGems,
  };
}

class Mecha {
  final String mechaId;
  final String name;
  final String rarity; // COMMON, RARE, EPIC, LEGEND
  final String origin; // EAST or WEST
  final MechaRole role;
  final BaseStats baseStats;
  final String iconUrl;
  final List<Skin> skins;
  final String description;

  Mecha({
    required this.mechaId,
    required this.name,
    required this.rarity,
    required this.origin,
    this.role = MechaRole.attacker,
    required this.baseStats,
    required this.iconUrl,
    required this.skins,
    required this.description,
  });

  Mecha copyWith({
    String? mechaId,
    String? name,
    String? rarity,
    String? origin,
    MechaRole? role,
    BaseStats? baseStats,
    String? iconUrl,
    List<Skin>? skins,
    String? description,
  }) {
    return Mecha(
      mechaId: mechaId ?? this.mechaId,
      name: name ?? this.name,
      rarity: rarity ?? this.rarity,
      origin: origin ?? this.origin,
      role: role ?? this.role,
      baseStats: baseStats ?? this.baseStats,
      iconUrl: iconUrl ?? this.iconUrl,
      skins: skins ?? this.skins,
      description: description ?? this.description,
    );
  }

  factory Mecha.fromJson(Map<String, dynamic> json) {
    return Mecha(
      mechaId: json['mechaId'] as String,
      name: json['name'] as String,
      rarity: json['rarity'] as String? ?? 'COMMON',
      origin: json['origin'] as String? ?? 'EAST',
      role: mechaRoleFromString(json['role'] as String?),
      baseStats: json['baseStats'] != null
          ? BaseStats.fromJson(json['baseStats'] as Map<String, dynamic>)
          : BaseStats(hp: 100, atk: 50, spd: 40),
      iconUrl: json['iconUrl'] as String,
      skins:
          (json['skins'] as List<dynamic>?)
              ?.map((e) => Skin.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'mechaId': mechaId,
    'name': name,
    'rarity': rarity,
    'origin': origin,
    'role': role.name,
    'baseStats': baseStats.toJson(),
    'iconUrl': iconUrl,
    'skins': skins.map((s) => s.toJson()).toList(),
    'description': description,
  };
}
