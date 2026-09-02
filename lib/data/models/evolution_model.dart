enum EvolutionType {
  attack,
  defense,
  mobility;

  String get displayName {
    switch (this) {
      case EvolutionType.attack:
        return '攻撃';
      case EvolutionType.defense:
        return '防御';
      case EvolutionType.mobility:
        return '機動';
      default:
        return 'Unknown';
    }
  }
}

class StatBoost {
  final double hpMultiplier;
  final double atkMultiplier;
  final double spdMultiplier;

  StatBoost({
    required this.hpMultiplier,
    required this.atkMultiplier,
    required this.spdMultiplier,
  });

  factory StatBoost.fromJson(Map<String, dynamic> json) {
    return StatBoost(
      hpMultiplier: (json['hpMultiplier'] as num?)?.toDouble() ?? 1.0,
      atkMultiplier: (json['atkMultiplier'] as num?)?.toDouble() ?? 1.0,
      spdMultiplier: (json['spdMultiplier'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'hpMultiplier': hpMultiplier,
    'atkMultiplier': atkMultiplier,
    'spdMultiplier': spdMultiplier,
  };
}

class Evolution {
  final EvolutionType type;
  final StatBoost statBoost;
  final String description;

  Evolution({
    required this.type,
    required this.statBoost,
    required this.description,
  });

  factory Evolution.attack() => Evolution(
    type: EvolutionType.attack,
    statBoost: StatBoost(
      hpMultiplier: 1.0,
      atkMultiplier: 1.3,
      spdMultiplier: 1.0,
    ),
    description: '攻撃力が1.3倍になります',
  );

  factory Evolution.defense() => Evolution(
    type: EvolutionType.defense,
    statBoost: StatBoost(
      hpMultiplier: 1.3,
      atkMultiplier: 1.0,
      spdMultiplier: 1.0,
    ),
    description: 'HP が1.3倍になります',
  );

  factory Evolution.mobility() => Evolution(
    type: EvolutionType.mobility,
    statBoost: StatBoost(
      hpMultiplier: 1.0,
      atkMultiplier: 1.0,
      spdMultiplier: 1.3,
    ),
    description: '移動速度が1.3倍になります',
  );

  factory Evolution.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'attack';
    final type = EvolutionType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => EvolutionType.attack,
    );

    return Evolution(
      type: type,
      statBoost: json['statBoost'] != null
          ? StatBoost.fromJson(json['statBoost'] as Map<String, dynamic>)
          : StatBoost(
              hpMultiplier: 1.0,
              atkMultiplier: 1.0,
              spdMultiplier: 1.0,
            ),
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'statBoost': statBoost.toJson(),
    'description': description,
  };
}
