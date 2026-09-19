// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'skill_catalog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SkillLevelData _$SkillLevelDataFromJson(Map<String, dynamic> json) {
  return _SkillLevelData.fromJson(json);
}

/// @nodoc
mixin _$SkillLevelData {
  int get level => throw _privateConstructorUsedError;
  int get damage =>
      throw _privateConstructorUsedError; // Q/R/ULT のダメージ、またはEの効果値（%）
  double get cooldown => throw _privateConstructorUsedError; // 秒単位
  String? get description => throw _privateConstructorUsedError;

  /// Serializes this SkillLevelData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SkillLevelData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SkillLevelDataCopyWith<SkillLevelData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SkillLevelDataCopyWith<$Res> {
  factory $SkillLevelDataCopyWith(
    SkillLevelData value,
    $Res Function(SkillLevelData) then,
  ) = _$SkillLevelDataCopyWithImpl<$Res, SkillLevelData>;
  @useResult
  $Res call({int level, int damage, double cooldown, String? description});
}

/// @nodoc
class _$SkillLevelDataCopyWithImpl<$Res, $Val extends SkillLevelData>
    implements $SkillLevelDataCopyWith<$Res> {
  _$SkillLevelDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SkillLevelData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? level = null,
    Object? damage = null,
    Object? cooldown = null,
    Object? description = freezed,
  }) {
    return _then(
      _value.copyWith(
            level: null == level
                ? _value.level
                : level // ignore: cast_nullable_to_non_nullable
                      as int,
            damage: null == damage
                ? _value.damage
                : damage // ignore: cast_nullable_to_non_nullable
                      as int,
            cooldown: null == cooldown
                ? _value.cooldown
                : cooldown // ignore: cast_nullable_to_non_nullable
                      as double,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SkillLevelDataImplCopyWith<$Res>
    implements $SkillLevelDataCopyWith<$Res> {
  factory _$$SkillLevelDataImplCopyWith(
    _$SkillLevelDataImpl value,
    $Res Function(_$SkillLevelDataImpl) then,
  ) = __$$SkillLevelDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int level, int damage, double cooldown, String? description});
}

/// @nodoc
class __$$SkillLevelDataImplCopyWithImpl<$Res>
    extends _$SkillLevelDataCopyWithImpl<$Res, _$SkillLevelDataImpl>
    implements _$$SkillLevelDataImplCopyWith<$Res> {
  __$$SkillLevelDataImplCopyWithImpl(
    _$SkillLevelDataImpl _value,
    $Res Function(_$SkillLevelDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SkillLevelData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? level = null,
    Object? damage = null,
    Object? cooldown = null,
    Object? description = freezed,
  }) {
    return _then(
      _$SkillLevelDataImpl(
        level: null == level
            ? _value.level
            : level // ignore: cast_nullable_to_non_nullable
                  as int,
        damage: null == damage
            ? _value.damage
            : damage // ignore: cast_nullable_to_non_nullable
                  as int,
        cooldown: null == cooldown
            ? _value.cooldown
            : cooldown // ignore: cast_nullable_to_non_nullable
                  as double,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SkillLevelDataImpl implements _SkillLevelData {
  const _$SkillLevelDataImpl({
    required this.level,
    required this.damage,
    required this.cooldown,
    this.description,
  });

  factory _$SkillLevelDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$SkillLevelDataImplFromJson(json);

  @override
  final int level;
  @override
  final int damage;
  // Q/R/ULT のダメージ、またはEの効果値（%）
  @override
  final double cooldown;
  // 秒単位
  @override
  final String? description;

  @override
  String toString() {
    return 'SkillLevelData(level: $level, damage: $damage, cooldown: $cooldown, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SkillLevelDataImpl &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.damage, damage) || other.damage == damage) &&
            (identical(other.cooldown, cooldown) ||
                other.cooldown == cooldown) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, level, damage, cooldown, description);

  /// Create a copy of SkillLevelData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SkillLevelDataImplCopyWith<_$SkillLevelDataImpl> get copyWith =>
      __$$SkillLevelDataImplCopyWithImpl<_$SkillLevelDataImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SkillLevelDataImplToJson(this);
  }
}

abstract class _SkillLevelData implements SkillLevelData {
  const factory _SkillLevelData({
    required final int level,
    required final int damage,
    required final double cooldown,
    final String? description,
  }) = _$SkillLevelDataImpl;

  factory _SkillLevelData.fromJson(Map<String, dynamic> json) =
      _$SkillLevelDataImpl.fromJson;

  @override
  int get level;
  @override
  int get damage; // Q/R/ULT のダメージ、またはEの効果値（%）
  @override
  double get cooldown; // 秒単位
  @override
  String? get description;

  /// Create a copy of SkillLevelData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SkillLevelDataImplCopyWith<_$SkillLevelDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SkillDefinition _$SkillDefinitionFromJson(Map<String, dynamic> json) {
  return _SkillDefinition.fromJson(json);
}

/// @nodoc
mixin _$SkillDefinition {
  String get skillId =>
      throw _privateConstructorUsedError; // e.g. 'leon_q', 'dragoon_ult'
  String get name => throw _privateConstructorUsedError;
  SkillSlot get slot => throw _privateConstructorUsedError;
  Map<int, SkillLevelData> get levelData =>
      throw _privateConstructorUsedError; // Lv → 数値マッピング
  String? get baseDescription => throw _privateConstructorUsedError;

  /// Serializes this SkillDefinition to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SkillDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SkillDefinitionCopyWith<SkillDefinition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SkillDefinitionCopyWith<$Res> {
  factory $SkillDefinitionCopyWith(
    SkillDefinition value,
    $Res Function(SkillDefinition) then,
  ) = _$SkillDefinitionCopyWithImpl<$Res, SkillDefinition>;
  @useResult
  $Res call({
    String skillId,
    String name,
    SkillSlot slot,
    Map<int, SkillLevelData> levelData,
    String? baseDescription,
  });
}

/// @nodoc
class _$SkillDefinitionCopyWithImpl<$Res, $Val extends SkillDefinition>
    implements $SkillDefinitionCopyWith<$Res> {
  _$SkillDefinitionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SkillDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? skillId = null,
    Object? name = null,
    Object? slot = null,
    Object? levelData = null,
    Object? baseDescription = freezed,
  }) {
    return _then(
      _value.copyWith(
            skillId: null == skillId
                ? _value.skillId
                : skillId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            slot: null == slot
                ? _value.slot
                : slot // ignore: cast_nullable_to_non_nullable
                      as SkillSlot,
            levelData: null == levelData
                ? _value.levelData
                : levelData // ignore: cast_nullable_to_non_nullable
                      as Map<int, SkillLevelData>,
            baseDescription: freezed == baseDescription
                ? _value.baseDescription
                : baseDescription // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SkillDefinitionImplCopyWith<$Res>
    implements $SkillDefinitionCopyWith<$Res> {
  factory _$$SkillDefinitionImplCopyWith(
    _$SkillDefinitionImpl value,
    $Res Function(_$SkillDefinitionImpl) then,
  ) = __$$SkillDefinitionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String skillId,
    String name,
    SkillSlot slot,
    Map<int, SkillLevelData> levelData,
    String? baseDescription,
  });
}

/// @nodoc
class __$$SkillDefinitionImplCopyWithImpl<$Res>
    extends _$SkillDefinitionCopyWithImpl<$Res, _$SkillDefinitionImpl>
    implements _$$SkillDefinitionImplCopyWith<$Res> {
  __$$SkillDefinitionImplCopyWithImpl(
    _$SkillDefinitionImpl _value,
    $Res Function(_$SkillDefinitionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SkillDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? skillId = null,
    Object? name = null,
    Object? slot = null,
    Object? levelData = null,
    Object? baseDescription = freezed,
  }) {
    return _then(
      _$SkillDefinitionImpl(
        skillId: null == skillId
            ? _value.skillId
            : skillId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        slot: null == slot
            ? _value.slot
            : slot // ignore: cast_nullable_to_non_nullable
                  as SkillSlot,
        levelData: null == levelData
            ? _value._levelData
            : levelData // ignore: cast_nullable_to_non_nullable
                  as Map<int, SkillLevelData>,
        baseDescription: freezed == baseDescription
            ? _value.baseDescription
            : baseDescription // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SkillDefinitionImpl extends _SkillDefinition {
  const _$SkillDefinitionImpl({
    required this.skillId,
    required this.name,
    required this.slot,
    required final Map<int, SkillLevelData> levelData,
    this.baseDescription,
  }) : _levelData = levelData,
       super._();

  factory _$SkillDefinitionImpl.fromJson(Map<String, dynamic> json) =>
      _$$SkillDefinitionImplFromJson(json);

  @override
  final String skillId;
  // e.g. 'leon_q', 'dragoon_ult'
  @override
  final String name;
  @override
  final SkillSlot slot;
  final Map<int, SkillLevelData> _levelData;
  @override
  Map<int, SkillLevelData> get levelData {
    if (_levelData is EqualUnmodifiableMapView) return _levelData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_levelData);
  }

  // Lv → 数値マッピング
  @override
  final String? baseDescription;

  @override
  String toString() {
    return 'SkillDefinition(skillId: $skillId, name: $name, slot: $slot, levelData: $levelData, baseDescription: $baseDescription)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SkillDefinitionImpl &&
            (identical(other.skillId, skillId) || other.skillId == skillId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.slot, slot) || other.slot == slot) &&
            const DeepCollectionEquality().equals(
              other._levelData,
              _levelData,
            ) &&
            (identical(other.baseDescription, baseDescription) ||
                other.baseDescription == baseDescription));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    skillId,
    name,
    slot,
    const DeepCollectionEquality().hash(_levelData),
    baseDescription,
  );

  /// Create a copy of SkillDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SkillDefinitionImplCopyWith<_$SkillDefinitionImpl> get copyWith =>
      __$$SkillDefinitionImplCopyWithImpl<_$SkillDefinitionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SkillDefinitionImplToJson(this);
  }
}

abstract class _SkillDefinition extends SkillDefinition {
  const factory _SkillDefinition({
    required final String skillId,
    required final String name,
    required final SkillSlot slot,
    required final Map<int, SkillLevelData> levelData,
    final String? baseDescription,
  }) = _$SkillDefinitionImpl;
  const _SkillDefinition._() : super._();

  factory _SkillDefinition.fromJson(Map<String, dynamic> json) =
      _$SkillDefinitionImpl.fromJson;

  @override
  String get skillId; // e.g. 'leon_q', 'dragoon_ult'
  @override
  String get name;
  @override
  SkillSlot get slot;
  @override
  Map<int, SkillLevelData> get levelData; // Lv → 数値マッピング
  @override
  String? get baseDescription;

  /// Create a copy of SkillDefinition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SkillDefinitionImplCopyWith<_$SkillDefinitionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CharacterEvolution _$CharacterEvolutionFromJson(Map<String, dynamic> json) {
  return _CharacterEvolution.fromJson(json);
}

/// @nodoc
mixin _$CharacterEvolution {
  String get mechaId => throw _privateConstructorUsedError;
  EvolutionType? get evolutionAtLv3 =>
      throw _privateConstructorUsedError; // null = 未選択
  EvolutionType? get evolutionAtLv6 =>
      throw _privateConstructorUsedError; // Lv6で変更可能
  int get lastEvolutionLevel => throw _privateConstructorUsedError;

  /// Serializes this CharacterEvolution to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CharacterEvolution
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CharacterEvolutionCopyWith<CharacterEvolution> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CharacterEvolutionCopyWith<$Res> {
  factory $CharacterEvolutionCopyWith(
    CharacterEvolution value,
    $Res Function(CharacterEvolution) then,
  ) = _$CharacterEvolutionCopyWithImpl<$Res, CharacterEvolution>;
  @useResult
  $Res call({
    String mechaId,
    EvolutionType? evolutionAtLv3,
    EvolutionType? evolutionAtLv6,
    int lastEvolutionLevel,
  });
}

/// @nodoc
class _$CharacterEvolutionCopyWithImpl<$Res, $Val extends CharacterEvolution>
    implements $CharacterEvolutionCopyWith<$Res> {
  _$CharacterEvolutionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CharacterEvolution
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mechaId = null,
    Object? evolutionAtLv3 = freezed,
    Object? evolutionAtLv6 = freezed,
    Object? lastEvolutionLevel = null,
  }) {
    return _then(
      _value.copyWith(
            mechaId: null == mechaId
                ? _value.mechaId
                : mechaId // ignore: cast_nullable_to_non_nullable
                      as String,
            evolutionAtLv3: freezed == evolutionAtLv3
                ? _value.evolutionAtLv3
                : evolutionAtLv3 // ignore: cast_nullable_to_non_nullable
                      as EvolutionType?,
            evolutionAtLv6: freezed == evolutionAtLv6
                ? _value.evolutionAtLv6
                : evolutionAtLv6 // ignore: cast_nullable_to_non_nullable
                      as EvolutionType?,
            lastEvolutionLevel: null == lastEvolutionLevel
                ? _value.lastEvolutionLevel
                : lastEvolutionLevel // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CharacterEvolutionImplCopyWith<$Res>
    implements $CharacterEvolutionCopyWith<$Res> {
  factory _$$CharacterEvolutionImplCopyWith(
    _$CharacterEvolutionImpl value,
    $Res Function(_$CharacterEvolutionImpl) then,
  ) = __$$CharacterEvolutionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String mechaId,
    EvolutionType? evolutionAtLv3,
    EvolutionType? evolutionAtLv6,
    int lastEvolutionLevel,
  });
}

/// @nodoc
class __$$CharacterEvolutionImplCopyWithImpl<$Res>
    extends _$CharacterEvolutionCopyWithImpl<$Res, _$CharacterEvolutionImpl>
    implements _$$CharacterEvolutionImplCopyWith<$Res> {
  __$$CharacterEvolutionImplCopyWithImpl(
    _$CharacterEvolutionImpl _value,
    $Res Function(_$CharacterEvolutionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CharacterEvolution
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mechaId = null,
    Object? evolutionAtLv3 = freezed,
    Object? evolutionAtLv6 = freezed,
    Object? lastEvolutionLevel = null,
  }) {
    return _then(
      _$CharacterEvolutionImpl(
        mechaId: null == mechaId
            ? _value.mechaId
            : mechaId // ignore: cast_nullable_to_non_nullable
                  as String,
        evolutionAtLv3: freezed == evolutionAtLv3
            ? _value.evolutionAtLv3
            : evolutionAtLv3 // ignore: cast_nullable_to_non_nullable
                  as EvolutionType?,
        evolutionAtLv6: freezed == evolutionAtLv6
            ? _value.evolutionAtLv6
            : evolutionAtLv6 // ignore: cast_nullable_to_non_nullable
                  as EvolutionType?,
        lastEvolutionLevel: null == lastEvolutionLevel
            ? _value.lastEvolutionLevel
            : lastEvolutionLevel // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CharacterEvolutionImpl implements _CharacterEvolution {
  const _$CharacterEvolutionImpl({
    required this.mechaId,
    required this.evolutionAtLv3,
    required this.evolutionAtLv6,
    required this.lastEvolutionLevel,
  });

  factory _$CharacterEvolutionImpl.fromJson(Map<String, dynamic> json) =>
      _$$CharacterEvolutionImplFromJson(json);

  @override
  final String mechaId;
  @override
  final EvolutionType? evolutionAtLv3;
  // null = 未選択
  @override
  final EvolutionType? evolutionAtLv6;
  // Lv6で変更可能
  @override
  final int lastEvolutionLevel;

  @override
  String toString() {
    return 'CharacterEvolution(mechaId: $mechaId, evolutionAtLv3: $evolutionAtLv3, evolutionAtLv6: $evolutionAtLv6, lastEvolutionLevel: $lastEvolutionLevel)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CharacterEvolutionImpl &&
            (identical(other.mechaId, mechaId) || other.mechaId == mechaId) &&
            (identical(other.evolutionAtLv3, evolutionAtLv3) ||
                other.evolutionAtLv3 == evolutionAtLv3) &&
            (identical(other.evolutionAtLv6, evolutionAtLv6) ||
                other.evolutionAtLv6 == evolutionAtLv6) &&
            (identical(other.lastEvolutionLevel, lastEvolutionLevel) ||
                other.lastEvolutionLevel == lastEvolutionLevel));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    mechaId,
    evolutionAtLv3,
    evolutionAtLv6,
    lastEvolutionLevel,
  );

  /// Create a copy of CharacterEvolution
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CharacterEvolutionImplCopyWith<_$CharacterEvolutionImpl> get copyWith =>
      __$$CharacterEvolutionImplCopyWithImpl<_$CharacterEvolutionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CharacterEvolutionImplToJson(this);
  }
}

abstract class _CharacterEvolution implements CharacterEvolution {
  const factory _CharacterEvolution({
    required final String mechaId,
    required final EvolutionType? evolutionAtLv3,
    required final EvolutionType? evolutionAtLv6,
    required final int lastEvolutionLevel,
  }) = _$CharacterEvolutionImpl;

  factory _CharacterEvolution.fromJson(Map<String, dynamic> json) =
      _$CharacterEvolutionImpl.fromJson;

  @override
  String get mechaId;
  @override
  EvolutionType? get evolutionAtLv3; // null = 未選択
  @override
  EvolutionType? get evolutionAtLv6; // Lv6で変更可能
  @override
  int get lastEvolutionLevel;

  /// Create a copy of CharacterEvolution
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CharacterEvolutionImplCopyWith<_$CharacterEvolutionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
