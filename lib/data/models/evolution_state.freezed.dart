// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'evolution_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

EvolutionRecord _$EvolutionRecordFromJson(Map<String, dynamic> json) {
  return _EvolutionRecord.fromJson(json);
}

/// @nodoc
mixin _$EvolutionRecord {
  int get level => throw _privateConstructorUsedError;
  EvolutionType get choice => throw _privateConstructorUsedError;
  DateTime get selectedAt => throw _privateConstructorUsedError;

  /// Serializes this EvolutionRecord to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EvolutionRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EvolutionRecordCopyWith<EvolutionRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EvolutionRecordCopyWith<$Res> {
  factory $EvolutionRecordCopyWith(
    EvolutionRecord value,
    $Res Function(EvolutionRecord) then,
  ) = _$EvolutionRecordCopyWithImpl<$Res, EvolutionRecord>;
  @useResult
  $Res call({int level, EvolutionType choice, DateTime selectedAt});
}

/// @nodoc
class _$EvolutionRecordCopyWithImpl<$Res, $Val extends EvolutionRecord>
    implements $EvolutionRecordCopyWith<$Res> {
  _$EvolutionRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EvolutionRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? level = null,
    Object? choice = null,
    Object? selectedAt = null,
  }) {
    return _then(
      _value.copyWith(
            level: null == level
                ? _value.level
                : level // ignore: cast_nullable_to_non_nullable
                      as int,
            choice: null == choice
                ? _value.choice
                : choice // ignore: cast_nullable_to_non_nullable
                      as EvolutionType,
            selectedAt: null == selectedAt
                ? _value.selectedAt
                : selectedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$EvolutionRecordImplCopyWith<$Res>
    implements $EvolutionRecordCopyWith<$Res> {
  factory _$$EvolutionRecordImplCopyWith(
    _$EvolutionRecordImpl value,
    $Res Function(_$EvolutionRecordImpl) then,
  ) = __$$EvolutionRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int level, EvolutionType choice, DateTime selectedAt});
}

/// @nodoc
class __$$EvolutionRecordImplCopyWithImpl<$Res>
    extends _$EvolutionRecordCopyWithImpl<$Res, _$EvolutionRecordImpl>
    implements _$$EvolutionRecordImplCopyWith<$Res> {
  __$$EvolutionRecordImplCopyWithImpl(
    _$EvolutionRecordImpl _value,
    $Res Function(_$EvolutionRecordImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EvolutionRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? level = null,
    Object? choice = null,
    Object? selectedAt = null,
  }) {
    return _then(
      _$EvolutionRecordImpl(
        level: null == level
            ? _value.level
            : level // ignore: cast_nullable_to_non_nullable
                  as int,
        choice: null == choice
            ? _value.choice
            : choice // ignore: cast_nullable_to_non_nullable
                  as EvolutionType,
        selectedAt: null == selectedAt
            ? _value.selectedAt
            : selectedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$EvolutionRecordImpl implements _EvolutionRecord {
  const _$EvolutionRecordImpl({
    required this.level,
    required this.choice,
    required this.selectedAt,
  });

  factory _$EvolutionRecordImpl.fromJson(Map<String, dynamic> json) =>
      _$$EvolutionRecordImplFromJson(json);

  @override
  final int level;
  @override
  final EvolutionType choice;
  @override
  final DateTime selectedAt;

  @override
  String toString() {
    return 'EvolutionRecord(level: $level, choice: $choice, selectedAt: $selectedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EvolutionRecordImpl &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.choice, choice) || other.choice == choice) &&
            (identical(other.selectedAt, selectedAt) ||
                other.selectedAt == selectedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, level, choice, selectedAt);

  /// Create a copy of EvolutionRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EvolutionRecordImplCopyWith<_$EvolutionRecordImpl> get copyWith =>
      __$$EvolutionRecordImplCopyWithImpl<_$EvolutionRecordImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$EvolutionRecordImplToJson(this);
  }
}

abstract class _EvolutionRecord implements EvolutionRecord {
  const factory _EvolutionRecord({
    required final int level,
    required final EvolutionType choice,
    required final DateTime selectedAt,
  }) = _$EvolutionRecordImpl;

  factory _EvolutionRecord.fromJson(Map<String, dynamic> json) =
      _$EvolutionRecordImpl.fromJson;

  @override
  int get level;
  @override
  EvolutionType get choice;
  @override
  DateTime get selectedAt;

  /// Create a copy of EvolutionRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EvolutionRecordImplCopyWith<_$EvolutionRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PlayerEvolutionState _$PlayerEvolutionStateFromJson(Map<String, dynamic> json) {
  return _PlayerEvolutionState.fromJson(json);
}

/// @nodoc
mixin _$PlayerEvolutionState {
  String get mechaId => throw _privateConstructorUsedError;
  EvolutionType? get currentEvolution => throw _privateConstructorUsedError;
  List<EvolutionRecord> get evolutionHistory =>
      throw _privateConstructorUsedError;
  int get lastEvolutionLevel => throw _privateConstructorUsedError;
  int get currentLevel => throw _privateConstructorUsedError;

  /// Serializes this PlayerEvolutionState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlayerEvolutionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerEvolutionStateCopyWith<PlayerEvolutionState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerEvolutionStateCopyWith<$Res> {
  factory $PlayerEvolutionStateCopyWith(
    PlayerEvolutionState value,
    $Res Function(PlayerEvolutionState) then,
  ) = _$PlayerEvolutionStateCopyWithImpl<$Res, PlayerEvolutionState>;
  @useResult
  $Res call({
    String mechaId,
    EvolutionType? currentEvolution,
    List<EvolutionRecord> evolutionHistory,
    int lastEvolutionLevel,
    int currentLevel,
  });
}

/// @nodoc
class _$PlayerEvolutionStateCopyWithImpl<
  $Res,
  $Val extends PlayerEvolutionState
>
    implements $PlayerEvolutionStateCopyWith<$Res> {
  _$PlayerEvolutionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlayerEvolutionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mechaId = null,
    Object? currentEvolution = freezed,
    Object? evolutionHistory = null,
    Object? lastEvolutionLevel = null,
    Object? currentLevel = null,
  }) {
    return _then(
      _value.copyWith(
            mechaId: null == mechaId
                ? _value.mechaId
                : mechaId // ignore: cast_nullable_to_non_nullable
                      as String,
            currentEvolution: freezed == currentEvolution
                ? _value.currentEvolution
                : currentEvolution // ignore: cast_nullable_to_non_nullable
                      as EvolutionType?,
            evolutionHistory: null == evolutionHistory
                ? _value.evolutionHistory
                : evolutionHistory // ignore: cast_nullable_to_non_nullable
                      as List<EvolutionRecord>,
            lastEvolutionLevel: null == lastEvolutionLevel
                ? _value.lastEvolutionLevel
                : lastEvolutionLevel // ignore: cast_nullable_to_non_nullable
                      as int,
            currentLevel: null == currentLevel
                ? _value.currentLevel
                : currentLevel // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PlayerEvolutionStateImplCopyWith<$Res>
    implements $PlayerEvolutionStateCopyWith<$Res> {
  factory _$$PlayerEvolutionStateImplCopyWith(
    _$PlayerEvolutionStateImpl value,
    $Res Function(_$PlayerEvolutionStateImpl) then,
  ) = __$$PlayerEvolutionStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String mechaId,
    EvolutionType? currentEvolution,
    List<EvolutionRecord> evolutionHistory,
    int lastEvolutionLevel,
    int currentLevel,
  });
}

/// @nodoc
class __$$PlayerEvolutionStateImplCopyWithImpl<$Res>
    extends _$PlayerEvolutionStateCopyWithImpl<$Res, _$PlayerEvolutionStateImpl>
    implements _$$PlayerEvolutionStateImplCopyWith<$Res> {
  __$$PlayerEvolutionStateImplCopyWithImpl(
    _$PlayerEvolutionStateImpl _value,
    $Res Function(_$PlayerEvolutionStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlayerEvolutionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mechaId = null,
    Object? currentEvolution = freezed,
    Object? evolutionHistory = null,
    Object? lastEvolutionLevel = null,
    Object? currentLevel = null,
  }) {
    return _then(
      _$PlayerEvolutionStateImpl(
        mechaId: null == mechaId
            ? _value.mechaId
            : mechaId // ignore: cast_nullable_to_non_nullable
                  as String,
        currentEvolution: freezed == currentEvolution
            ? _value.currentEvolution
            : currentEvolution // ignore: cast_nullable_to_non_nullable
                  as EvolutionType?,
        evolutionHistory: null == evolutionHistory
            ? _value._evolutionHistory
            : evolutionHistory // ignore: cast_nullable_to_non_nullable
                  as List<EvolutionRecord>,
        lastEvolutionLevel: null == lastEvolutionLevel
            ? _value.lastEvolutionLevel
            : lastEvolutionLevel // ignore: cast_nullable_to_non_nullable
                  as int,
        currentLevel: null == currentLevel
            ? _value.currentLevel
            : currentLevel // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlayerEvolutionStateImpl extends _PlayerEvolutionState {
  const _$PlayerEvolutionStateImpl({
    required this.mechaId,
    required this.currentEvolution,
    required final List<EvolutionRecord> evolutionHistory,
    required this.lastEvolutionLevel,
    required this.currentLevel,
  }) : _evolutionHistory = evolutionHistory,
       super._();

  factory _$PlayerEvolutionStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerEvolutionStateImplFromJson(json);

  @override
  final String mechaId;
  @override
  final EvolutionType? currentEvolution;
  final List<EvolutionRecord> _evolutionHistory;
  @override
  List<EvolutionRecord> get evolutionHistory {
    if (_evolutionHistory is EqualUnmodifiableListView)
      return _evolutionHistory;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_evolutionHistory);
  }

  @override
  final int lastEvolutionLevel;
  @override
  final int currentLevel;

  @override
  String toString() {
    return 'PlayerEvolutionState(mechaId: $mechaId, currentEvolution: $currentEvolution, evolutionHistory: $evolutionHistory, lastEvolutionLevel: $lastEvolutionLevel, currentLevel: $currentLevel)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerEvolutionStateImpl &&
            (identical(other.mechaId, mechaId) || other.mechaId == mechaId) &&
            (identical(other.currentEvolution, currentEvolution) ||
                other.currentEvolution == currentEvolution) &&
            const DeepCollectionEquality().equals(
              other._evolutionHistory,
              _evolutionHistory,
            ) &&
            (identical(other.lastEvolutionLevel, lastEvolutionLevel) ||
                other.lastEvolutionLevel == lastEvolutionLevel) &&
            (identical(other.currentLevel, currentLevel) ||
                other.currentLevel == currentLevel));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    mechaId,
    currentEvolution,
    const DeepCollectionEquality().hash(_evolutionHistory),
    lastEvolutionLevel,
    currentLevel,
  );

  /// Create a copy of PlayerEvolutionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerEvolutionStateImplCopyWith<_$PlayerEvolutionStateImpl>
  get copyWith =>
      __$$PlayerEvolutionStateImplCopyWithImpl<_$PlayerEvolutionStateImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayerEvolutionStateImplToJson(this);
  }
}

abstract class _PlayerEvolutionState extends PlayerEvolutionState {
  const factory _PlayerEvolutionState({
    required final String mechaId,
    required final EvolutionType? currentEvolution,
    required final List<EvolutionRecord> evolutionHistory,
    required final int lastEvolutionLevel,
    required final int currentLevel,
  }) = _$PlayerEvolutionStateImpl;
  const _PlayerEvolutionState._() : super._();

  factory _PlayerEvolutionState.fromJson(Map<String, dynamic> json) =
      _$PlayerEvolutionStateImpl.fromJson;

  @override
  String get mechaId;
  @override
  EvolutionType? get currentEvolution;
  @override
  List<EvolutionRecord> get evolutionHistory;
  @override
  int get lastEvolutionLevel;
  @override
  int get currentLevel;

  /// Create a copy of PlayerEvolutionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerEvolutionStateImplCopyWith<_$PlayerEvolutionStateImpl>
  get copyWith => throw _privateConstructorUsedError;
}

EvolutionSelectionState _$EvolutionSelectionStateFromJson(
  Map<String, dynamic> json,
) {
  return _EvolutionSelectionState.fromJson(json);
}

/// @nodoc
mixin _$EvolutionSelectionState {
  int get targetLevel => throw _privateConstructorUsedError; // 3 or 6
  bool get isVisible => throw _privateConstructorUsedError;
  int get remainingSeconds => throw _privateConstructorUsedError; // カウントダウン秒数
  EvolutionType? get selectedChoice => throw _privateConstructorUsedError;

  /// Serializes this EvolutionSelectionState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EvolutionSelectionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EvolutionSelectionStateCopyWith<EvolutionSelectionState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EvolutionSelectionStateCopyWith<$Res> {
  factory $EvolutionSelectionStateCopyWith(
    EvolutionSelectionState value,
    $Res Function(EvolutionSelectionState) then,
  ) = _$EvolutionSelectionStateCopyWithImpl<$Res, EvolutionSelectionState>;
  @useResult
  $Res call({
    int targetLevel,
    bool isVisible,
    int remainingSeconds,
    EvolutionType? selectedChoice,
  });
}

/// @nodoc
class _$EvolutionSelectionStateCopyWithImpl<
  $Res,
  $Val extends EvolutionSelectionState
>
    implements $EvolutionSelectionStateCopyWith<$Res> {
  _$EvolutionSelectionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EvolutionSelectionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetLevel = null,
    Object? isVisible = null,
    Object? remainingSeconds = null,
    Object? selectedChoice = freezed,
  }) {
    return _then(
      _value.copyWith(
            targetLevel: null == targetLevel
                ? _value.targetLevel
                : targetLevel // ignore: cast_nullable_to_non_nullable
                      as int,
            isVisible: null == isVisible
                ? _value.isVisible
                : isVisible // ignore: cast_nullable_to_non_nullable
                      as bool,
            remainingSeconds: null == remainingSeconds
                ? _value.remainingSeconds
                : remainingSeconds // ignore: cast_nullable_to_non_nullable
                      as int,
            selectedChoice: freezed == selectedChoice
                ? _value.selectedChoice
                : selectedChoice // ignore: cast_nullable_to_non_nullable
                      as EvolutionType?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$EvolutionSelectionStateImplCopyWith<$Res>
    implements $EvolutionSelectionStateCopyWith<$Res> {
  factory _$$EvolutionSelectionStateImplCopyWith(
    _$EvolutionSelectionStateImpl value,
    $Res Function(_$EvolutionSelectionStateImpl) then,
  ) = __$$EvolutionSelectionStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int targetLevel,
    bool isVisible,
    int remainingSeconds,
    EvolutionType? selectedChoice,
  });
}

/// @nodoc
class __$$EvolutionSelectionStateImplCopyWithImpl<$Res>
    extends
        _$EvolutionSelectionStateCopyWithImpl<
          $Res,
          _$EvolutionSelectionStateImpl
        >
    implements _$$EvolutionSelectionStateImplCopyWith<$Res> {
  __$$EvolutionSelectionStateImplCopyWithImpl(
    _$EvolutionSelectionStateImpl _value,
    $Res Function(_$EvolutionSelectionStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EvolutionSelectionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetLevel = null,
    Object? isVisible = null,
    Object? remainingSeconds = null,
    Object? selectedChoice = freezed,
  }) {
    return _then(
      _$EvolutionSelectionStateImpl(
        targetLevel: null == targetLevel
            ? _value.targetLevel
            : targetLevel // ignore: cast_nullable_to_non_nullable
                  as int,
        isVisible: null == isVisible
            ? _value.isVisible
            : isVisible // ignore: cast_nullable_to_non_nullable
                  as bool,
        remainingSeconds: null == remainingSeconds
            ? _value.remainingSeconds
            : remainingSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
        selectedChoice: freezed == selectedChoice
            ? _value.selectedChoice
            : selectedChoice // ignore: cast_nullable_to_non_nullable
                  as EvolutionType?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$EvolutionSelectionStateImpl extends _EvolutionSelectionState {
  const _$EvolutionSelectionStateImpl({
    required this.targetLevel,
    required this.isVisible,
    required this.remainingSeconds,
    this.selectedChoice,
  }) : super._();

  factory _$EvolutionSelectionStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$EvolutionSelectionStateImplFromJson(json);

  @override
  final int targetLevel;
  // 3 or 6
  @override
  final bool isVisible;
  @override
  final int remainingSeconds;
  // カウントダウン秒数
  @override
  final EvolutionType? selectedChoice;

  @override
  String toString() {
    return 'EvolutionSelectionState(targetLevel: $targetLevel, isVisible: $isVisible, remainingSeconds: $remainingSeconds, selectedChoice: $selectedChoice)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EvolutionSelectionStateImpl &&
            (identical(other.targetLevel, targetLevel) ||
                other.targetLevel == targetLevel) &&
            (identical(other.isVisible, isVisible) ||
                other.isVisible == isVisible) &&
            (identical(other.remainingSeconds, remainingSeconds) ||
                other.remainingSeconds == remainingSeconds) &&
            (identical(other.selectedChoice, selectedChoice) ||
                other.selectedChoice == selectedChoice));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    targetLevel,
    isVisible,
    remainingSeconds,
    selectedChoice,
  );

  /// Create a copy of EvolutionSelectionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EvolutionSelectionStateImplCopyWith<_$EvolutionSelectionStateImpl>
  get copyWith =>
      __$$EvolutionSelectionStateImplCopyWithImpl<
        _$EvolutionSelectionStateImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EvolutionSelectionStateImplToJson(this);
  }
}

abstract class _EvolutionSelectionState extends EvolutionSelectionState {
  const factory _EvolutionSelectionState({
    required final int targetLevel,
    required final bool isVisible,
    required final int remainingSeconds,
    final EvolutionType? selectedChoice,
  }) = _$EvolutionSelectionStateImpl;
  const _EvolutionSelectionState._() : super._();

  factory _EvolutionSelectionState.fromJson(Map<String, dynamic> json) =
      _$EvolutionSelectionStateImpl.fromJson;

  @override
  int get targetLevel; // 3 or 6
  @override
  bool get isVisible;
  @override
  int get remainingSeconds; // カウントダウン秒数
  @override
  EvolutionType? get selectedChoice;

  /// Create a copy of EvolutionSelectionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EvolutionSelectionStateImplCopyWith<_$EvolutionSelectionStateImpl>
  get copyWith => throw _privateConstructorUsedError;
}

SkillProgression _$SkillProgressionFromJson(Map<String, dynamic> json) {
  return _SkillProgression.fromJson(json);
}

/// @nodoc
mixin _$SkillProgression {
  String get skillId => throw _privateConstructorUsedError;
  Map<int, int> get levelToDamage =>
      throw _privateConstructorUsedError; // Lv → ダメージ値
  Map<int, double> get levelToCooldown => throw _privateConstructorUsedError;

  /// Serializes this SkillProgression to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SkillProgression
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SkillProgressionCopyWith<SkillProgression> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SkillProgressionCopyWith<$Res> {
  factory $SkillProgressionCopyWith(
    SkillProgression value,
    $Res Function(SkillProgression) then,
  ) = _$SkillProgressionCopyWithImpl<$Res, SkillProgression>;
  @useResult
  $Res call({
    String skillId,
    Map<int, int> levelToDamage,
    Map<int, double> levelToCooldown,
  });
}

/// @nodoc
class _$SkillProgressionCopyWithImpl<$Res, $Val extends SkillProgression>
    implements $SkillProgressionCopyWith<$Res> {
  _$SkillProgressionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SkillProgression
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? skillId = null,
    Object? levelToDamage = null,
    Object? levelToCooldown = null,
  }) {
    return _then(
      _value.copyWith(
            skillId: null == skillId
                ? _value.skillId
                : skillId // ignore: cast_nullable_to_non_nullable
                      as String,
            levelToDamage: null == levelToDamage
                ? _value.levelToDamage
                : levelToDamage // ignore: cast_nullable_to_non_nullable
                      as Map<int, int>,
            levelToCooldown: null == levelToCooldown
                ? _value.levelToCooldown
                : levelToCooldown // ignore: cast_nullable_to_non_nullable
                      as Map<int, double>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SkillProgressionImplCopyWith<$Res>
    implements $SkillProgressionCopyWith<$Res> {
  factory _$$SkillProgressionImplCopyWith(
    _$SkillProgressionImpl value,
    $Res Function(_$SkillProgressionImpl) then,
  ) = __$$SkillProgressionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String skillId,
    Map<int, int> levelToDamage,
    Map<int, double> levelToCooldown,
  });
}

/// @nodoc
class __$$SkillProgressionImplCopyWithImpl<$Res>
    extends _$SkillProgressionCopyWithImpl<$Res, _$SkillProgressionImpl>
    implements _$$SkillProgressionImplCopyWith<$Res> {
  __$$SkillProgressionImplCopyWithImpl(
    _$SkillProgressionImpl _value,
    $Res Function(_$SkillProgressionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SkillProgression
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? skillId = null,
    Object? levelToDamage = null,
    Object? levelToCooldown = null,
  }) {
    return _then(
      _$SkillProgressionImpl(
        skillId: null == skillId
            ? _value.skillId
            : skillId // ignore: cast_nullable_to_non_nullable
                  as String,
        levelToDamage: null == levelToDamage
            ? _value._levelToDamage
            : levelToDamage // ignore: cast_nullable_to_non_nullable
                  as Map<int, int>,
        levelToCooldown: null == levelToCooldown
            ? _value._levelToCooldown
            : levelToCooldown // ignore: cast_nullable_to_non_nullable
                  as Map<int, double>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SkillProgressionImpl extends _SkillProgression {
  const _$SkillProgressionImpl({
    required this.skillId,
    required final Map<int, int> levelToDamage,
    required final Map<int, double> levelToCooldown,
  }) : _levelToDamage = levelToDamage,
       _levelToCooldown = levelToCooldown,
       super._();

  factory _$SkillProgressionImpl.fromJson(Map<String, dynamic> json) =>
      _$$SkillProgressionImplFromJson(json);

  @override
  final String skillId;
  final Map<int, int> _levelToDamage;
  @override
  Map<int, int> get levelToDamage {
    if (_levelToDamage is EqualUnmodifiableMapView) return _levelToDamage;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_levelToDamage);
  }

  // Lv → ダメージ値
  final Map<int, double> _levelToCooldown;
  // Lv → ダメージ値
  @override
  Map<int, double> get levelToCooldown {
    if (_levelToCooldown is EqualUnmodifiableMapView) return _levelToCooldown;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_levelToCooldown);
  }

  @override
  String toString() {
    return 'SkillProgression(skillId: $skillId, levelToDamage: $levelToDamage, levelToCooldown: $levelToCooldown)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SkillProgressionImpl &&
            (identical(other.skillId, skillId) || other.skillId == skillId) &&
            const DeepCollectionEquality().equals(
              other._levelToDamage,
              _levelToDamage,
            ) &&
            const DeepCollectionEquality().equals(
              other._levelToCooldown,
              _levelToCooldown,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    skillId,
    const DeepCollectionEquality().hash(_levelToDamage),
    const DeepCollectionEquality().hash(_levelToCooldown),
  );

  /// Create a copy of SkillProgression
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SkillProgressionImplCopyWith<_$SkillProgressionImpl> get copyWith =>
      __$$SkillProgressionImplCopyWithImpl<_$SkillProgressionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SkillProgressionImplToJson(this);
  }
}

abstract class _SkillProgression extends SkillProgression {
  const factory _SkillProgression({
    required final String skillId,
    required final Map<int, int> levelToDamage,
    required final Map<int, double> levelToCooldown,
  }) = _$SkillProgressionImpl;
  const _SkillProgression._() : super._();

  factory _SkillProgression.fromJson(Map<String, dynamic> json) =
      _$SkillProgressionImpl.fromJson;

  @override
  String get skillId;
  @override
  Map<int, int> get levelToDamage; // Lv → ダメージ値
  @override
  Map<int, double> get levelToCooldown;

  /// Create a copy of SkillProgression
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SkillProgressionImplCopyWith<_$SkillProgressionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
