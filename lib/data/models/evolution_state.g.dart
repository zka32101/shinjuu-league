// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evolution_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EvolutionRecordImpl _$$EvolutionRecordImplFromJson(
  Map<String, dynamic> json,
) => _$EvolutionRecordImpl(
  level: (json['level'] as num).toInt(),
  choice: $enumDecode(_$EvolutionTypeEnumMap, json['choice']),
  selectedAt: DateTime.parse(json['selectedAt'] as String),
);

Map<String, dynamic> _$$EvolutionRecordImplToJson(
  _$EvolutionRecordImpl instance,
) => <String, dynamic>{
  'level': instance.level,
  'choice': _$EvolutionTypeEnumMap[instance.choice]!,
  'selectedAt': instance.selectedAt.toIso8601String(),
};

const _$EvolutionTypeEnumMap = {
  EvolutionType.offensive: 'offensive',
  EvolutionType.defensive: 'defensive',
  EvolutionType.support: 'support',
};

_$PlayerEvolutionStateImpl _$$PlayerEvolutionStateImplFromJson(
  Map<String, dynamic> json,
) => _$PlayerEvolutionStateImpl(
  mechaId: json['mechaId'] as String,
  currentEvolution: $enumDecodeNullable(
    _$EvolutionTypeEnumMap,
    json['currentEvolution'],
  ),
  evolutionHistory: (json['evolutionHistory'] as List<dynamic>)
      .map((e) => EvolutionRecord.fromJson(e as Map<String, dynamic>))
      .toList(),
  lastEvolutionLevel: (json['lastEvolutionLevel'] as num).toInt(),
  currentLevel: (json['currentLevel'] as num).toInt(),
);

Map<String, dynamic> _$$PlayerEvolutionStateImplToJson(
  _$PlayerEvolutionStateImpl instance,
) => <String, dynamic>{
  'mechaId': instance.mechaId,
  'currentEvolution': _$EvolutionTypeEnumMap[instance.currentEvolution],
  'evolutionHistory': instance.evolutionHistory,
  'lastEvolutionLevel': instance.lastEvolutionLevel,
  'currentLevel': instance.currentLevel,
};

_$EvolutionSelectionStateImpl _$$EvolutionSelectionStateImplFromJson(
  Map<String, dynamic> json,
) => _$EvolutionSelectionStateImpl(
  targetLevel: (json['targetLevel'] as num).toInt(),
  isVisible: json['isVisible'] as bool,
  remainingSeconds: (json['remainingSeconds'] as num).toInt(),
  selectedChoice: $enumDecodeNullable(
    _$EvolutionTypeEnumMap,
    json['selectedChoice'],
  ),
);

Map<String, dynamic> _$$EvolutionSelectionStateImplToJson(
  _$EvolutionSelectionStateImpl instance,
) => <String, dynamic>{
  'targetLevel': instance.targetLevel,
  'isVisible': instance.isVisible,
  'remainingSeconds': instance.remainingSeconds,
  'selectedChoice': _$EvolutionTypeEnumMap[instance.selectedChoice],
};

_$SkillProgressionImpl _$$SkillProgressionImplFromJson(
  Map<String, dynamic> json,
) => _$SkillProgressionImpl(
  skillId: json['skillId'] as String,
  levelToDamage: (json['levelToDamage'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(int.parse(k), (e as num).toInt()),
  ),
  levelToCooldown: (json['levelToCooldown'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(int.parse(k), (e as num).toDouble()),
  ),
);

Map<String, dynamic> _$$SkillProgressionImplToJson(
  _$SkillProgressionImpl instance,
) => <String, dynamic>{
  'skillId': instance.skillId,
  'levelToDamage': instance.levelToDamage.map(
    (k, e) => MapEntry(k.toString(), e),
  ),
  'levelToCooldown': instance.levelToCooldown.map(
    (k, e) => MapEntry(k.toString(), e),
  ),
};
