// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'seasonal_reward.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SeasonalReward _$SeasonalRewardFromJson(Map<String, dynamic> json) {
  return _SeasonalReward.fromJson(json);
}

/// @nodoc
mixin _$SeasonalReward {
  String get rewardId => throw _privateConstructorUsedError;
  String get tier =>
      throw _privateConstructorUsedError; // Bronze/Silver/Gold/Platinum/Diamond
  RewardType get rewardType => throw _privateConstructorUsedError;
  int get quantity =>
      throw _privateConstructorUsedError; // Amount of currency or count of items
  String get displayName => throw _privateConstructorUsedError;
  String get iconUrl => throw _privateConstructorUsedError;

  /// Serializes this SeasonalReward to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SeasonalReward
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SeasonalRewardCopyWith<SeasonalReward> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SeasonalRewardCopyWith<$Res> {
  factory $SeasonalRewardCopyWith(
    SeasonalReward value,
    $Res Function(SeasonalReward) then,
  ) = _$SeasonalRewardCopyWithImpl<$Res, SeasonalReward>;
  @useResult
  $Res call({
    String rewardId,
    String tier,
    RewardType rewardType,
    int quantity,
    String displayName,
    String iconUrl,
  });
}

/// @nodoc
class _$SeasonalRewardCopyWithImpl<$Res, $Val extends SeasonalReward>
    implements $SeasonalRewardCopyWith<$Res> {
  _$SeasonalRewardCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SeasonalReward
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rewardId = null,
    Object? tier = null,
    Object? rewardType = null,
    Object? quantity = null,
    Object? displayName = null,
    Object? iconUrl = null,
  }) {
    return _then(
      _value.copyWith(
            rewardId: null == rewardId
                ? _value.rewardId
                : rewardId // ignore: cast_nullable_to_non_nullable
                      as String,
            tier: null == tier
                ? _value.tier
                : tier // ignore: cast_nullable_to_non_nullable
                      as String,
            rewardType: null == rewardType
                ? _value.rewardType
                : rewardType // ignore: cast_nullable_to_non_nullable
                      as RewardType,
            quantity: null == quantity
                ? _value.quantity
                : quantity // ignore: cast_nullable_to_non_nullable
                      as int,
            displayName: null == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String,
            iconUrl: null == iconUrl
                ? _value.iconUrl
                : iconUrl // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SeasonalRewardImplCopyWith<$Res>
    implements $SeasonalRewardCopyWith<$Res> {
  factory _$$SeasonalRewardImplCopyWith(
    _$SeasonalRewardImpl value,
    $Res Function(_$SeasonalRewardImpl) then,
  ) = __$$SeasonalRewardImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String rewardId,
    String tier,
    RewardType rewardType,
    int quantity,
    String displayName,
    String iconUrl,
  });
}

/// @nodoc
class __$$SeasonalRewardImplCopyWithImpl<$Res>
    extends _$SeasonalRewardCopyWithImpl<$Res, _$SeasonalRewardImpl>
    implements _$$SeasonalRewardImplCopyWith<$Res> {
  __$$SeasonalRewardImplCopyWithImpl(
    _$SeasonalRewardImpl _value,
    $Res Function(_$SeasonalRewardImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SeasonalReward
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rewardId = null,
    Object? tier = null,
    Object? rewardType = null,
    Object? quantity = null,
    Object? displayName = null,
    Object? iconUrl = null,
  }) {
    return _then(
      _$SeasonalRewardImpl(
        rewardId: null == rewardId
            ? _value.rewardId
            : rewardId // ignore: cast_nullable_to_non_nullable
                  as String,
        tier: null == tier
            ? _value.tier
            : tier // ignore: cast_nullable_to_non_nullable
                  as String,
        rewardType: null == rewardType
            ? _value.rewardType
            : rewardType // ignore: cast_nullable_to_non_nullable
                  as RewardType,
        quantity: null == quantity
            ? _value.quantity
            : quantity // ignore: cast_nullable_to_non_nullable
                  as int,
        displayName: null == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        iconUrl: null == iconUrl
            ? _value.iconUrl
            : iconUrl // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SeasonalRewardImpl implements _SeasonalReward {
  const _$SeasonalRewardImpl({
    required this.rewardId,
    required this.tier,
    required this.rewardType,
    required this.quantity,
    required this.displayName,
    required this.iconUrl,
  });

  factory _$SeasonalRewardImpl.fromJson(Map<String, dynamic> json) =>
      _$$SeasonalRewardImplFromJson(json);

  @override
  final String rewardId;
  @override
  final String tier;
  // Bronze/Silver/Gold/Platinum/Diamond
  @override
  final RewardType rewardType;
  @override
  final int quantity;
  // Amount of currency or count of items
  @override
  final String displayName;
  @override
  final String iconUrl;

  @override
  String toString() {
    return 'SeasonalReward(rewardId: $rewardId, tier: $tier, rewardType: $rewardType, quantity: $quantity, displayName: $displayName, iconUrl: $iconUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SeasonalRewardImpl &&
            (identical(other.rewardId, rewardId) ||
                other.rewardId == rewardId) &&
            (identical(other.tier, tier) || other.tier == tier) &&
            (identical(other.rewardType, rewardType) ||
                other.rewardType == rewardType) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    rewardId,
    tier,
    rewardType,
    quantity,
    displayName,
    iconUrl,
  );

  /// Create a copy of SeasonalReward
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SeasonalRewardImplCopyWith<_$SeasonalRewardImpl> get copyWith =>
      __$$SeasonalRewardImplCopyWithImpl<_$SeasonalRewardImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SeasonalRewardImplToJson(this);
  }
}

abstract class _SeasonalReward implements SeasonalReward {
  const factory _SeasonalReward({
    required final String rewardId,
    required final String tier,
    required final RewardType rewardType,
    required final int quantity,
    required final String displayName,
    required final String iconUrl,
  }) = _$SeasonalRewardImpl;

  factory _SeasonalReward.fromJson(Map<String, dynamic> json) =
      _$SeasonalRewardImpl.fromJson;

  @override
  String get rewardId;
  @override
  String get tier; // Bronze/Silver/Gold/Platinum/Diamond
  @override
  RewardType get rewardType;
  @override
  int get quantity; // Amount of currency or count of items
  @override
  String get displayName;
  @override
  String get iconUrl;

  /// Create a copy of SeasonalReward
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SeasonalRewardImplCopyWith<_$SeasonalRewardImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SeasonRewardDistribution _$SeasonRewardDistributionFromJson(
  Map<String, dynamic> json,
) {
  return _SeasonRewardDistribution.fromJson(json);
}

/// @nodoc
mixin _$SeasonRewardDistribution {
  String get seasonId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get finalTier =>
      throw _privateConstructorUsedError; // Tier achieved by season end
  List<SeasonalReward> get rewards => throw _privateConstructorUsedError;
  DateTime get distributedAt => throw _privateConstructorUsedError;
  DateTime? get claimedAt =>
      throw _privateConstructorUsedError; // When player claimed rewards (null = unclaimed)
  DateTime get expiresAt => throw _privateConstructorUsedError;

  /// Serializes this SeasonRewardDistribution to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SeasonRewardDistribution
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SeasonRewardDistributionCopyWith<SeasonRewardDistribution> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SeasonRewardDistributionCopyWith<$Res> {
  factory $SeasonRewardDistributionCopyWith(
    SeasonRewardDistribution value,
    $Res Function(SeasonRewardDistribution) then,
  ) = _$SeasonRewardDistributionCopyWithImpl<$Res, SeasonRewardDistribution>;
  @useResult
  $Res call({
    String seasonId,
    String userId,
    String finalTier,
    List<SeasonalReward> rewards,
    DateTime distributedAt,
    DateTime? claimedAt,
    DateTime expiresAt,
  });
}

/// @nodoc
class _$SeasonRewardDistributionCopyWithImpl<
  $Res,
  $Val extends SeasonRewardDistribution
>
    implements $SeasonRewardDistributionCopyWith<$Res> {
  _$SeasonRewardDistributionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SeasonRewardDistribution
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? seasonId = null,
    Object? userId = null,
    Object? finalTier = null,
    Object? rewards = null,
    Object? distributedAt = null,
    Object? claimedAt = freezed,
    Object? expiresAt = null,
  }) {
    return _then(
      _value.copyWith(
            seasonId: null == seasonId
                ? _value.seasonId
                : seasonId // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            finalTier: null == finalTier
                ? _value.finalTier
                : finalTier // ignore: cast_nullable_to_non_nullable
                      as String,
            rewards: null == rewards
                ? _value.rewards
                : rewards // ignore: cast_nullable_to_non_nullable
                      as List<SeasonalReward>,
            distributedAt: null == distributedAt
                ? _value.distributedAt
                : distributedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            claimedAt: freezed == claimedAt
                ? _value.claimedAt
                : claimedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            expiresAt: null == expiresAt
                ? _value.expiresAt
                : expiresAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SeasonRewardDistributionImplCopyWith<$Res>
    implements $SeasonRewardDistributionCopyWith<$Res> {
  factory _$$SeasonRewardDistributionImplCopyWith(
    _$SeasonRewardDistributionImpl value,
    $Res Function(_$SeasonRewardDistributionImpl) then,
  ) = __$$SeasonRewardDistributionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String seasonId,
    String userId,
    String finalTier,
    List<SeasonalReward> rewards,
    DateTime distributedAt,
    DateTime? claimedAt,
    DateTime expiresAt,
  });
}

/// @nodoc
class __$$SeasonRewardDistributionImplCopyWithImpl<$Res>
    extends
        _$SeasonRewardDistributionCopyWithImpl<
          $Res,
          _$SeasonRewardDistributionImpl
        >
    implements _$$SeasonRewardDistributionImplCopyWith<$Res> {
  __$$SeasonRewardDistributionImplCopyWithImpl(
    _$SeasonRewardDistributionImpl _value,
    $Res Function(_$SeasonRewardDistributionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SeasonRewardDistribution
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? seasonId = null,
    Object? userId = null,
    Object? finalTier = null,
    Object? rewards = null,
    Object? distributedAt = null,
    Object? claimedAt = freezed,
    Object? expiresAt = null,
  }) {
    return _then(
      _$SeasonRewardDistributionImpl(
        seasonId: null == seasonId
            ? _value.seasonId
            : seasonId // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        finalTier: null == finalTier
            ? _value.finalTier
            : finalTier // ignore: cast_nullable_to_non_nullable
                  as String,
        rewards: null == rewards
            ? _value._rewards
            : rewards // ignore: cast_nullable_to_non_nullable
                  as List<SeasonalReward>,
        distributedAt: null == distributedAt
            ? _value.distributedAt
            : distributedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        claimedAt: freezed == claimedAt
            ? _value.claimedAt
            : claimedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        expiresAt: null == expiresAt
            ? _value.expiresAt
            : expiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SeasonRewardDistributionImpl extends _SeasonRewardDistribution {
  const _$SeasonRewardDistributionImpl({
    required this.seasonId,
    required this.userId,
    required this.finalTier,
    required final List<SeasonalReward> rewards,
    required this.distributedAt,
    this.claimedAt,
    required this.expiresAt,
  }) : _rewards = rewards,
       super._();

  factory _$SeasonRewardDistributionImpl.fromJson(Map<String, dynamic> json) =>
      _$$SeasonRewardDistributionImplFromJson(json);

  @override
  final String seasonId;
  @override
  final String userId;
  @override
  final String finalTier;
  // Tier achieved by season end
  final List<SeasonalReward> _rewards;
  // Tier achieved by season end
  @override
  List<SeasonalReward> get rewards {
    if (_rewards is EqualUnmodifiableListView) return _rewards;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rewards);
  }

  @override
  final DateTime distributedAt;
  @override
  final DateTime? claimedAt;
  // When player claimed rewards (null = unclaimed)
  @override
  final DateTime expiresAt;

  @override
  String toString() {
    return 'SeasonRewardDistribution(seasonId: $seasonId, userId: $userId, finalTier: $finalTier, rewards: $rewards, distributedAt: $distributedAt, claimedAt: $claimedAt, expiresAt: $expiresAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SeasonRewardDistributionImpl &&
            (identical(other.seasonId, seasonId) ||
                other.seasonId == seasonId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.finalTier, finalTier) ||
                other.finalTier == finalTier) &&
            const DeepCollectionEquality().equals(other._rewards, _rewards) &&
            (identical(other.distributedAt, distributedAt) ||
                other.distributedAt == distributedAt) &&
            (identical(other.claimedAt, claimedAt) ||
                other.claimedAt == claimedAt) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    seasonId,
    userId,
    finalTier,
    const DeepCollectionEquality().hash(_rewards),
    distributedAt,
    claimedAt,
    expiresAt,
  );

  /// Create a copy of SeasonRewardDistribution
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SeasonRewardDistributionImplCopyWith<_$SeasonRewardDistributionImpl>
  get copyWith =>
      __$$SeasonRewardDistributionImplCopyWithImpl<
        _$SeasonRewardDistributionImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SeasonRewardDistributionImplToJson(this);
  }
}

abstract class _SeasonRewardDistribution extends SeasonRewardDistribution {
  const factory _SeasonRewardDistribution({
    required final String seasonId,
    required final String userId,
    required final String finalTier,
    required final List<SeasonalReward> rewards,
    required final DateTime distributedAt,
    final DateTime? claimedAt,
    required final DateTime expiresAt,
  }) = _$SeasonRewardDistributionImpl;
  const _SeasonRewardDistribution._() : super._();

  factory _SeasonRewardDistribution.fromJson(Map<String, dynamic> json) =
      _$SeasonRewardDistributionImpl.fromJson;

  @override
  String get seasonId;
  @override
  String get userId;
  @override
  String get finalTier; // Tier achieved by season end
  @override
  List<SeasonalReward> get rewards;
  @override
  DateTime get distributedAt;
  @override
  DateTime? get claimedAt; // When player claimed rewards (null = unclaimed)
  @override
  DateTime get expiresAt;

  /// Create a copy of SeasonRewardDistribution
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SeasonRewardDistributionImplCopyWith<_$SeasonRewardDistributionImpl>
  get copyWith => throw _privateConstructorUsedError;
}
