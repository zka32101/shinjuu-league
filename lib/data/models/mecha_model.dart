class BaseStats {
  final int hp;
  final int atk;
  final int spd;

  BaseStats({
    required this.hp,
    required this.atk,
    required this.spd,
  });

  factory BaseStats.fromJson(Map<String, dynamic> json) {
    return BaseStats(
      hp: json['hp'] as int? ?? 100,
      atk: json['atk'] as int? ?? 50,
      spd: json['spd'] as int? ?? 40,
    );
  }

  Map<String, dynamic> toJson() => {
    'hp': hp,
    'atk': atk,
    'spd': spd,
  };
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
  final BaseStats baseStats;
  final String iconUrl;
  final List<Skin> skins;
  final String description;

  Mecha({
    required this.mechaId,
    required this.name,
    required this.rarity,
    required this.origin,
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
      baseStats: json['baseStats'] != null
          ? BaseStats.fromJson(json['baseStats'] as Map<String, dynamic>)
          : BaseStats(hp: 100, atk: 50, spd: 40),
      iconUrl: json['iconUrl'] as String,
      skins: (json['skins'] as List<dynamic>?)
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
    'baseStats': baseStats.toJson(),
    'iconUrl': iconUrl,
    'skins': skins.map((s) => s.toJson()).toList(),
    'description': description,
  };
}
