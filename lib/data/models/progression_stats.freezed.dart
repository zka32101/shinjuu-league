// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'progression_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SeasonStats _$SeasonStatsFromJson(Map<String, dynamic> json) {
  return _SeasonStats.fromJson(json);
}

/// @nodoc
mixin _$SeasonStats {
  String get seasonId => throw _privateConstructorUsedError;
  DateTime get startedAt => throw _privateConstructorUsedError;
  DateTime? get endedAt => throw _privateConstructorUsedError;
  String get finalTier =>
      throw _privateConstructorUsedError; // Bronze/Silver/Gold/Platinum/Diamond
  String get maxTierReached =>
      throw _privateConstructorUsedError; // Highest tier during season
  int get pointsAllocated =>
      throw _privateConstructorUsedError; // Skill tree points used
  int get totalGamesPlayed => throw _privateConstructorUsedError;
  int get gamesWon => throw _privateConstructorUsedError;
  int get gamesLost => throw _privateConstructorUsedError;
  Duration get totalPlayTime =>
      throw _privateConstructorUsedError; // Hours played this season
  double get winRate => throw _privateConstructorUsedError; // 0.0 - 1.0
  List<EloSnapshot> get eloProgression =>
      throw _privateConstructorUsedError; // ELO curve over time
  int get seasonRewards => throw _privateConstructorUsedError;

  /// Serializes this SeasonStats to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SeasonStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SeasonStatsCopyWith<SeasonStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SeasonStatsCopyWith<$Res> {
  factory $SeasonStatsCopyWith(
    SeasonStats value,
    $Res Function(SeasonStats) then,
  ) = _$SeasonStatsCopyWithImpl<$Res, SeasonStats>;
  @useResult
  $Res call({
    String seasonId,
    DateTime startedAt,
    DateTime? endedAt,
    String finalTier,
    String maxTierReached,
    int pointsAllocated,
    int totalGamesPlayed,
    int gamesWon,
    int gamesLost,
    Duration totalPlayTime,
    double winRate,
    List<EloSnapshot> eloProgression,
    int seasonRewards,
  });
}

/// @nodoc
class _$SeasonStatsCopyWithImpl<$Res, $Val extends SeasonStats>
    implements $SeasonStatsCopyWith<$Res> {
  _$SeasonStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SeasonStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? seasonId = null,
    Object? startedAt = null,
    Object? endedAt = freezed,
    Object? finalTier = null,
    Object? maxTierReached = null,
    Object? pointsAllocated = null,
    Object? totalGamesPlayed = null,
    Object? gamesWon = null,
    Object? gamesLost = null,
    Object? totalPlayTime = null,
    Object? winRate = null,
    Object? eloProgression = null,
    Object? seasonRewards = null,
  }) {
    return _then(
      _value.copyWith(
            seasonId: null == seasonId
                ? _value.seasonId
                : seasonId // ignore: cast_nullable_to_non_nullable
                      as String,
            startedAt: null == startedAt
                ? _value.startedAt
                : startedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            endedAt: freezed == endedAt
                ? _value.endedAt
                : endedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            finalTier: null == finalTier
                ? _value.finalTier
                : finalTier // ignore: cast_nullable_to_non_nullable
                      as String,
            maxTierReached: null == maxTierReached
                ? _value.maxTierReached
                : maxTierReached // ignore: cast_nullable_to_non_nullable
                      as String,
            pointsAllocated: null == pointsAllocated
                ? _value.pointsAllocated
                : pointsAllocated // ignore: cast_nullable_to_non_nullable
                      as int,
            totalGamesPlayed: null == totalGamesPlayed
                ? _value.totalGamesPlayed
                : totalGamesPlayed // ignore: cast_nullable_to_non_nullable
                      as int,
            gamesWon: null == gamesWon
                ? _value.gamesWon
                : gamesWon // ignore: cast_nullable_to_non_nullable
                      as int,
            gamesLost: null == gamesLost
                ? _value.gamesLost
                : gamesLost // ignore: cast_nullable_to_non_nullable
                      as int,
            totalPlayTime: null == totalPlayTime
                ? _value.totalPlayTime
                : totalPlayTime // ignore: cast_nullable_to_non_nullable
                      as Duration,
            winRate: null == winRate
                ? _value.winRate
                : winRate // ignore: cast_nullable_to_non_nullable
                      as double,
            eloProgression: null == eloProgression
                ? _value.eloProgression
                : eloProgression // ignore: cast_nullable_to_non_nullable
                      as List<EloSnapshot>,
            seasonRewards: null == seasonRewards
                ? _value.seasonRewards
                : seasonRewards // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SeasonStatsImplCopyWith<$Res>
    implements $SeasonStatsCopyWith<$Res> {
  factory _$$SeasonStatsImplCopyWith(
    _$SeasonStatsImpl value,
    $Res Function(_$SeasonStatsImpl) then,
  ) = __$$SeasonStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String seasonId,
    DateTime startedAt,
    DateTime? endedAt,
    String finalTier,
    String maxTierReached,
    int pointsAllocated,
    int totalGamesPlayed,
    int gamesWon,
    int gamesLost,
    Duration totalPlayTime,
    double winRate,
    List<EloSnapshot> eloProgression,
    int seasonRewards,
  });
}

/// @nodoc
class __$$SeasonStatsImplCopyWithImpl<$Res>
    extends _$SeasonStatsCopyWithImpl<$Res, _$SeasonStatsImpl>
    implements _$$SeasonStatsImplCopyWith<$Res> {
  __$$SeasonStatsImplCopyWithImpl(
    _$SeasonStatsImpl _value,
    $Res Function(_$SeasonStatsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SeasonStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? seasonId = null,
    Object? startedAt = null,
    Object? endedAt = freezed,
    Object? finalTier = null,
    Object? maxTierReached = null,
    Object? pointsAllocated = null,
    Object? totalGamesPlayed = null,
    Object? gamesWon = null,
    Object? gamesLost = null,
    Object? totalPlayTime = null,
    Object? winRate = null,
    Object? eloProgression = null,
    Object? seasonRewards = null,
  }) {
    return _then(
      _$SeasonStatsImpl(
        seasonId: null == seasonId
            ? _value.seasonId
            : seasonId // ignore: cast_nullable_to_non_nullable
                  as String,
        startedAt: null == startedAt
            ? _value.startedAt
            : startedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        endedAt: freezed == endedAt
            ? _value.endedAt
            : endedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        finalTier: null == finalTier
            ? _value.finalTier
            : finalTier // ignore: cast_nullable_to_non_nullable
                  as String,
        maxTierReached: null == maxTierReached
            ? _value.maxTierReached
            : maxTierReached // ignore: cast_nullable_to_non_nullable
                  as String,
        pointsAllocated: null == pointsAllocated
            ? _value.pointsAllocated
            : pointsAllocated // ignore: cast_nullable_to_non_nullable
                  as int,
        totalGamesPlayed: null == totalGamesPlayed
            ? _value.totalGamesPlayed
            : totalGamesPlayed // ignore: cast_nullable_to_non_nullable
                  as int,
        gamesWon: null == gamesWon
            ? _value.gamesWon
            : gamesWon // ignore: cast_nullable_to_non_nullable
                  as int,
        gamesLost: null == gamesLost
            ? _value.gamesLost
            : gamesLost // ignore: cast_nullable_to_non_nullable
                  as int,
        totalPlayTime: null == totalPlayTime
            ? _value.totalPlayTime
            : totalPlayTime // ignore: cast_nullable_to_non_nullable
                  as Duration,
        winRate: null == winRate
            ? _value.winRate
            : winRate // ignore: cast_nullable_to_non_nullable
                  as double,
        eloProgression: null == eloProgression
            ? _value._eloProgression
            : eloProgression // ignore: cast_nullable_to_non_nullable
                  as List<EloSnapshot>,
        seasonRewards: null == seasonRewards
            ? _value.seasonRewards
            : seasonRewards // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SeasonStatsImpl extends _SeasonStats {
  const _$SeasonStatsImpl({
    required this.seasonId,
    required this.startedAt,
    this.endedAt,
    required this.finalTier,
    required this.maxTierReached,
    required this.pointsAllocated,
    required this.totalGamesPlayed,
    required this.gamesWon,
    required this.gamesLost,
    required this.totalPlayTime,
    required this.winRate,
    required final List<EloSnapshot> eloProgression,
    required this.seasonRewards,
  }) : _eloProgression = eloProgression,
       super._();

  factory _$SeasonStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$SeasonStatsImplFromJson(json);

  @override
  final String seasonId;
  @override
  final DateTime startedAt;
  @override
  final DateTime? endedAt;
  @override
  final String finalTier;
  // Bronze/Silver/Gold/Platinum/Diamond
  @override
  final String maxTierReached;
  // Highest tier during season
  @override
  final int pointsAllocated;
  // Skill tree points used
  @override
  final int totalGamesPlayed;
  @override
  final int gamesWon;
  @override
  final int gamesLost;
  @override
  final Duration totalPlayTime;
  // Hours played this season
  @override
  final double winRate;
  // 0.0 - 1.0
  final List<EloSnapshot> _eloProgression;
  // 0.0 - 1.0
  @override
  List<EloSnapshot> get eloProgression {
    if (_eloProgression is EqualUnmodifiableListView) return _eloProgression;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_eloProgression);
  }

  // ELO curve over time
  @override
  final int seasonRewards;

  @override
  String toString() {
    return 'SeasonStats(seasonId: $seasonId, startedAt: $startedAt, endedAt: $endedAt, finalTier: $finalTier, maxTierReached: $maxTierReached, pointsAllocated: $pointsAllocated, totalGamesPlayed: $totalGamesPlayed, gamesWon: $gamesWon, gamesLost: $gamesLost, totalPlayTime: $totalPlayTime, winRate: $winRate, eloProgression: $eloProgression, seasonRewards: $seasonRewards)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SeasonStatsImpl &&
            (identical(other.seasonId, seasonId) ||
                other.seasonId == seasonId) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.endedAt, endedAt) || other.endedAt == endedAt) &&
            (identical(other.finalTier, finalTier) ||
                other.finalTier == finalTier) &&
            (identical(other.maxTierReached, maxTierReached) ||
                other.maxTierReached == maxTierReached) &&
            (identical(other.pointsAllocated, pointsAllocated) ||
                other.pointsAllocated == pointsAllocated) &&
            (identical(other.totalGamesPlayed, totalGamesPlayed) ||
                other.totalGamesPlayed == totalGamesPlayed) &&
            (identical(other.gamesWon, gamesWon) ||
                other.gamesWon == gamesWon) &&
            (identical(other.gamesLost, gamesLost) ||
                other.gamesLost == gamesLost) &&
            (identical(other.totalPlayTime, totalPlayTime) ||
                other.totalPlayTime == totalPlayTime) &&
            (identical(other.winRate, winRate) || other.winRate == winRate) &&
            const DeepCollectionEquality().equals(
              other._eloProgression,
              _eloProgression,
            ) &&
            (identical(other.seasonRewards, seasonRewards) ||
                other.seasonRewards == seasonRewards));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    seasonId,
    startedAt,
    endedAt,
    finalTier,
    maxTierReached,
    pointsAllocated,
    totalGamesPlayed,
    gamesWon,
    gamesLost,
    totalPlayTime,
    winRate,
    const DeepCollectionEquality().hash(_eloProgression),
    seasonRewards,
  );

  /// Create a copy of SeasonStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SeasonStatsImplCopyWith<_$SeasonStatsImpl> get copyWith =>
      __$$SeasonStatsImplCopyWithImpl<_$SeasonStatsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SeasonStatsImplToJson(this);
  }
}

abstract class _SeasonStats extends SeasonStats {
  const factory _SeasonStats({
    required final String seasonId,
    required final DateTime startedAt,
    final DateTime? endedAt,
    required final String finalTier,
    required final String maxTierReached,
    required final int pointsAllocated,
    required final int totalGamesPlayed,
    required final int gamesWon,
    required final int gamesLost,
    required final Duration totalPlayTime,
    required final double winRate,
    required final List<EloSnapshot> eloProgression,
    required final int seasonRewards,
  }) = _$SeasonStatsImpl;
  const _SeasonStats._() : super._();

  factory _SeasonStats.fromJson(Map<String, dynamic> json) =
      _$SeasonStatsImpl.fromJson;

  @override
  String get seasonId;
  @override
  DateTime get startedAt;
  @override
  DateTime? get endedAt;
  @override
  String get finalTier; // Bronze/Silver/Gold/Platinum/Diamond
  @override
  String get maxTierReached; // Highest tier during season
  @override
  int get pointsAllocated; // Skill tree points used
  @override
  int get totalGamesPlayed;
  @override
  int get gamesWon;
  @override
  int get gamesLost;
  @override
  Duration get totalPlayTime; // Hours played this season
  @override
  double get winRate; // 0.0 - 1.0
  @override
  List<EloSnapshot> get eloProgression; // ELO curve over time
  @override
  int get seasonRewards;

  /// Create a copy of SeasonStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SeasonStatsImplCopyWith<_$SeasonStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EloSnapshot _$EloSnapshotFromJson(Map<String, dynamic> json) {
  return _EloSnapshot.fromJson(json);
}

/// @nodoc
mixin _$EloSnapshot {
  DateTime get recordedAt => throw _privateConstructorUsedError;
  double get rating => throw _privateConstructorUsedError;
  int get gamesPlayed => throw _privateConstructorUsedError;

  /// Serializes this EloSnapshot to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EloSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EloSnapshotCopyWith<EloSnapshot> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EloSnapshotCopyWith<$Res> {
  factory $EloSnapshotCopyWith(
    EloSnapshot value,
    $Res Function(EloSnapshot) then,
  ) = _$EloSnapshotCopyWithImpl<$Res, EloSnapshot>;
  @useResult
  $Res call({DateTime recordedAt, double rating, int gamesPlayed});
}

/// @nodoc
class _$EloSnapshotCopyWithImpl<$Res, $Val extends EloSnapshot>
    implements $EloSnapshotCopyWith<$Res> {
  _$EloSnapshotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EloSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recordedAt = null,
    Object? rating = null,
    Object? gamesPlayed = null,
  }) {
    return _then(
      _value.copyWith(
            recordedAt: null == recordedAt
                ? _value.recordedAt
                : recordedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            rating: null == rating
                ? _value.rating
                : rating // ignore: cast_nullable_to_non_nullable
                      as double,
            gamesPlayed: null == gamesPlayed
                ? _value.gamesPlayed
                : gamesPlayed // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$EloSnapshotImplCopyWith<$Res>
    implements $EloSnapshotCopyWith<$Res> {
  factory _$$EloSnapshotImplCopyWith(
    _$EloSnapshotImpl value,
    $Res Function(_$EloSnapshotImpl) then,
  ) = __$$EloSnapshotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DateTime recordedAt, double rating, int gamesPlayed});
}

/// @nodoc
class __$$EloSnapshotImplCopyWithImpl<$Res>
    extends _$EloSnapshotCopyWithImpl<$Res, _$EloSnapshotImpl>
    implements _$$EloSnapshotImplCopyWith<$Res> {
  __$$EloSnapshotImplCopyWithImpl(
    _$EloSnapshotImpl _value,
    $Res Function(_$EloSnapshotImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EloSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recordedAt = null,
    Object? rating = null,
    Object? gamesPlayed = null,
  }) {
    return _then(
      _$EloSnapshotImpl(
        recordedAt: null == recordedAt
            ? _value.recordedAt
            : recordedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        rating: null == rating
            ? _value.rating
            : rating // ignore: cast_nullable_to_non_nullable
                  as double,
        gamesPlayed: null == gamesPlayed
            ? _value.gamesPlayed
            : gamesPlayed // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$EloSnapshotImpl implements _EloSnapshot {
  const _$EloSnapshotImpl({
    required this.recordedAt,
    required this.rating,
    required this.gamesPlayed,
  });

  factory _$EloSnapshotImpl.fromJson(Map<String, dynamic> json) =>
      _$$EloSnapshotImplFromJson(json);

  @override
  final DateTime recordedAt;
  @override
  final double rating;
  @override
  final int gamesPlayed;

  @override
  String toString() {
    return 'EloSnapshot(recordedAt: $recordedAt, rating: $rating, gamesPlayed: $gamesPlayed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EloSnapshotImpl &&
            (identical(other.recordedAt, recordedAt) ||
                other.recordedAt == recordedAt) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.gamesPlayed, gamesPlayed) ||
                other.gamesPlayed == gamesPlayed));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, recordedAt, rating, gamesPlayed);

  /// Create a copy of EloSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EloSnapshotImplCopyWith<_$EloSnapshotImpl> get copyWith =>
      __$$EloSnapshotImplCopyWithImpl<_$EloSnapshotImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EloSnapshotImplToJson(this);
  }
}

abstract class _EloSnapshot implements EloSnapshot {
  const factory _EloSnapshot({
    required final DateTime recordedAt,
    required final double rating,
    required final int gamesPlayed,
  }) = _$EloSnapshotImpl;

  factory _EloSnapshot.fromJson(Map<String, dynamic> json) =
      _$EloSnapshotImpl.fromJson;

  @override
  DateTime get recordedAt;
  @override
  double get rating;
  @override
  int get gamesPlayed;

  /// Create a copy of EloSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EloSnapshotImplCopyWith<_$EloSnapshotImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AggregateStats _$AggregateStatsFromJson(Map<String, dynamic> json) {
  return _AggregateStats.fromJson(json);
}

/// @nodoc
mixin _$AggregateStats {
  int get totalSeasonsPlayed => throw _privateConstructorUsedError;
  String get favoriteTree =>
      throw _privateConstructorUsedError; // Most invested skill tree
  String get averageTier =>
      throw _privateConstructorUsedError; // Mean tier across seasons
  String get highestTierEver =>
      throw _privateConstructorUsedError; // Career high tier
  int get totalGamesPlayed => throw _privateConstructorUsedError;
  int get totalGamesWon => throw _privateConstructorUsedError;
  double get careerWinRate => throw _privateConstructorUsedError;
  Map<String, int> get totalRewardsClaimed =>
      throw _privateConstructorUsedError; // reward_type → count
  ProgressionTrend get progression => throw _privateConstructorUsedError;
  DateTime get firstSeasonAt => throw _privateConstructorUsedError;
  DateTime get lastUpdatedAt => throw _privateConstructorUsedError;

  /// Serializes this AggregateStats to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AggregateStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AggregateStatsCopyWith<AggregateStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AggregateStatsCopyWith<$Res> {
  factory $AggregateStatsCopyWith(
    AggregateStats value,
    $Res Function(AggregateStats) then,
  ) = _$AggregateStatsCopyWithImpl<$Res, AggregateStats>;
  @useResult
  $Res call({
    int totalSeasonsPlayed,
    String favoriteTree,
    String averageTier,
    String highestTierEver,
    int totalGamesPlayed,
    int totalGamesWon,
    double careerWinRate,
    Map<String, int> totalRewardsClaimed,
    ProgressionTrend progression,
    DateTime firstSeasonAt,
    DateTime lastUpdatedAt,
  });

  $ProgressionTrendCopyWith<$Res> get progression;
}

/// @nodoc
class _$AggregateStatsCopyWithImpl<$Res, $Val extends AggregateStats>
    implements $AggregateStatsCopyWith<$Res> {
  _$AggregateStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AggregateStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalSeasonsPlayed = null,
    Object? favoriteTree = null,
    Object? averageTier = null,
    Object? highestTierEver = null,
    Object? totalGamesPlayed = null,
    Object? totalGamesWon = null,
    Object? careerWinRate = null,
    Object? totalRewardsClaimed = null,
    Object? progression = null,
    Object? firstSeasonAt = null,
    Object? lastUpdatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            totalSeasonsPlayed: null == totalSeasonsPlayed
                ? _value.totalSeasonsPlayed
                : totalSeasonsPlayed // ignore: cast_nullable_to_non_nullable
                      as int,
            favoriteTree: null == favoriteTree
                ? _value.favoriteTree
                : favoriteTree // ignore: cast_nullable_to_non_nullable
                      as String,
            averageTier: null == averageTier
                ? _value.averageTier
                : averageTier // ignore: cast_nullable_to_non_nullable
                      as String,
            highestTierEver: null == highestTierEver
                ? _value.highestTierEver
                : highestTierEver // ignore: cast_nullable_to_non_nullable
                      as String,
            totalGamesPlayed: null == totalGamesPlayed
                ? _value.totalGamesPlayed
                : totalGamesPlayed // ignore: cast_nullable_to_non_nullable
                      as int,
            totalGamesWon: null == totalGamesWon
                ? _value.totalGamesWon
                : totalGamesWon // ignore: cast_nullable_to_non_nullable
                      as int,
            careerWinRate: null == careerWinRate
                ? _value.careerWinRate
                : careerWinRate // ignore: cast_nullable_to_non_nullable
                      as double,
            totalRewardsClaimed: null == totalRewardsClaimed
                ? _value.totalRewardsClaimed
                : totalRewardsClaimed // ignore: cast_nullable_to_non_nullable
                      as Map<String, int>,
            progression: null == progression
                ? _value.progression
                : progression // ignore: cast_nullable_to_non_nullable
                      as ProgressionTrend,
            firstSeasonAt: null == firstSeasonAt
                ? _value.firstSeasonAt
                : firstSeasonAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            lastUpdatedAt: null == lastUpdatedAt
                ? _value.lastUpdatedAt
                : lastUpdatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }

  /// Create a copy of AggregateStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProgressionTrendCopyWith<$Res> get progression {
    return $ProgressionTrendCopyWith<$Res>(_value.progression, (value) {
      return _then(_value.copyWith(progression: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AggregateStatsImplCopyWith<$Res>
    implements $AggregateStatsCopyWith<$Res> {
  factory _$$AggregateStatsImplCopyWith(
    _$AggregateStatsImpl value,
    $Res Function(_$AggregateStatsImpl) then,
  ) = __$$AggregateStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int totalSeasonsPlayed,
    String favoriteTree,
    String averageTier,
    String highestTierEver,
    int totalGamesPlayed,
    int totalGamesWon,
    double careerWinRate,
    Map<String, int> totalRewardsClaimed,
    ProgressionTrend progression,
    DateTime firstSeasonAt,
    DateTime lastUpdatedAt,
  });

  @override
  $ProgressionTrendCopyWith<$Res> get progression;
}

/// @nodoc
class __$$AggregateStatsImplCopyWithImpl<$Res>
    extends _$AggregateStatsCopyWithImpl<$Res, _$AggregateStatsImpl>
    implements _$$AggregateStatsImplCopyWith<$Res> {
  __$$AggregateStatsImplCopyWithImpl(
    _$AggregateStatsImpl _value,
    $Res Function(_$AggregateStatsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AggregateStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalSeasonsPlayed = null,
    Object? favoriteTree = null,
    Object? averageTier = null,
    Object? highestTierEver = null,
    Object? totalGamesPlayed = null,
    Object? totalGamesWon = null,
    Object? careerWinRate = null,
    Object? totalRewardsClaimed = null,
    Object? progression = null,
    Object? firstSeasonAt = null,
    Object? lastUpdatedAt = null,
  }) {
    return _then(
      _$AggregateStatsImpl(
        totalSeasonsPlayed: null == totalSeasonsPlayed
            ? _value.totalSeasonsPlayed
            : totalSeasonsPlayed // ignore: cast_nullable_to_non_nullable
                  as int,
        favoriteTree: null == favoriteTree
            ? _value.favoriteTree
            : favoriteTree // ignore: cast_nullable_to_non_nullable
                  as String,
        averageTier: null == averageTier
            ? _value.averageTier
            : averageTier // ignore: cast_nullable_to_non_nullable
                  as String,
        highestTierEver: null == highestTierEver
            ? _value.highestTierEver
            : highestTierEver // ignore: cast_nullable_to_non_nullable
                  as String,
        totalGamesPlayed: null == totalGamesPlayed
            ? _value.totalGamesPlayed
            : totalGamesPlayed // ignore: cast_nullable_to_non_nullable
                  as int,
        totalGamesWon: null == totalGamesWon
            ? _value.totalGamesWon
            : totalGamesWon // ignore: cast_nullable_to_non_nullable
                  as int,
        careerWinRate: null == careerWinRate
            ? _value.careerWinRate
            : careerWinRate // ignore: cast_nullable_to_non_nullable
                  as double,
        totalRewardsClaimed: null == totalRewardsClaimed
            ? _value._totalRewardsClaimed
            : totalRewardsClaimed // ignore: cast_nullable_to_non_nullable
                  as Map<String, int>,
        progression: null == progression
            ? _value.progression
            : progression // ignore: cast_nullable_to_non_nullable
                  as ProgressionTrend,
        firstSeasonAt: null == firstSeasonAt
            ? _value.firstSeasonAt
            : firstSeasonAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        lastUpdatedAt: null == lastUpdatedAt
            ? _value.lastUpdatedAt
            : lastUpdatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AggregateStatsImpl extends _AggregateStats {
  const _$AggregateStatsImpl({
    required this.totalSeasonsPlayed,
    required this.favoriteTree,
    required this.averageTier,
    required this.highestTierEver,
    required this.totalGamesPlayed,
    required this.totalGamesWon,
    required this.careerWinRate,
    required final Map<String, int> totalRewardsClaimed,
    required this.progression,
    required this.firstSeasonAt,
    required this.lastUpdatedAt,
  }) : _totalRewardsClaimed = totalRewardsClaimed,
       super._();

  factory _$AggregateStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$AggregateStatsImplFromJson(json);

  @override
  final int totalSeasonsPlayed;
  @override
  final String favoriteTree;
  // Most invested skill tree
  @override
  final String averageTier;
  // Mean tier across seasons
  @override
  final String highestTierEver;
  // Career high tier
  @override
  final int totalGamesPlayed;
  @override
  final int totalGamesWon;
  @override
  final double careerWinRate;
  final Map<String, int> _totalRewardsClaimed;
  @override
  Map<String, int> get totalRewardsClaimed {
    if (_totalRewardsClaimed is EqualUnmodifiableMapView)
      return _totalRewardsClaimed;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_totalRewardsClaimed);
  }

  // reward_type → count
  @override
  final ProgressionTrend progression;
  @override
  final DateTime firstSeasonAt;
  @override
  final DateTime lastUpdatedAt;

  @override
  String toString() {
    return 'AggregateStats(totalSeasonsPlayed: $totalSeasonsPlayed, favoriteTree: $favoriteTree, averageTier: $averageTier, highestTierEver: $highestTierEver, totalGamesPlayed: $totalGamesPlayed, totalGamesWon: $totalGamesWon, careerWinRate: $careerWinRate, totalRewardsClaimed: $totalRewardsClaimed, progression: $progression, firstSeasonAt: $firstSeasonAt, lastUpdatedAt: $lastUpdatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AggregateStatsImpl &&
            (identical(other.totalSeasonsPlayed, totalSeasonsPlayed) ||
                other.totalSeasonsPlayed == totalSeasonsPlayed) &&
            (identical(other.favoriteTree, favoriteTree) ||
                other.favoriteTree == favoriteTree) &&
            (identical(other.averageTier, averageTier) ||
                other.averageTier == averageTier) &&
            (identical(other.highestTierEver, highestTierEver) ||
                other.highestTierEver == highestTierEver) &&
            (identical(other.totalGamesPlayed, totalGamesPlayed) ||
                other.totalGamesPlayed == totalGamesPlayed) &&
            (identical(other.totalGamesWon, totalGamesWon) ||
                other.totalGamesWon == totalGamesWon) &&
            (identical(other.careerWinRate, careerWinRate) ||
                other.careerWinRate == careerWinRate) &&
            const DeepCollectionEquality().equals(
              other._totalRewardsClaimed,
              _totalRewardsClaimed,
            ) &&
            (identical(other.progression, progression) ||
                other.progression == progression) &&
            (identical(other.firstSeasonAt, firstSeasonAt) ||
                other.firstSeasonAt == firstSeasonAt) &&
            (identical(other.lastUpdatedAt, lastUpdatedAt) ||
                other.lastUpdatedAt == lastUpdatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    totalSeasonsPlayed,
    favoriteTree,
    averageTier,
    highestTierEver,
    totalGamesPlayed,
    totalGamesWon,
    careerWinRate,
    const DeepCollectionEquality().hash(_totalRewardsClaimed),
    progression,
    firstSeasonAt,
    lastUpdatedAt,
  );

  /// Create a copy of AggregateStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AggregateStatsImplCopyWith<_$AggregateStatsImpl> get copyWith =>
      __$$AggregateStatsImplCopyWithImpl<_$AggregateStatsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AggregateStatsImplToJson(this);
  }
}

abstract class _AggregateStats extends AggregateStats {
  const factory _AggregateStats({
    required final int totalSeasonsPlayed,
    required final String favoriteTree,
    required final String averageTier,
    required final String highestTierEver,
    required final int totalGamesPlayed,
    required final int totalGamesWon,
    required final double careerWinRate,
    required final Map<String, int> totalRewardsClaimed,
    required final ProgressionTrend progression,
    required final DateTime firstSeasonAt,
    required final DateTime lastUpdatedAt,
  }) = _$AggregateStatsImpl;
  const _AggregateStats._() : super._();

  factory _AggregateStats.fromJson(Map<String, dynamic> json) =
      _$AggregateStatsImpl.fromJson;

  @override
  int get totalSeasonsPlayed;
  @override
  String get favoriteTree; // Most invested skill tree
  @override
  String get averageTier; // Mean tier across seasons
  @override
  String get highestTierEver; // Career high tier
  @override
  int get totalGamesPlayed;
  @override
  int get totalGamesWon;
  @override
  double get careerWinRate;
  @override
  Map<String, int> get totalRewardsClaimed; // reward_type → count
  @override
  ProgressionTrend get progression;
  @override
  DateTime get firstSeasonAt;
  @override
  DateTime get lastUpdatedAt;

  /// Create a copy of AggregateStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AggregateStatsImplCopyWith<_$AggregateStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProgressionTrend _$ProgressionTrendFromJson(Map<String, dynamic> json) {
  return _ProgressionTrend.fromJson(json);
}

/// @nodoc
mixin _$ProgressionTrend {
  double get seasonOverSeason =>
      throw _privateConstructorUsedError; // % change in tier rating
  double get winRateTrend =>
      throw _privateConstructorUsedError; // Win rate delta
  double get eloTrend =>
      throw _privateConstructorUsedError; // Average ELO delta
  ProgressionTrendType get prediction =>
      throw _privateConstructorUsedError; // Trend direction
  int get dataPointsUsed => throw _privateConstructorUsedError;

  /// Serializes this ProgressionTrend to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProgressionTrend
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProgressionTrendCopyWith<ProgressionTrend> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProgressionTrendCopyWith<$Res> {
  factory $ProgressionTrendCopyWith(
    ProgressionTrend value,
    $Res Function(ProgressionTrend) then,
  ) = _$ProgressionTrendCopyWithImpl<$Res, ProgressionTrend>;
  @useResult
  $Res call({
    double seasonOverSeason,
    double winRateTrend,
    double eloTrend,
    ProgressionTrendType prediction,
    int dataPointsUsed,
  });
}

/// @nodoc
class _$ProgressionTrendCopyWithImpl<$Res, $Val extends ProgressionTrend>
    implements $ProgressionTrendCopyWith<$Res> {
  _$ProgressionTrendCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProgressionTrend
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? seasonOverSeason = null,
    Object? winRateTrend = null,
    Object? eloTrend = null,
    Object? prediction = null,
    Object? dataPointsUsed = null,
  }) {
    return _then(
      _value.copyWith(
            seasonOverSeason: null == seasonOverSeason
                ? _value.seasonOverSeason
                : seasonOverSeason // ignore: cast_nullable_to_non_nullable
                      as double,
            winRateTrend: null == winRateTrend
                ? _value.winRateTrend
                : winRateTrend // ignore: cast_nullable_to_non_nullable
                      as double,
            eloTrend: null == eloTrend
                ? _value.eloTrend
                : eloTrend // ignore: cast_nullable_to_non_nullable
                      as double,
            prediction: null == prediction
                ? _value.prediction
                : prediction // ignore: cast_nullable_to_non_nullable
                      as ProgressionTrendType,
            dataPointsUsed: null == dataPointsUsed
                ? _value.dataPointsUsed
                : dataPointsUsed // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProgressionTrendImplCopyWith<$Res>
    implements $ProgressionTrendCopyWith<$Res> {
  factory _$$ProgressionTrendImplCopyWith(
    _$ProgressionTrendImpl value,
    $Res Function(_$ProgressionTrendImpl) then,
  ) = __$$ProgressionTrendImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    double seasonOverSeason,
    double winRateTrend,
    double eloTrend,
    ProgressionTrendType prediction,
    int dataPointsUsed,
  });
}

/// @nodoc
class __$$ProgressionTrendImplCopyWithImpl<$Res>
    extends _$ProgressionTrendCopyWithImpl<$Res, _$ProgressionTrendImpl>
    implements _$$ProgressionTrendImplCopyWith<$Res> {
  __$$ProgressionTrendImplCopyWithImpl(
    _$ProgressionTrendImpl _value,
    $Res Function(_$ProgressionTrendImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ProgressionTrend
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? seasonOverSeason = null,
    Object? winRateTrend = null,
    Object? eloTrend = null,
    Object? prediction = null,
    Object? dataPointsUsed = null,
  }) {
    return _then(
      _$ProgressionTrendImpl(
        seasonOverSeason: null == seasonOverSeason
            ? _value.seasonOverSeason
            : seasonOverSeason // ignore: cast_nullable_to_non_nullable
                  as double,
        winRateTrend: null == winRateTrend
            ? _value.winRateTrend
            : winRateTrend // ignore: cast_nullable_to_non_nullable
                  as double,
        eloTrend: null == eloTrend
            ? _value.eloTrend
            : eloTrend // ignore: cast_nullable_to_non_nullable
                  as double,
        prediction: null == prediction
            ? _value.prediction
            : prediction // ignore: cast_nullable_to_non_nullable
                  as ProgressionTrendType,
        dataPointsUsed: null == dataPointsUsed
            ? _value.dataPointsUsed
            : dataPointsUsed // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ProgressionTrendImpl extends _ProgressionTrend {
  const _$ProgressionTrendImpl({
    required this.seasonOverSeason,
    required this.winRateTrend,
    required this.eloTrend,
    required this.prediction,
    required this.dataPointsUsed,
  }) : super._();

  factory _$ProgressionTrendImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProgressionTrendImplFromJson(json);

  @override
  final double seasonOverSeason;
  // % change in tier rating
  @override
  final double winRateTrend;
  // Win rate delta
  @override
  final double eloTrend;
  // Average ELO delta
  @override
  final ProgressionTrendType prediction;
  // Trend direction
  @override
  final int dataPointsUsed;

  @override
  String toString() {
    return 'ProgressionTrend(seasonOverSeason: $seasonOverSeason, winRateTrend: $winRateTrend, eloTrend: $eloTrend, prediction: $prediction, dataPointsUsed: $dataPointsUsed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProgressionTrendImpl &&
            (identical(other.seasonOverSeason, seasonOverSeason) ||
                other.seasonOverSeason == seasonOverSeason) &&
            (identical(other.winRateTrend, winRateTrend) ||
                other.winRateTrend == winRateTrend) &&
            (identical(other.eloTrend, eloTrend) ||
                other.eloTrend == eloTrend) &&
            (identical(other.prediction, prediction) ||
                other.prediction == prediction) &&
            (identical(other.dataPointsUsed, dataPointsUsed) ||
                other.dataPointsUsed == dataPointsUsed));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    seasonOverSeason,
    winRateTrend,
    eloTrend,
    prediction,
    dataPointsUsed,
  );

  /// Create a copy of ProgressionTrend
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProgressionTrendImplCopyWith<_$ProgressionTrendImpl> get copyWith =>
      __$$ProgressionTrendImplCopyWithImpl<_$ProgressionTrendImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ProgressionTrendImplToJson(this);
  }
}

abstract class _ProgressionTrend extends ProgressionTrend {
  const factory _ProgressionTrend({
    required final double seasonOverSeason,
    required final double winRateTrend,
    required final double eloTrend,
    required final ProgressionTrendType prediction,
    required final int dataPointsUsed,
  }) = _$ProgressionTrendImpl;
  const _ProgressionTrend._() : super._();

  factory _ProgressionTrend.fromJson(Map<String, dynamic> json) =
      _$ProgressionTrendImpl.fromJson;

  @override
  double get seasonOverSeason; // % change in tier rating
  @override
  double get winRateTrend; // Win rate delta
  @override
  double get eloTrend; // Average ELO delta
  @override
  ProgressionTrendType get prediction; // Trend direction
  @override
  int get dataPointsUsed;

  /// Create a copy of ProgressionTrend
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProgressionTrendImplCopyWith<_$ProgressionTrendImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProgressionStats _$ProgressionStatsFromJson(Map<String, dynamic> json) {
  return _ProgressionStats.fromJson(json);
}

/// @nodoc
mixin _$ProgressionStats {
  String get userId => throw _privateConstructorUsedError;
  SeasonStats? get currentSeason => throw _privateConstructorUsedError;
  List<SeasonStats> get allSeasons =>
      throw _privateConstructorUsedError; // Historical data
  AggregateStats get allTimeStats => throw _privateConstructorUsedError;

  /// Serializes this ProgressionStats to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProgressionStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProgressionStatsCopyWith<ProgressionStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProgressionStatsCopyWith<$Res> {
  factory $ProgressionStatsCopyWith(
    ProgressionStats value,
    $Res Function(ProgressionStats) then,
  ) = _$ProgressionStatsCopyWithImpl<$Res, ProgressionStats>;
  @useResult
  $Res call({
    String userId,
    SeasonStats? currentSeason,
    List<SeasonStats> allSeasons,
    AggregateStats allTimeStats,
  });

  $SeasonStatsCopyWith<$Res>? get currentSeason;
  $AggregateStatsCopyWith<$Res> get allTimeStats;
}

/// @nodoc
class _$ProgressionStatsCopyWithImpl<$Res, $Val extends ProgressionStats>
    implements $ProgressionStatsCopyWith<$Res> {
  _$ProgressionStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProgressionStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? currentSeason = freezed,
    Object? allSeasons = null,
    Object? allTimeStats = null,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            currentSeason: freezed == currentSeason
                ? _value.currentSeason
                : currentSeason // ignore: cast_nullable_to_non_nullable
                      as SeasonStats?,
            allSeasons: null == allSeasons
                ? _value.allSeasons
                : allSeasons // ignore: cast_nullable_to_non_nullable
                      as List<SeasonStats>,
            allTimeStats: null == allTimeStats
                ? _value.allTimeStats
                : allTimeStats // ignore: cast_nullable_to_non_nullable
                      as AggregateStats,
          )
          as $Val,
    );
  }

  /// Create a copy of ProgressionStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SeasonStatsCopyWith<$Res>? get currentSeason {
    if (_value.currentSeason == null) {
      return null;
    }

    return $SeasonStatsCopyWith<$Res>(_value.currentSeason!, (value) {
      return _then(_value.copyWith(currentSeason: value) as $Val);
    });
  }

  /// Create a copy of ProgressionStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AggregateStatsCopyWith<$Res> get allTimeStats {
    return $AggregateStatsCopyWith<$Res>(_value.allTimeStats, (value) {
      return _then(_value.copyWith(allTimeStats: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ProgressionStatsImplCopyWith<$Res>
    implements $ProgressionStatsCopyWith<$Res> {
  factory _$$ProgressionStatsImplCopyWith(
    _$ProgressionStatsImpl value,
    $Res Function(_$ProgressionStatsImpl) then,
  ) = __$$ProgressionStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    SeasonStats? currentSeason,
    List<SeasonStats> allSeasons,
    AggregateStats allTimeStats,
  });

  @override
  $SeasonStatsCopyWith<$Res>? get currentSeason;
  @override
  $AggregateStatsCopyWith<$Res> get allTimeStats;
}

/// @nodoc
class __$$ProgressionStatsImplCopyWithImpl<$Res>
    extends _$ProgressionStatsCopyWithImpl<$Res, _$ProgressionStatsImpl>
    implements _$$ProgressionStatsImplCopyWith<$Res> {
  __$$ProgressionStatsImplCopyWithImpl(
    _$ProgressionStatsImpl _value,
    $Res Function(_$ProgressionStatsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ProgressionStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? currentSeason = freezed,
    Object? allSeasons = null,
    Object? allTimeStats = null,
  }) {
    return _then(
      _$ProgressionStatsImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        currentSeason: freezed == currentSeason
            ? _value.currentSeason
            : currentSeason // ignore: cast_nullable_to_non_nullable
                  as SeasonStats?,
        allSeasons: null == allSeasons
            ? _value._allSeasons
            : allSeasons // ignore: cast_nullable_to_non_nullable
                  as List<SeasonStats>,
        allTimeStats: null == allTimeStats
            ? _value.allTimeStats
            : allTimeStats // ignore: cast_nullable_to_non_nullable
                  as AggregateStats,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ProgressionStatsImpl extends _ProgressionStats {
  const _$ProgressionStatsImpl({
    required this.userId,
    required this.currentSeason,
    required final List<SeasonStats> allSeasons,
    required this.allTimeStats,
  }) : _allSeasons = allSeasons,
       super._();

  factory _$ProgressionStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProgressionStatsImplFromJson(json);

  @override
  final String userId;
  @override
  final SeasonStats? currentSeason;
  final List<SeasonStats> _allSeasons;
  @override
  List<SeasonStats> get allSeasons {
    if (_allSeasons is EqualUnmodifiableListView) return _allSeasons;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allSeasons);
  }

  // Historical data
  @override
  final AggregateStats allTimeStats;

  @override
  String toString() {
    return 'ProgressionStats(userId: $userId, currentSeason: $currentSeason, allSeasons: $allSeasons, allTimeStats: $allTimeStats)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProgressionStatsImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.currentSeason, currentSeason) ||
                other.currentSeason == currentSeason) &&
            const DeepCollectionEquality().equals(
              other._allSeasons,
              _allSeasons,
            ) &&
            (identical(other.allTimeStats, allTimeStats) ||
                other.allTimeStats == allTimeStats));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    userId,
    currentSeason,
    const DeepCollectionEquality().hash(_allSeasons),
    allTimeStats,
  );

  /// Create a copy of ProgressionStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProgressionStatsImplCopyWith<_$ProgressionStatsImpl> get copyWith =>
      __$$ProgressionStatsImplCopyWithImpl<_$ProgressionStatsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ProgressionStatsImplToJson(this);
  }
}

abstract class _ProgressionStats extends ProgressionStats {
  const factory _ProgressionStats({
    required final String userId,
    required final SeasonStats? currentSeason,
    required final List<SeasonStats> allSeasons,
    required final AggregateStats allTimeStats,
  }) = _$ProgressionStatsImpl;
  const _ProgressionStats._() : super._();

  factory _ProgressionStats.fromJson(Map<String, dynamic> json) =
      _$ProgressionStatsImpl.fromJson;

  @override
  String get userId;
  @override
  SeasonStats? get currentSeason;
  @override
  List<SeasonStats> get allSeasons; // Historical data
  @override
  AggregateStats get allTimeStats;

  /// Create a copy of ProgressionStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProgressionStatsImplCopyWith<_$ProgressionStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
