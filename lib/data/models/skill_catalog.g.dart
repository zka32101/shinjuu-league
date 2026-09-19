// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_catalog.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SkillLevelDataImpl _$$SkillLevelDataImplFromJson(Map<String, dynamic> json) =>
    _$SkillLevelDataImpl(
      level: (json['level'] as num).toInt(),
      damage: (json['damage'] as num).toInt(),
      cooldown: (json['cooldown'] as num).toDouble(),
      description: json['description'] as String?,
    );

Map<String, dynamic> _$$SkillLevelDataImplToJson(
  _$SkillLevelDataImpl instance,
) => <String, dynamic>{
  'level': instance.level,
  'damage': instance.damage,
  'cooldown': instance.cooldown,
  'description': instance.description,
};

_$SkillDefinitionImpl _$$SkillDefinitionImplFromJson(
  Map<String, dynamic> json,
) => _$SkillDefinitionImpl(
  skillId: json['skillId'] as String,
  name: json['name'] as String,
  slot: $enumDecode(_$SkillSlotEnumMap, json['slot']),
  levelData: (json['levelData'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(
      int.parse(k),
      SkillLevelData.fromJson(e as Map<String, dynamic>),
    ),
  ),
  baseDescription: json['baseDescription'] as String?,
);

Map<String, dynamic> _$$SkillDefinitionImplToJson(
  _$SkillDefinitionImpl instance,
) => <String, dynamic>{
  'skillId': instance.skillId,
  'name': instance.name,
  'slot': _$SkillSlotEnumMap[instance.slot]!,
  'levelData': instance.levelData.map(
    (k, e) => MapEntry(k.toString(), e.toJson()),
  ),
  'baseDescription': instance.baseDescription,
};

const _$SkillSlotEnumMap = {
  SkillSlot.q: 'q',
  SkillSlot.r: 'r',
  SkillSlot.e: 'e',
  SkillSlot.ult: 'ult',
};

_$CharacterEvolutionImpl _$$CharacterEvolutionImplFromJson(
  Map<String, dynamic> json,
) => _$CharacterEvolutionImpl(
  mechaId: json['mechaId'] as String,
  evolutionAtLv3: $enumDecodeNullable(
    _$EvolutionTypeEnumMap,
    json['evolutionAtLv3'],
  ),
  evolutionAtLv6: $enumDecodeNullable(
    _$EvolutionTypeEnumMap,
    json['evolutionAtLv6'],
  ),
  lastEvolutionLevel: (json['lastEvolutionLevel'] as num).toInt(),
);

Map<String, dynamic> _$$CharacterEvolutionImplToJson(
  _$CharacterEvolutionImpl instance,
) => <String, dynamic>{
  'mechaId': instance.mechaId,
  'evolutionAtLv3': _$EvolutionTypeEnumMap[instance.evolutionAtLv3],
  'evolutionAtLv6': _$EvolutionTypeEnumMap[instance.evolutionAtLv6],
  'lastEvolutionLevel': instance.lastEvolutionLevel,
};

const _$EvolutionTypeEnumMap = {
  EvolutionType.offensive: 'offensive',
  EvolutionType.defensive: 'defensive',
  EvolutionType.support: 'support',
};
