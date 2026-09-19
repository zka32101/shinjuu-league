// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'achievement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Achievement _$AchievementFromJson(Map<String, dynamic> json) {
  return _Achievement.fromJson(json);
}

/// @nodoc
mixin _$Achievement {
  String get achievementId => throw _privateConstructorUsedError;
  AchievementCategory get category => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get iconUrl => throw _privateConstructorUsedError;
  AchievementRewardTier get rewardTier => throw _privateConstructorUsedError;
  int get maxProgress =>
      throw _privateConstructorUsedError; // Max progress for progress-based
  bool get isProgressBased =>
      throw _privateConstructorUsedError; // False = instant unlock, True = cumulative
  bool get isHidden =>
      throw _privateConstructorUsedError; // Hidden until progress > 0
  DateTime? get unlockedAfter => throw _privateConstructorUsedError;

  /// Serializes this Achievement to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Achievement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AchievementCopyWith<Achievement> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AchievementCopyWith<$Res> {
  factory $AchievementCopyWith(
    Achievement value,
    $Res Function(Achievement) then,
  ) = _$AchievementCopyWithImpl<$Res, Achievement>;
  @useResult
  $Res call({
    String achievementId,
    AchievementCategory category,
    String name,
    String description,
    String iconUrl,
    AchievementRewardTier rewardTier,
    int maxProgress,
    bool isProgressBased,
    bool isHidden,
    DateTime? unlockedAfter,
  });
}

/// @nodoc
class _$AchievementCopyWithImpl<$Res, $Val extends Achievement>
    implements $AchievementCopyWith<$Res> {
  _$AchievementCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Achievement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? achievementId = null,
    Object? category = null,
    Object? name = null,
    Object? description = null,
    Object? iconUrl = null,
    Object? rewardTier = null,
    Object? maxProgress = null,
    Object? isProgressBased = null,
    Object? isHidden = null,
    Object? unlockedAfter = freezed,
  }) {
    return _then(
      _value.copyWith(
            achievementId: null == achievementId
                ? _value.achievementId
                : achievementId // ignore: cast_nullable_to_non_nullable
                      as String,
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as AchievementCategory,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            iconUrl: null == iconUrl
                ? _value.iconUrl
                : iconUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            rewardTier: null == rewardTier
                ? _value.rewardTier
                : rewardTier // ignore: cast_nullable_to_non_nullable
                      as AchievementRewardTier,
            maxProgress: null == maxProgress
                ? _value.maxProgress
                : maxProgress // ignore: cast_nullable_to_non_nullable
                      as int,
            isProgressBased: null == isProgressBased
                ? _value.isProgressBased
                : isProgressBased // ignore: cast_nullable_to_non_nullable
                      as bool,
            isHidden: null == isHidden
                ? _value.isHidden
                : isHidden // ignore: cast_nullable_to_non_nullable
                      as bool,
            unlockedAfter: freezed == unlockedAfter
                ? _value.unlockedAfter
                : unlockedAfter // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AchievementImplCopyWith<$Res>
    implements $AchievementCopyWith<$Res> {
  factory _$$AchievementImplCopyWith(
    _$AchievementImpl value,
    $Res Function(_$AchievementImpl) then,
  ) = __$$AchievementImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String achievementId,
    AchievementCategory category,
    String name,
    String description,
    String iconUrl,
    AchievementRewardTier rewardTier,
    int maxProgress,
    bool isProgressBased,
    bool isHidden,
    DateTime? unlockedAfter,
  });
}

/// @nodoc
class __$$AchievementImplCopyWithImpl<$Res>
    extends _$AchievementCopyWithImpl<$Res, _$AchievementImpl>
    implements _$$AchievementImplCopyWith<$Res> {
  __$$AchievementImplCopyWithImpl(
    _$AchievementImpl _value,
    $Res Function(_$AchievementImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Achievement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? achievementId = null,
    Object? category = null,
    Object? name = null,
    Object? description = null,
    Object? iconUrl = null,
    Object? rewardTier = null,
    Object? maxProgress = null,
    Object? isProgressBased = null,
    Object? isHidden = null,
    Object? unlockedAfter = freezed,
  }) {
    return _then(
      _$AchievementImpl(
        achievementId: null == achievementId
            ? _value.achievementId
            : achievementId // ignore: cast_nullable_to_non_nullable
                  as String,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as AchievementCategory,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        iconUrl: null == iconUrl
            ? _value.iconUrl
            : iconUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        rewardTier: null == rewardTier
            ? _value.rewardTier
            : rewardTier // ignore: cast_nullable_to_non_nullable
                  as AchievementRewardTier,
        maxProgress: null == maxProgress
            ? _value.maxProgress
            : maxProgress // ignore: cast_nullable_to_non_nullable
                  as int,
        isProgressBased: null == isProgressBased
            ? _value.isProgressBased
            : isProgressBased // ignore: cast_nullable_to_non_nullable
                  as bool,
        isHidden: null == isHidden
            ? _value.isHidden
            : isHidden // ignore: cast_nullable_to_non_nullable
                  as bool,
        unlockedAfter: freezed == unlockedAfter
            ? _value.unlockedAfter
            : unlockedAfter // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AchievementImpl extends _Achievement {
  const _$AchievementImpl({
    required this.achievementId,
    required this.category,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.rewardTier,
    required this.maxProgress,
    this.isProgressBased = false,
    this.isHidden = false,
    this.unlockedAfter,
  }) : super._();

  factory _$AchievementImpl.fromJson(Map<String, dynamic> json) =>
      _$$AchievementImplFromJson(json);

  @override
  final String achievementId;
  @override
  final AchievementCategory category;
  @override
  final String name;
  @override
  final String description;
  @override
  final String iconUrl;
  @override
  final AchievementRewardTier rewardTier;
  @override
  final int maxProgress;
  // Max progress for progress-based
  @override
  @JsonKey()
  final bool isProgressBased;
  // False = instant unlock, True = cumulative
  @override
  @JsonKey()
  final bool isHidden;
  // Hidden until progress > 0
  @override
  final DateTime? unlockedAfter;

  @override
  String toString() {
    return 'Achievement(achievementId: $achievementId, category: $category, name: $name, description: $description, iconUrl: $iconUrl, rewardTier: $rewardTier, maxProgress: $maxProgress, isProgressBased: $isProgressBased, isHidden: $isHidden, unlockedAfter: $unlockedAfter)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AchievementImpl &&
            (identical(other.achievementId, achievementId) ||
                other.achievementId == achievementId) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl) &&
            (identical(other.rewardTier, rewardTier) ||
                other.rewardTier == rewardTier) &&
            (identical(other.maxProgress, maxProgress) ||
                other.maxProgress == maxProgress) &&
            (identical(other.isProgressBased, isProgressBased) ||
                other.isProgressBased == isProgressBased) &&
            (identical(other.isHidden, isHidden) ||
                other.isHidden == isHidden) &&
            (identical(other.unlockedAfter, unlockedAfter) ||
                other.unlockedAfter == unlockedAfter));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    achievementId,
    category,
    name,
    description,
    iconUrl,
    rewardTier,
    maxProgress,
    isProgressBased,
    isHidden,
    unlockedAfter,
  );

  /// Create a copy of Achievement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AchievementImplCopyWith<_$AchievementImpl> get copyWith =>
      __$$AchievementImplCopyWithImpl<_$AchievementImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AchievementImplToJson(this);
  }
}

abstract class _Achievement extends Achievement {
  const factory _Achievement({
    required final String achievementId,
    required final AchievementCategory category,
    required final String name,
    required final String description,
    required final String iconUrl,
    required final AchievementRewardTier rewardTier,
    required final int maxProgress,
    final bool isProgressBased,
    final bool isHidden,
    final DateTime? unlockedAfter,
  }) = _$AchievementImpl;
  const _Achievement._() : super._();

  factory _Achievement.fromJson(Map<String, dynamic> json) =
      _$AchievementImpl.fromJson;

  @override
  String get achievementId;
  @override
  AchievementCategory get category;
  @override
  String get name;
  @override
  String get description;
  @override
  String get iconUrl;
  @override
  AchievementRewardTier get rewardTier;
  @override
  int get maxProgress; // Max progress for progress-based
  @override
  bool get isProgressBased; // False = instant unlock, True = cumulative
  @override
  bool get isHidden; // Hidden until progress > 0
  @override
  DateTime? get unlockedAfter;

  /// Create a copy of Achievement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AchievementImplCopyWith<_$AchievementImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PlayerAchievement _$PlayerAchievementFromJson(Map<String, dynamic> json) {
  return _PlayerAchievement.fromJson(json);
}

/// @nodoc
mixin _$PlayerAchievement {
  String get userId => throw _privateConstructorUsedError;
  String get achievementId => throw _privateConstructorUsedError;
  DateTime get unlockedAt => throw _privateConstructorUsedError;
  AchievementProgress? get progress =>
      throw _privateConstructorUsedError; // Null = instant unlock, Present = progress-based
  bool get isHidden => throw _privateConstructorUsedError;

  /// Serializes this PlayerAchievement to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlayerAchievement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerAchievementCopyWith<PlayerAchievement> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerAchievementCopyWith<$Res> {
  factory $PlayerAchievementCopyWith(
    PlayerAchievement value,
    $Res Function(PlayerAchievement) then,
  ) = _$PlayerAchievementCopyWithImpl<$Res, PlayerAchievement>;
  @useResult
  $Res call({
    String userId,
    String achievementId,
    DateTime unlockedAt,
    AchievementProgress? progress,
    bool isHidden,
  });

  $AchievementProgressCopyWith<$Res>? get progress;
}

/// @nodoc
class _$PlayerAchievementCopyWithImpl<$Res, $Val extends PlayerAchievement>
    implements $PlayerAchievementCopyWith<$Res> {
  _$PlayerAchievementCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlayerAchievement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? achievementId = null,
    Object? unlockedAt = null,
    Object? progress = freezed,
    Object? isHidden = null,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            achievementId: null == achievementId
                ? _value.achievementId
                : achievementId // ignore: cast_nullable_to_non_nullable
                      as String,
            unlockedAt: null == unlockedAt
                ? _value.unlockedAt
                : unlockedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            progress: freezed == progress
                ? _value.progress
                : progress // ignore: cast_nullable_to_non_nullable
                      as AchievementProgress?,
            isHidden: null == isHidden
                ? _value.isHidden
                : isHidden // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }

  /// Create a copy of PlayerAchievement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AchievementProgressCopyWith<$Res>? get progress {
    if (_value.progress == null) {
      return null;
    }

    return $AchievementProgressCopyWith<$Res>(_value.progress!, (value) {
      return _then(_value.copyWith(progress: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PlayerAchievementImplCopyWith<$Res>
    implements $PlayerAchievementCopyWith<$Res> {
  factory _$$PlayerAchievementImplCopyWith(
    _$PlayerAchievementImpl value,
    $Res Function(_$PlayerAchievementImpl) then,
  ) = __$$PlayerAchievementImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    String achievementId,
    DateTime unlockedAt,
    AchievementProgress? progress,
    bool isHidden,
  });

  @override
  $AchievementProgressCopyWith<$Res>? get progress;
}

/// @nodoc
class __$$PlayerAchievementImplCopyWithImpl<$Res>
    extends _$PlayerAchievementCopyWithImpl<$Res, _$PlayerAchievementImpl>
    implements _$$PlayerAchievementImplCopyWith<$Res> {
  __$$PlayerAchievementImplCopyWithImpl(
    _$PlayerAchievementImpl _value,
    $Res Function(_$PlayerAchievementImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlayerAchievement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? achievementId = null,
    Object? unlockedAt = null,
    Object? progress = freezed,
    Object? isHidden = null,
  }) {
    return _then(
      _$PlayerAchievementImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        achievementId: null == achievementId
            ? _value.achievementId
            : achievementId // ignore: cast_nullable_to_non_nullable
                  as String,
        unlockedAt: null == unlockedAt
            ? _value.unlockedAt
            : unlockedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        progress: freezed == progress
            ? _value.progress
            : progress // ignore: cast_nullable_to_non_nullable
                  as AchievementProgress?,
        isHidden: null == isHidden
            ? _value.isHidden
            : isHidden // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlayerAchievementImpl extends _PlayerAchievement {
  const _$PlayerAchievementImpl({
    required this.userId,
    required this.achievementId,
    required this.unlockedAt,
    this.progress,
    this.isHidden = false,
  }) : super._();

  factory _$PlayerAchievementImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerAchievementImplFromJson(json);

  @override
  final String userId;
  @override
  final String achievementId;
  @override
  final DateTime unlockedAt;
  @override
  final AchievementProgress? progress;
  // Null = instant unlock, Present = progress-based
  @override
  @JsonKey()
  final bool isHidden;

  @override
  String toString() {
    return 'PlayerAchievement(userId: $userId, achievementId: $achievementId, unlockedAt: $unlockedAt, progress: $progress, isHidden: $isHidden)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerAchievementImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.achievementId, achievementId) ||
                other.achievementId == achievementId) &&
            (identical(other.unlockedAt, unlockedAt) ||
                other.unlockedAt == unlockedAt) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.isHidden, isHidden) ||
                other.isHidden == isHidden));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    userId,
    achievementId,
    unlockedAt,
    progress,
    isHidden,
  );

  /// Create a copy of PlayerAchievement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerAchievementImplCopyWith<_$PlayerAchievementImpl> get copyWith =>
      __$$PlayerAchievementImplCopyWithImpl<_$PlayerAchievementImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayerAchievementImplToJson(this);
  }
}

abstract class _PlayerAchievement extends PlayerAchievement {
  const factory _PlayerAchievement({
    required final String userId,
    required final String achievementId,
    required final DateTime unlockedAt,
    final AchievementProgress? progress,
    final bool isHidden,
  }) = _$PlayerAchievementImpl;
  const _PlayerAchievement._() : super._();

  factory _PlayerAchievement.fromJson(Map<String, dynamic> json) =
      _$PlayerAchievementImpl.fromJson;

  @override
  String get userId;
  @override
  String get achievementId;
  @override
  DateTime get unlockedAt;
  @override
  AchievementProgress? get progress; // Null = instant unlock, Present = progress-based
  @override
  bool get isHidden;

  /// Create a copy of PlayerAchievement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerAchievementImplCopyWith<_$PlayerAchievementImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AchievementProgress _$AchievementProgressFromJson(Map<String, dynamic> json) {
  return _AchievementProgress.fromJson(json);
}

/// @nodoc
mixin _$AchievementProgress {
  int get current =>
      throw _privateConstructorUsedError; // Current progress value
  int get target => throw _privateConstructorUsedError;

  /// Serializes this AchievementProgress to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AchievementProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AchievementProgressCopyWith<AchievementProgress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AchievementProgressCopyWith<$Res> {
  factory $AchievementProgressCopyWith(
    AchievementProgress value,
    $Res Function(AchievementProgress) then,
  ) = _$AchievementProgressCopyWithImpl<$Res, AchievementProgress>;
  @useResult
  $Res call({int current, int target});
}

/// @nodoc
class _$AchievementProgressCopyWithImpl<$Res, $Val extends AchievementProgress>
    implements $AchievementProgressCopyWith<$Res> {
  _$AchievementProgressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AchievementProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? current = null, Object? target = null}) {
    return _then(
      _value.copyWith(
            current: null == current
                ? _value.current
                : current // ignore: cast_nullable_to_non_nullable
                      as int,
            target: null == target
                ? _value.target
                : target // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AchievementProgressImplCopyWith<$Res>
    implements $AchievementProgressCopyWith<$Res> {
  factory _$$AchievementProgressImplCopyWith(
    _$AchievementProgressImpl value,
    $Res Function(_$AchievementProgressImpl) then,
  ) = __$$AchievementProgressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int current, int target});
}

/// @nodoc
class __$$AchievementProgressImplCopyWithImpl<$Res>
    extends _$AchievementProgressCopyWithImpl<$Res, _$AchievementProgressImpl>
    implements _$$AchievementProgressImplCopyWith<$Res> {
  __$$AchievementProgressImplCopyWithImpl(
    _$AchievementProgressImpl _value,
    $Res Function(_$AchievementProgressImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AchievementProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? current = null, Object? target = null}) {
    return _then(
      _$AchievementProgressImpl(
        current: null == current
            ? _value.current
            : current // ignore: cast_nullable_to_non_nullable
                  as int,
        target: null == target
            ? _value.target
            : target // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AchievementProgressImpl extends _AchievementProgress {
  const _$AchievementProgressImpl({required this.current, required this.target})
    : super._();

  factory _$AchievementProgressImpl.fromJson(Map<String, dynamic> json) =>
      _$$AchievementProgressImplFromJson(json);

  @override
  final int current;
  // Current progress value
  @override
  final int target;

  @override
  String toString() {
    return 'AchievementProgress(current: $current, target: $target)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AchievementProgressImpl &&
            (identical(other.current, current) || other.current == current) &&
            (identical(other.target, target) || other.target == target));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, current, target);

  /// Create a copy of AchievementProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AchievementProgressImplCopyWith<_$AchievementProgressImpl> get copyWith =>
      __$$AchievementProgressImplCopyWithImpl<_$AchievementProgressImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AchievementProgressImplToJson(this);
  }
}

abstract class _AchievementProgress extends AchievementProgress {
  const factory _AchievementProgress({
    required final int current,
    required final int target,
  }) = _$AchievementProgressImpl;
  const _AchievementProgress._() : super._();

  factory _AchievementProgress.fromJson(Map<String, dynamic> json) =
      _$AchievementProgressImpl.fromJson;

  @override
  int get current; // Current progress value
  @override
  int get target;

  /// Create a copy of AchievementProgress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AchievementProgressImplCopyWith<_$AchievementProgressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AchievementUnlockEvent _$AchievementUnlockEventFromJson(
  Map<String, dynamic> json,
) {
  return _AchievementUnlockEvent.fromJson(json);
}

/// @nodoc
mixin _$AchievementUnlockEvent {
  String get userId => throw _privateConstructorUsedError;
  Achievement get achievement => throw _privateConstructorUsedError;
  DateTime get unlockedAt => throw _privateConstructorUsedError;
  bool get isNewUnlock => throw _privateConstructorUsedError;

  /// Serializes this AchievementUnlockEvent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AchievementUnlockEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AchievementUnlockEventCopyWith<AchievementUnlockEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AchievementUnlockEventCopyWith<$Res> {
  factory $AchievementUnlockEventCopyWith(
    AchievementUnlockEvent value,
    $Res Function(AchievementUnlockEvent) then,
  ) = _$AchievementUnlockEventCopyWithImpl<$Res, AchievementUnlockEvent>;
  @useResult
  $Res call({
    String userId,
    Achievement achievement,
    DateTime unlockedAt,
    bool isNewUnlock,
  });

  $AchievementCopyWith<$Res> get achievement;
}

/// @nodoc
class _$AchievementUnlockEventCopyWithImpl<
  $Res,
  $Val extends AchievementUnlockEvent
>
    implements $AchievementUnlockEventCopyWith<$Res> {
  _$AchievementUnlockEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AchievementUnlockEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? achievement = null,
    Object? unlockedAt = null,
    Object? isNewUnlock = null,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            achievement: null == achievement
                ? _value.achievement
                : achievement // ignore: cast_nullable_to_non_nullable
                      as Achievement,
            unlockedAt: null == unlockedAt
                ? _value.unlockedAt
                : unlockedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            isNewUnlock: null == isNewUnlock
                ? _value.isNewUnlock
                : isNewUnlock // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }

  /// Create a copy of AchievementUnlockEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AchievementCopyWith<$Res> get achievement {
    return $AchievementCopyWith<$Res>(_value.achievement, (value) {
      return _then(_value.copyWith(achievement: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AchievementUnlockEventImplCopyWith<$Res>
    implements $AchievementUnlockEventCopyWith<$Res> {
  factory _$$AchievementUnlockEventImplCopyWith(
    _$AchievementUnlockEventImpl value,
    $Res Function(_$AchievementUnlockEventImpl) then,
  ) = __$$AchievementUnlockEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    Achievement achievement,
    DateTime unlockedAt,
    bool isNewUnlock,
  });

  @override
  $AchievementCopyWith<$Res> get achievement;
}

/// @nodoc
class __$$AchievementUnlockEventImplCopyWithImpl<$Res>
    extends
        _$AchievementUnlockEventCopyWithImpl<$Res, _$AchievementUnlockEventImpl>
    implements _$$AchievementUnlockEventImplCopyWith<$Res> {
  __$$AchievementUnlockEventImplCopyWithImpl(
    _$AchievementUnlockEventImpl _value,
    $Res Function(_$AchievementUnlockEventImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AchievementUnlockEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? achievement = null,
    Object? unlockedAt = null,
    Object? isNewUnlock = null,
  }) {
    return _then(
      _$AchievementUnlockEventImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        achievement: null == achievement
            ? _value.achievement
            : achievement // ignore: cast_nullable_to_non_nullable
                  as Achievement,
        unlockedAt: null == unlockedAt
            ? _value.unlockedAt
            : unlockedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        isNewUnlock: null == isNewUnlock
            ? _value.isNewUnlock
            : isNewUnlock // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AchievementUnlockEventImpl implements _AchievementUnlockEvent {
  const _$AchievementUnlockEventImpl({
    required this.userId,
    required this.achievement,
    required this.unlockedAt,
    this.isNewUnlock = true,
  });

  factory _$AchievementUnlockEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$AchievementUnlockEventImplFromJson(json);

  @override
  final String userId;
  @override
  final Achievement achievement;
  @override
  final DateTime unlockedAt;
  @override
  @JsonKey()
  final bool isNewUnlock;

  @override
  String toString() {
    return 'AchievementUnlockEvent(userId: $userId, achievement: $achievement, unlockedAt: $unlockedAt, isNewUnlock: $isNewUnlock)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AchievementUnlockEventImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.achievement, achievement) ||
                other.achievement == achievement) &&
            (identical(other.unlockedAt, unlockedAt) ||
                other.unlockedAt == unlockedAt) &&
            (identical(other.isNewUnlock, isNewUnlock) ||
                other.isNewUnlock == isNewUnlock));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, userId, achievement, unlockedAt, isNewUnlock);

  /// Create a copy of AchievementUnlockEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AchievementUnlockEventImplCopyWith<_$AchievementUnlockEventImpl>
  get copyWith =>
      __$$AchievementUnlockEventImplCopyWithImpl<_$AchievementUnlockEventImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AchievementUnlockEventImplToJson(this);
  }
}

abstract class _AchievementUnlockEvent implements AchievementUnlockEvent {
  const factory _AchievementUnlockEvent({
    required final String userId,
    required final Achievement achievement,
    required final DateTime unlockedAt,
    final bool isNewUnlock,
  }) = _$AchievementUnlockEventImpl;

  factory _AchievementUnlockEvent.fromJson(Map<String, dynamic> json) =
      _$AchievementUnlockEventImpl.fromJson;

  @override
  String get userId;
  @override
  Achievement get achievement;
  @override
  DateTime get unlockedAt;
  @override
  bool get isNewUnlock;

  /// Create a copy of AchievementUnlockEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AchievementUnlockEventImplCopyWith<_$AchievementUnlockEventImpl>
  get copyWith => throw _privateConstructorUsedError;
}
