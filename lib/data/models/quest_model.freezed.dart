// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quest_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

QuestCondition _$QuestConditionFromJson(Map<String, dynamic> json) {
  return _QuestCondition.fromJson(json);
}

/// @nodoc
mixin _$QuestCondition {
  QuestConditionType get type => throw _privateConstructorUsedError;
  int get target => throw _privateConstructorUsedError; // Goal value
  int get current => throw _privateConstructorUsedError;

  /// Serializes this QuestCondition to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of QuestCondition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QuestConditionCopyWith<QuestCondition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuestConditionCopyWith<$Res> {
  factory $QuestConditionCopyWith(
    QuestCondition value,
    $Res Function(QuestCondition) then,
  ) = _$QuestConditionCopyWithImpl<$Res, QuestCondition>;
  @useResult
  $Res call({QuestConditionType type, int target, int current});
}

/// @nodoc
class _$QuestConditionCopyWithImpl<$Res, $Val extends QuestCondition>
    implements $QuestConditionCopyWith<$Res> {
  _$QuestConditionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QuestCondition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? target = null,
    Object? current = null,
  }) {
    return _then(
      _value.copyWith(
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as QuestConditionType,
            target: null == target
                ? _value.target
                : target // ignore: cast_nullable_to_non_nullable
                      as int,
            current: null == current
                ? _value.current
                : current // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$QuestConditionImplCopyWith<$Res>
    implements $QuestConditionCopyWith<$Res> {
  factory _$$QuestConditionImplCopyWith(
    _$QuestConditionImpl value,
    $Res Function(_$QuestConditionImpl) then,
  ) = __$$QuestConditionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({QuestConditionType type, int target, int current});
}

/// @nodoc
class __$$QuestConditionImplCopyWithImpl<$Res>
    extends _$QuestConditionCopyWithImpl<$Res, _$QuestConditionImpl>
    implements _$$QuestConditionImplCopyWith<$Res> {
  __$$QuestConditionImplCopyWithImpl(
    _$QuestConditionImpl _value,
    $Res Function(_$QuestConditionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QuestCondition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? target = null,
    Object? current = null,
  }) {
    return _then(
      _$QuestConditionImpl(
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as QuestConditionType,
        target: null == target
            ? _value.target
            : target // ignore: cast_nullable_to_non_nullable
                  as int,
        current: null == current
            ? _value.current
            : current // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$QuestConditionImpl extends _QuestCondition {
  const _$QuestConditionImpl({
    required this.type,
    required this.target,
    this.current = 0,
  }) : super._();

  factory _$QuestConditionImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuestConditionImplFromJson(json);

  @override
  final QuestConditionType type;
  @override
  final int target;
  // Goal value
  @override
  @JsonKey()
  final int current;

  @override
  String toString() {
    return 'QuestCondition(type: $type, target: $target, current: $current)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuestConditionImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.target, target) || other.target == target) &&
            (identical(other.current, current) || other.current == current));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, type, target, current);

  /// Create a copy of QuestCondition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QuestConditionImplCopyWith<_$QuestConditionImpl> get copyWith =>
      __$$QuestConditionImplCopyWithImpl<_$QuestConditionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$QuestConditionImplToJson(this);
  }
}

abstract class _QuestCondition extends QuestCondition {
  const factory _QuestCondition({
    required final QuestConditionType type,
    required final int target,
    final int current,
  }) = _$QuestConditionImpl;
  const _QuestCondition._() : super._();

  factory _QuestCondition.fromJson(Map<String, dynamic> json) =
      _$QuestConditionImpl.fromJson;

  @override
  QuestConditionType get type;
  @override
  int get target; // Goal value
  @override
  int get current;

  /// Create a copy of QuestCondition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QuestConditionImplCopyWith<_$QuestConditionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

QuestReward _$QuestRewardFromJson(Map<String, dynamic> json) {
  return _QuestReward.fromJson(json);
}

/// @nodoc
mixin _$QuestReward {
  int get currency => throw _privateConstructorUsedError; // Gold/gems
  int get experiencePoints =>
      throw _privateConstructorUsedError; // XP for level progression
  int get achievementBadges =>
      throw _privateConstructorUsedError; // Cosmetic badges
  List<String> get cosmetics => throw _privateConstructorUsedError;

  /// Serializes this QuestReward to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of QuestReward
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QuestRewardCopyWith<QuestReward> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuestRewardCopyWith<$Res> {
  factory $QuestRewardCopyWith(
    QuestReward value,
    $Res Function(QuestReward) then,
  ) = _$QuestRewardCopyWithImpl<$Res, QuestReward>;
  @useResult
  $Res call({
    int currency,
    int experiencePoints,
    int achievementBadges,
    List<String> cosmetics,
  });
}

/// @nodoc
class _$QuestRewardCopyWithImpl<$Res, $Val extends QuestReward>
    implements $QuestRewardCopyWith<$Res> {
  _$QuestRewardCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QuestReward
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currency = null,
    Object? experiencePoints = null,
    Object? achievementBadges = null,
    Object? cosmetics = null,
  }) {
    return _then(
      _value.copyWith(
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as int,
            experiencePoints: null == experiencePoints
                ? _value.experiencePoints
                : experiencePoints // ignore: cast_nullable_to_non_nullable
                      as int,
            achievementBadges: null == achievementBadges
                ? _value.achievementBadges
                : achievementBadges // ignore: cast_nullable_to_non_nullable
                      as int,
            cosmetics: null == cosmetics
                ? _value.cosmetics
                : cosmetics // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$QuestRewardImplCopyWith<$Res>
    implements $QuestRewardCopyWith<$Res> {
  factory _$$QuestRewardImplCopyWith(
    _$QuestRewardImpl value,
    $Res Function(_$QuestRewardImpl) then,
  ) = __$$QuestRewardImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int currency,
    int experiencePoints,
    int achievementBadges,
    List<String> cosmetics,
  });
}

/// @nodoc
class __$$QuestRewardImplCopyWithImpl<$Res>
    extends _$QuestRewardCopyWithImpl<$Res, _$QuestRewardImpl>
    implements _$$QuestRewardImplCopyWith<$Res> {
  __$$QuestRewardImplCopyWithImpl(
    _$QuestRewardImpl _value,
    $Res Function(_$QuestRewardImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QuestReward
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currency = null,
    Object? experiencePoints = null,
    Object? achievementBadges = null,
    Object? cosmetics = null,
  }) {
    return _then(
      _$QuestRewardImpl(
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as int,
        experiencePoints: null == experiencePoints
            ? _value.experiencePoints
            : experiencePoints // ignore: cast_nullable_to_non_nullable
                  as int,
        achievementBadges: null == achievementBadges
            ? _value.achievementBadges
            : achievementBadges // ignore: cast_nullable_to_non_nullable
                  as int,
        cosmetics: null == cosmetics
            ? _value._cosmetics
            : cosmetics // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$QuestRewardImpl implements _QuestReward {
  const _$QuestRewardImpl({
    required this.currency,
    this.experiencePoints = 0,
    this.achievementBadges = 0,
    final List<String> cosmetics = const [],
  }) : _cosmetics = cosmetics;

  factory _$QuestRewardImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuestRewardImplFromJson(json);

  @override
  final int currency;
  // Gold/gems
  @override
  @JsonKey()
  final int experiencePoints;
  // XP for level progression
  @override
  @JsonKey()
  final int achievementBadges;
  // Cosmetic badges
  final List<String> _cosmetics;
  // Cosmetic badges
  @override
  @JsonKey()
  List<String> get cosmetics {
    if (_cosmetics is EqualUnmodifiableListView) return _cosmetics;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_cosmetics);
  }

  @override
  String toString() {
    return 'QuestReward(currency: $currency, experiencePoints: $experiencePoints, achievementBadges: $achievementBadges, cosmetics: $cosmetics)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuestRewardImpl &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.experiencePoints, experiencePoints) ||
                other.experiencePoints == experiencePoints) &&
            (identical(other.achievementBadges, achievementBadges) ||
                other.achievementBadges == achievementBadges) &&
            const DeepCollectionEquality().equals(
              other._cosmetics,
              _cosmetics,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    currency,
    experiencePoints,
    achievementBadges,
    const DeepCollectionEquality().hash(_cosmetics),
  );

  /// Create a copy of QuestReward
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QuestRewardImplCopyWith<_$QuestRewardImpl> get copyWith =>
      __$$QuestRewardImplCopyWithImpl<_$QuestRewardImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QuestRewardImplToJson(this);
  }
}

abstract class _QuestReward implements QuestReward {
  const factory _QuestReward({
    required final int currency,
    final int experiencePoints,
    final int achievementBadges,
    final List<String> cosmetics,
  }) = _$QuestRewardImpl;

  factory _QuestReward.fromJson(Map<String, dynamic> json) =
      _$QuestRewardImpl.fromJson;

  @override
  int get currency; // Gold/gems
  @override
  int get experiencePoints; // XP for level progression
  @override
  int get achievementBadges; // Cosmetic badges
  @override
  List<String> get cosmetics;

  /// Create a copy of QuestReward
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QuestRewardImplCopyWith<_$QuestRewardImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Quest _$QuestFromJson(Map<String, dynamic> json) {
  return _Quest.fromJson(json);
}

/// @nodoc
mixin _$Quest {
  String get questId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  QuestType get type => throw _privateConstructorUsedError;
  QuestFrequency get frequency => throw _privateConstructorUsedError;
  QuestDifficulty get difficulty => throw _privateConstructorUsedError;
  List<QuestCondition> get conditions =>
      throw _privateConstructorUsedError; // All must be met
  QuestReward get reward => throw _privateConstructorUsedError;
  DateTime? get availableFrom =>
      throw _privateConstructorUsedError; // When quest becomes available
  DateTime? get availableUntil =>
      throw _privateConstructorUsedError; // Quest expiration
  int? get displayOrder => throw _privateConstructorUsedError;

  /// Serializes this Quest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Quest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QuestCopyWith<Quest> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuestCopyWith<$Res> {
  factory $QuestCopyWith(Quest value, $Res Function(Quest) then) =
      _$QuestCopyWithImpl<$Res, Quest>;
  @useResult
  $Res call({
    String questId,
    String title,
    String description,
    QuestType type,
    QuestFrequency frequency,
    QuestDifficulty difficulty,
    List<QuestCondition> conditions,
    QuestReward reward,
    DateTime? availableFrom,
    DateTime? availableUntil,
    int? displayOrder,
  });

  $QuestRewardCopyWith<$Res> get reward;
}

/// @nodoc
class _$QuestCopyWithImpl<$Res, $Val extends Quest>
    implements $QuestCopyWith<$Res> {
  _$QuestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Quest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? questId = null,
    Object? title = null,
    Object? description = null,
    Object? type = null,
    Object? frequency = null,
    Object? difficulty = null,
    Object? conditions = null,
    Object? reward = null,
    Object? availableFrom = freezed,
    Object? availableUntil = freezed,
    Object? displayOrder = freezed,
  }) {
    return _then(
      _value.copyWith(
            questId: null == questId
                ? _value.questId
                : questId // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as QuestType,
            frequency: null == frequency
                ? _value.frequency
                : frequency // ignore: cast_nullable_to_non_nullable
                      as QuestFrequency,
            difficulty: null == difficulty
                ? _value.difficulty
                : difficulty // ignore: cast_nullable_to_non_nullable
                      as QuestDifficulty,
            conditions: null == conditions
                ? _value.conditions
                : conditions // ignore: cast_nullable_to_non_nullable
                      as List<QuestCondition>,
            reward: null == reward
                ? _value.reward
                : reward // ignore: cast_nullable_to_non_nullable
                      as QuestReward,
            availableFrom: freezed == availableFrom
                ? _value.availableFrom
                : availableFrom // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            availableUntil: freezed == availableUntil
                ? _value.availableUntil
                : availableUntil // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            displayOrder: freezed == displayOrder
                ? _value.displayOrder
                : displayOrder // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }

  /// Create a copy of Quest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $QuestRewardCopyWith<$Res> get reward {
    return $QuestRewardCopyWith<$Res>(_value.reward, (value) {
      return _then(_value.copyWith(reward: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$QuestImplCopyWith<$Res> implements $QuestCopyWith<$Res> {
  factory _$$QuestImplCopyWith(
    _$QuestImpl value,
    $Res Function(_$QuestImpl) then,
  ) = __$$QuestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String questId,
    String title,
    String description,
    QuestType type,
    QuestFrequency frequency,
    QuestDifficulty difficulty,
    List<QuestCondition> conditions,
    QuestReward reward,
    DateTime? availableFrom,
    DateTime? availableUntil,
    int? displayOrder,
  });

  @override
  $QuestRewardCopyWith<$Res> get reward;
}

/// @nodoc
class __$$QuestImplCopyWithImpl<$Res>
    extends _$QuestCopyWithImpl<$Res, _$QuestImpl>
    implements _$$QuestImplCopyWith<$Res> {
  __$$QuestImplCopyWithImpl(
    _$QuestImpl _value,
    $Res Function(_$QuestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Quest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? questId = null,
    Object? title = null,
    Object? description = null,
    Object? type = null,
    Object? frequency = null,
    Object? difficulty = null,
    Object? conditions = null,
    Object? reward = null,
    Object? availableFrom = freezed,
    Object? availableUntil = freezed,
    Object? displayOrder = freezed,
  }) {
    return _then(
      _$QuestImpl(
        questId: null == questId
            ? _value.questId
            : questId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as QuestType,
        frequency: null == frequency
            ? _value.frequency
            : frequency // ignore: cast_nullable_to_non_nullable
                  as QuestFrequency,
        difficulty: null == difficulty
            ? _value.difficulty
            : difficulty // ignore: cast_nullable_to_non_nullable
                  as QuestDifficulty,
        conditions: null == conditions
            ? _value._conditions
            : conditions // ignore: cast_nullable_to_non_nullable
                  as List<QuestCondition>,
        reward: null == reward
            ? _value.reward
            : reward // ignore: cast_nullable_to_non_nullable
                  as QuestReward,
        availableFrom: freezed == availableFrom
            ? _value.availableFrom
            : availableFrom // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        availableUntil: freezed == availableUntil
            ? _value.availableUntil
            : availableUntil // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        displayOrder: freezed == displayOrder
            ? _value.displayOrder
            : displayOrder // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$QuestImpl extends _Quest {
  const _$QuestImpl({
    required this.questId,
    required this.title,
    required this.description,
    required this.type,
    required this.frequency,
    required this.difficulty,
    required final List<QuestCondition> conditions,
    required this.reward,
    this.availableFrom,
    this.availableUntil,
    this.displayOrder,
  }) : _conditions = conditions,
       super._();

  factory _$QuestImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuestImplFromJson(json);

  @override
  final String questId;
  @override
  final String title;
  @override
  final String description;
  @override
  final QuestType type;
  @override
  final QuestFrequency frequency;
  @override
  final QuestDifficulty difficulty;
  final List<QuestCondition> _conditions;
  @override
  List<QuestCondition> get conditions {
    if (_conditions is EqualUnmodifiableListView) return _conditions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_conditions);
  }

  // All must be met
  @override
  final QuestReward reward;
  @override
  final DateTime? availableFrom;
  // When quest becomes available
  @override
  final DateTime? availableUntil;
  // Quest expiration
  @override
  final int? displayOrder;

  @override
  String toString() {
    return 'Quest(questId: $questId, title: $title, description: $description, type: $type, frequency: $frequency, difficulty: $difficulty, conditions: $conditions, reward: $reward, availableFrom: $availableFrom, availableUntil: $availableUntil, displayOrder: $displayOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuestImpl &&
            (identical(other.questId, questId) || other.questId == questId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.frequency, frequency) ||
                other.frequency == frequency) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            const DeepCollectionEquality().equals(
              other._conditions,
              _conditions,
            ) &&
            (identical(other.reward, reward) || other.reward == reward) &&
            (identical(other.availableFrom, availableFrom) ||
                other.availableFrom == availableFrom) &&
            (identical(other.availableUntil, availableUntil) ||
                other.availableUntil == availableUntil) &&
            (identical(other.displayOrder, displayOrder) ||
                other.displayOrder == displayOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    questId,
    title,
    description,
    type,
    frequency,
    difficulty,
    const DeepCollectionEquality().hash(_conditions),
    reward,
    availableFrom,
    availableUntil,
    displayOrder,
  );

  /// Create a copy of Quest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QuestImplCopyWith<_$QuestImpl> get copyWith =>
      __$$QuestImplCopyWithImpl<_$QuestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QuestImplToJson(this);
  }
}

abstract class _Quest extends Quest {
  const factory _Quest({
    required final String questId,
    required final String title,
    required final String description,
    required final QuestType type,
    required final QuestFrequency frequency,
    required final QuestDifficulty difficulty,
    required final List<QuestCondition> conditions,
    required final QuestReward reward,
    final DateTime? availableFrom,
    final DateTime? availableUntil,
    final int? displayOrder,
  }) = _$QuestImpl;
  const _Quest._() : super._();

  factory _Quest.fromJson(Map<String, dynamic> json) = _$QuestImpl.fromJson;

  @override
  String get questId;
  @override
  String get title;
  @override
  String get description;
  @override
  QuestType get type;
  @override
  QuestFrequency get frequency;
  @override
  QuestDifficulty get difficulty;
  @override
  List<QuestCondition> get conditions; // All must be met
  @override
  QuestReward get reward;
  @override
  DateTime? get availableFrom; // When quest becomes available
  @override
  DateTime? get availableUntil; // Quest expiration
  @override
  int? get displayOrder;

  /// Create a copy of Quest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QuestImplCopyWith<_$QuestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PlayerQuest _$PlayerQuestFromJson(Map<String, dynamic> json) {
  return _PlayerQuest.fromJson(json);
}

/// @nodoc
mixin _$PlayerQuest {
  String get userId => throw _privateConstructorUsedError;
  String get questId => throw _privateConstructorUsedError;
  List<QuestCondition> get conditions =>
      throw _privateConstructorUsedError; // Current progress on each condition
  bool get isCompleted => throw _privateConstructorUsedError;
  bool get isRewarded =>
      throw _privateConstructorUsedError; // Has player claimed reward?
  DateTime? get startedAt => throw _privateConstructorUsedError;
  DateTime? get completedAt => throw _privateConstructorUsedError;
  DateTime? get claimedRewardAt => throw _privateConstructorUsedError;

  /// Serializes this PlayerQuest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlayerQuest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerQuestCopyWith<PlayerQuest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerQuestCopyWith<$Res> {
  factory $PlayerQuestCopyWith(
    PlayerQuest value,
    $Res Function(PlayerQuest) then,
  ) = _$PlayerQuestCopyWithImpl<$Res, PlayerQuest>;
  @useResult
  $Res call({
    String userId,
    String questId,
    List<QuestCondition> conditions,
    bool isCompleted,
    bool isRewarded,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? claimedRewardAt,
  });
}

/// @nodoc
class _$PlayerQuestCopyWithImpl<$Res, $Val extends PlayerQuest>
    implements $PlayerQuestCopyWith<$Res> {
  _$PlayerQuestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlayerQuest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? questId = null,
    Object? conditions = null,
    Object? isCompleted = null,
    Object? isRewarded = null,
    Object? startedAt = freezed,
    Object? completedAt = freezed,
    Object? claimedRewardAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            questId: null == questId
                ? _value.questId
                : questId // ignore: cast_nullable_to_non_nullable
                      as String,
            conditions: null == conditions
                ? _value.conditions
                : conditions // ignore: cast_nullable_to_non_nullable
                      as List<QuestCondition>,
            isCompleted: null == isCompleted
                ? _value.isCompleted
                : isCompleted // ignore: cast_nullable_to_non_nullable
                      as bool,
            isRewarded: null == isRewarded
                ? _value.isRewarded
                : isRewarded // ignore: cast_nullable_to_non_nullable
                      as bool,
            startedAt: freezed == startedAt
                ? _value.startedAt
                : startedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            completedAt: freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            claimedRewardAt: freezed == claimedRewardAt
                ? _value.claimedRewardAt
                : claimedRewardAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PlayerQuestImplCopyWith<$Res>
    implements $PlayerQuestCopyWith<$Res> {
  factory _$$PlayerQuestImplCopyWith(
    _$PlayerQuestImpl value,
    $Res Function(_$PlayerQuestImpl) then,
  ) = __$$PlayerQuestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    String questId,
    List<QuestCondition> conditions,
    bool isCompleted,
    bool isRewarded,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? claimedRewardAt,
  });
}

/// @nodoc
class __$$PlayerQuestImplCopyWithImpl<$Res>
    extends _$PlayerQuestCopyWithImpl<$Res, _$PlayerQuestImpl>
    implements _$$PlayerQuestImplCopyWith<$Res> {
  __$$PlayerQuestImplCopyWithImpl(
    _$PlayerQuestImpl _value,
    $Res Function(_$PlayerQuestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlayerQuest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? questId = null,
    Object? conditions = null,
    Object? isCompleted = null,
    Object? isRewarded = null,
    Object? startedAt = freezed,
    Object? completedAt = freezed,
    Object? claimedRewardAt = freezed,
  }) {
    return _then(
      _$PlayerQuestImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        questId: null == questId
            ? _value.questId
            : questId // ignore: cast_nullable_to_non_nullable
                  as String,
        conditions: null == conditions
            ? _value._conditions
            : conditions // ignore: cast_nullable_to_non_nullable
                  as List<QuestCondition>,
        isCompleted: null == isCompleted
            ? _value.isCompleted
            : isCompleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        isRewarded: null == isRewarded
            ? _value.isRewarded
            : isRewarded // ignore: cast_nullable_to_non_nullable
                  as bool,
        startedAt: freezed == startedAt
            ? _value.startedAt
            : startedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        completedAt: freezed == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        claimedRewardAt: freezed == claimedRewardAt
            ? _value.claimedRewardAt
            : claimedRewardAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlayerQuestImpl extends _PlayerQuest {
  const _$PlayerQuestImpl({
    required this.userId,
    required this.questId,
    required final List<QuestCondition> conditions,
    required this.isCompleted,
    required this.isRewarded,
    this.startedAt,
    this.completedAt,
    this.claimedRewardAt,
  }) : _conditions = conditions,
       super._();

  factory _$PlayerQuestImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerQuestImplFromJson(json);

  @override
  final String userId;
  @override
  final String questId;
  final List<QuestCondition> _conditions;
  @override
  List<QuestCondition> get conditions {
    if (_conditions is EqualUnmodifiableListView) return _conditions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_conditions);
  }

  // Current progress on each condition
  @override
  final bool isCompleted;
  @override
  final bool isRewarded;
  // Has player claimed reward?
  @override
  final DateTime? startedAt;
  @override
  final DateTime? completedAt;
  @override
  final DateTime? claimedRewardAt;

  @override
  String toString() {
    return 'PlayerQuest(userId: $userId, questId: $questId, conditions: $conditions, isCompleted: $isCompleted, isRewarded: $isRewarded, startedAt: $startedAt, completedAt: $completedAt, claimedRewardAt: $claimedRewardAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerQuestImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.questId, questId) || other.questId == questId) &&
            const DeepCollectionEquality().equals(
              other._conditions,
              _conditions,
            ) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.isRewarded, isRewarded) ||
                other.isRewarded == isRewarded) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.claimedRewardAt, claimedRewardAt) ||
                other.claimedRewardAt == claimedRewardAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    userId,
    questId,
    const DeepCollectionEquality().hash(_conditions),
    isCompleted,
    isRewarded,
    startedAt,
    completedAt,
    claimedRewardAt,
  );

  /// Create a copy of PlayerQuest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerQuestImplCopyWith<_$PlayerQuestImpl> get copyWith =>
      __$$PlayerQuestImplCopyWithImpl<_$PlayerQuestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayerQuestImplToJson(this);
  }
}

abstract class _PlayerQuest extends PlayerQuest {
  const factory _PlayerQuest({
    required final String userId,
    required final String questId,
    required final List<QuestCondition> conditions,
    required final bool isCompleted,
    required final bool isRewarded,
    final DateTime? startedAt,
    final DateTime? completedAt,
    final DateTime? claimedRewardAt,
  }) = _$PlayerQuestImpl;
  const _PlayerQuest._() : super._();

  factory _PlayerQuest.fromJson(Map<String, dynamic> json) =
      _$PlayerQuestImpl.fromJson;

  @override
  String get userId;
  @override
  String get questId;
  @override
  List<QuestCondition> get conditions; // Current progress on each condition
  @override
  bool get isCompleted;
  @override
  bool get isRewarded; // Has player claimed reward?
  @override
  DateTime? get startedAt;
  @override
  DateTime? get completedAt;
  @override
  DateTime? get claimedRewardAt;

  /// Create a copy of PlayerQuest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerQuestImplCopyWith<_$PlayerQuestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
