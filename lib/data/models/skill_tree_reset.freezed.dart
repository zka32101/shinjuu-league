// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'skill_tree_reset.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SkillTreeSnapshot _$SkillTreeSnapshotFromJson(Map<String, dynamic> json) {
  return _SkillTreeSnapshot.fromJson(json);
}

/// @nodoc
mixin _$SkillTreeSnapshot {
  String get seasonId => throw _privateConstructorUsedError;
  DateTime get snapshotAt => throw _privateConstructorUsedError;
  SkillTree get treeState => throw _privateConstructorUsedError;
  String get finalTier =>
      throw _privateConstructorUsedError; // Bronze/Silver/Gold/Platinum/Diamond
  int get totalPointsAllocated => throw _privateConstructorUsedError;
  Map<String, int> get treePointsBreakdown =>
      throw _privateConstructorUsedError;

  /// Serializes this SkillTreeSnapshot to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SkillTreeSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SkillTreeSnapshotCopyWith<SkillTreeSnapshot> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SkillTreeSnapshotCopyWith<$Res> {
  factory $SkillTreeSnapshotCopyWith(
    SkillTreeSnapshot value,
    $Res Function(SkillTreeSnapshot) then,
  ) = _$SkillTreeSnapshotCopyWithImpl<$Res, SkillTreeSnapshot>;
  @useResult
  $Res call({
    String seasonId,
    DateTime snapshotAt,
    SkillTree treeState,
    String finalTier,
    int totalPointsAllocated,
    Map<String, int> treePointsBreakdown,
  });
}

/// @nodoc
class _$SkillTreeSnapshotCopyWithImpl<$Res, $Val extends SkillTreeSnapshot>
    implements $SkillTreeSnapshotCopyWith<$Res> {
  _$SkillTreeSnapshotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SkillTreeSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? seasonId = null,
    Object? snapshotAt = null,
    Object? treeState = null,
    Object? finalTier = null,
    Object? totalPointsAllocated = null,
    Object? treePointsBreakdown = null,
  }) {
    return _then(
      _value.copyWith(
            seasonId: null == seasonId
                ? _value.seasonId
                : seasonId // ignore: cast_nullable_to_non_nullable
                      as String,
            snapshotAt: null == snapshotAt
                ? _value.snapshotAt
                : snapshotAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            treeState: null == treeState
                ? _value.treeState
                : treeState // ignore: cast_nullable_to_non_nullable
                      as SkillTree,
            finalTier: null == finalTier
                ? _value.finalTier
                : finalTier // ignore: cast_nullable_to_non_nullable
                      as String,
            totalPointsAllocated: null == totalPointsAllocated
                ? _value.totalPointsAllocated
                : totalPointsAllocated // ignore: cast_nullable_to_non_nullable
                      as int,
            treePointsBreakdown: null == treePointsBreakdown
                ? _value.treePointsBreakdown
                : treePointsBreakdown // ignore: cast_nullable_to_non_nullable
                      as Map<String, int>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SkillTreeSnapshotImplCopyWith<$Res>
    implements $SkillTreeSnapshotCopyWith<$Res> {
  factory _$$SkillTreeSnapshotImplCopyWith(
    _$SkillTreeSnapshotImpl value,
    $Res Function(_$SkillTreeSnapshotImpl) then,
  ) = __$$SkillTreeSnapshotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String seasonId,
    DateTime snapshotAt,
    SkillTree treeState,
    String finalTier,
    int totalPointsAllocated,
    Map<String, int> treePointsBreakdown,
  });
}

/// @nodoc
class __$$SkillTreeSnapshotImplCopyWithImpl<$Res>
    extends _$SkillTreeSnapshotCopyWithImpl<$Res, _$SkillTreeSnapshotImpl>
    implements _$$SkillTreeSnapshotImplCopyWith<$Res> {
  __$$SkillTreeSnapshotImplCopyWithImpl(
    _$SkillTreeSnapshotImpl _value,
    $Res Function(_$SkillTreeSnapshotImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SkillTreeSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? seasonId = null,
    Object? snapshotAt = null,
    Object? treeState = null,
    Object? finalTier = null,
    Object? totalPointsAllocated = null,
    Object? treePointsBreakdown = null,
  }) {
    return _then(
      _$SkillTreeSnapshotImpl(
        seasonId: null == seasonId
            ? _value.seasonId
            : seasonId // ignore: cast_nullable_to_non_nullable
                  as String,
        snapshotAt: null == snapshotAt
            ? _value.snapshotAt
            : snapshotAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        treeState: null == treeState
            ? _value.treeState
            : treeState // ignore: cast_nullable_to_non_nullable
                  as SkillTree,
        finalTier: null == finalTier
            ? _value.finalTier
            : finalTier // ignore: cast_nullable_to_non_nullable
                  as String,
        totalPointsAllocated: null == totalPointsAllocated
            ? _value.totalPointsAllocated
            : totalPointsAllocated // ignore: cast_nullable_to_non_nullable
                  as int,
        treePointsBreakdown: null == treePointsBreakdown
            ? _value._treePointsBreakdown
            : treePointsBreakdown // ignore: cast_nullable_to_non_nullable
                  as Map<String, int>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SkillTreeSnapshotImpl implements _SkillTreeSnapshot {
  const _$SkillTreeSnapshotImpl({
    required this.seasonId,
    required this.snapshotAt,
    required this.treeState,
    required this.finalTier,
    required this.totalPointsAllocated,
    required final Map<String, int> treePointsBreakdown,
  }) : _treePointsBreakdown = treePointsBreakdown;

  factory _$SkillTreeSnapshotImpl.fromJson(Map<String, dynamic> json) =>
      _$$SkillTreeSnapshotImplFromJson(json);

  @override
  final String seasonId;
  @override
  final DateTime snapshotAt;
  @override
  final SkillTree treeState;
  @override
  final String finalTier;
  // Bronze/Silver/Gold/Platinum/Diamond
  @override
  final int totalPointsAllocated;
  final Map<String, int> _treePointsBreakdown;
  @override
  Map<String, int> get treePointsBreakdown {
    if (_treePointsBreakdown is EqualUnmodifiableMapView)
      return _treePointsBreakdown;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_treePointsBreakdown);
  }

  @override
  String toString() {
    return 'SkillTreeSnapshot(seasonId: $seasonId, snapshotAt: $snapshotAt, treeState: $treeState, finalTier: $finalTier, totalPointsAllocated: $totalPointsAllocated, treePointsBreakdown: $treePointsBreakdown)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SkillTreeSnapshotImpl &&
            (identical(other.seasonId, seasonId) ||
                other.seasonId == seasonId) &&
            (identical(other.snapshotAt, snapshotAt) ||
                other.snapshotAt == snapshotAt) &&
            (identical(other.treeState, treeState) ||
                other.treeState == treeState) &&
            (identical(other.finalTier, finalTier) ||
                other.finalTier == finalTier) &&
            (identical(other.totalPointsAllocated, totalPointsAllocated) ||
                other.totalPointsAllocated == totalPointsAllocated) &&
            const DeepCollectionEquality().equals(
              other._treePointsBreakdown,
              _treePointsBreakdown,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    seasonId,
    snapshotAt,
    treeState,
    finalTier,
    totalPointsAllocated,
    const DeepCollectionEquality().hash(_treePointsBreakdown),
  );

  /// Create a copy of SkillTreeSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SkillTreeSnapshotImplCopyWith<_$SkillTreeSnapshotImpl> get copyWith =>
      __$$SkillTreeSnapshotImplCopyWithImpl<_$SkillTreeSnapshotImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SkillTreeSnapshotImplToJson(this);
  }
}

abstract class _SkillTreeSnapshot implements SkillTreeSnapshot {
  const factory _SkillTreeSnapshot({
    required final String seasonId,
    required final DateTime snapshotAt,
    required final SkillTree treeState,
    required final String finalTier,
    required final int totalPointsAllocated,
    required final Map<String, int> treePointsBreakdown,
  }) = _$SkillTreeSnapshotImpl;

  factory _SkillTreeSnapshot.fromJson(Map<String, dynamic> json) =
      _$SkillTreeSnapshotImpl.fromJson;

  @override
  String get seasonId;
  @override
  DateTime get snapshotAt;
  @override
  SkillTree get treeState;
  @override
  String get finalTier; // Bronze/Silver/Gold/Platinum/Diamond
  @override
  int get totalPointsAllocated;
  @override
  Map<String, int> get treePointsBreakdown;

  /// Create a copy of SkillTreeSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SkillTreeSnapshotImplCopyWith<_$SkillTreeSnapshotImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SkillTreeReset _$SkillTreeResetFromJson(Map<String, dynamic> json) {
  return _SkillTreeReset.fromJson(json);
}

/// @nodoc
mixin _$SkillTreeReset {
  String get seasonId => throw _privateConstructorUsedError;
  String get nextSeasonId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  SkillTree get previousTree =>
      throw _privateConstructorUsedError; // Backup of last season
  SkillTree get currentTree =>
      throw _privateConstructorUsedError; // Fresh allocation post-reset
  DateTime get resetAt => throw _privateConstructorUsedError;
  CarryoverMode get carryoverMode => throw _privateConstructorUsedError;
  int get pointsCarriedOver => throw _privateConstructorUsedError;

  /// Serializes this SkillTreeReset to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SkillTreeReset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SkillTreeResetCopyWith<SkillTreeReset> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SkillTreeResetCopyWith<$Res> {
  factory $SkillTreeResetCopyWith(
    SkillTreeReset value,
    $Res Function(SkillTreeReset) then,
  ) = _$SkillTreeResetCopyWithImpl<$Res, SkillTreeReset>;
  @useResult
  $Res call({
    String seasonId,
    String nextSeasonId,
    String userId,
    SkillTree previousTree,
    SkillTree currentTree,
    DateTime resetAt,
    CarryoverMode carryoverMode,
    int pointsCarriedOver,
  });
}

/// @nodoc
class _$SkillTreeResetCopyWithImpl<$Res, $Val extends SkillTreeReset>
    implements $SkillTreeResetCopyWith<$Res> {
  _$SkillTreeResetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SkillTreeReset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? seasonId = null,
    Object? nextSeasonId = null,
    Object? userId = null,
    Object? previousTree = null,
    Object? currentTree = null,
    Object? resetAt = null,
    Object? carryoverMode = null,
    Object? pointsCarriedOver = null,
  }) {
    return _then(
      _value.copyWith(
            seasonId: null == seasonId
                ? _value.seasonId
                : seasonId // ignore: cast_nullable_to_non_nullable
                      as String,
            nextSeasonId: null == nextSeasonId
                ? _value.nextSeasonId
                : nextSeasonId // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            previousTree: null == previousTree
                ? _value.previousTree
                : previousTree // ignore: cast_nullable_to_non_nullable
                      as SkillTree,
            currentTree: null == currentTree
                ? _value.currentTree
                : currentTree // ignore: cast_nullable_to_non_nullable
                      as SkillTree,
            resetAt: null == resetAt
                ? _value.resetAt
                : resetAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            carryoverMode: null == carryoverMode
                ? _value.carryoverMode
                : carryoverMode // ignore: cast_nullable_to_non_nullable
                      as CarryoverMode,
            pointsCarriedOver: null == pointsCarriedOver
                ? _value.pointsCarriedOver
                : pointsCarriedOver // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SkillTreeResetImplCopyWith<$Res>
    implements $SkillTreeResetCopyWith<$Res> {
  factory _$$SkillTreeResetImplCopyWith(
    _$SkillTreeResetImpl value,
    $Res Function(_$SkillTreeResetImpl) then,
  ) = __$$SkillTreeResetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String seasonId,
    String nextSeasonId,
    String userId,
    SkillTree previousTree,
    SkillTree currentTree,
    DateTime resetAt,
    CarryoverMode carryoverMode,
    int pointsCarriedOver,
  });
}

/// @nodoc
class __$$SkillTreeResetImplCopyWithImpl<$Res>
    extends _$SkillTreeResetCopyWithImpl<$Res, _$SkillTreeResetImpl>
    implements _$$SkillTreeResetImplCopyWith<$Res> {
  __$$SkillTreeResetImplCopyWithImpl(
    _$SkillTreeResetImpl _value,
    $Res Function(_$SkillTreeResetImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SkillTreeReset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? seasonId = null,
    Object? nextSeasonId = null,
    Object? userId = null,
    Object? previousTree = null,
    Object? currentTree = null,
    Object? resetAt = null,
    Object? carryoverMode = null,
    Object? pointsCarriedOver = null,
  }) {
    return _then(
      _$SkillTreeResetImpl(
        seasonId: null == seasonId
            ? _value.seasonId
            : seasonId // ignore: cast_nullable_to_non_nullable
                  as String,
        nextSeasonId: null == nextSeasonId
            ? _value.nextSeasonId
            : nextSeasonId // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        previousTree: null == previousTree
            ? _value.previousTree
            : previousTree // ignore: cast_nullable_to_non_nullable
                  as SkillTree,
        currentTree: null == currentTree
            ? _value.currentTree
            : currentTree // ignore: cast_nullable_to_non_nullable
                  as SkillTree,
        resetAt: null == resetAt
            ? _value.resetAt
            : resetAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        carryoverMode: null == carryoverMode
            ? _value.carryoverMode
            : carryoverMode // ignore: cast_nullable_to_non_nullable
                  as CarryoverMode,
        pointsCarriedOver: null == pointsCarriedOver
            ? _value.pointsCarriedOver
            : pointsCarriedOver // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SkillTreeResetImpl extends _SkillTreeReset {
  const _$SkillTreeResetImpl({
    required this.seasonId,
    required this.nextSeasonId,
    required this.userId,
    required this.previousTree,
    required this.currentTree,
    required this.resetAt,
    required this.carryoverMode,
    required this.pointsCarriedOver,
  }) : super._();

  factory _$SkillTreeResetImpl.fromJson(Map<String, dynamic> json) =>
      _$$SkillTreeResetImplFromJson(json);

  @override
  final String seasonId;
  @override
  final String nextSeasonId;
  @override
  final String userId;
  @override
  final SkillTree previousTree;
  // Backup of last season
  @override
  final SkillTree currentTree;
  // Fresh allocation post-reset
  @override
  final DateTime resetAt;
  @override
  final CarryoverMode carryoverMode;
  @override
  final int pointsCarriedOver;

  @override
  String toString() {
    return 'SkillTreeReset(seasonId: $seasonId, nextSeasonId: $nextSeasonId, userId: $userId, previousTree: $previousTree, currentTree: $currentTree, resetAt: $resetAt, carryoverMode: $carryoverMode, pointsCarriedOver: $pointsCarriedOver)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SkillTreeResetImpl &&
            (identical(other.seasonId, seasonId) ||
                other.seasonId == seasonId) &&
            (identical(other.nextSeasonId, nextSeasonId) ||
                other.nextSeasonId == nextSeasonId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.previousTree, previousTree) ||
                other.previousTree == previousTree) &&
            (identical(other.currentTree, currentTree) ||
                other.currentTree == currentTree) &&
            (identical(other.resetAt, resetAt) || other.resetAt == resetAt) &&
            (identical(other.carryoverMode, carryoverMode) ||
                other.carryoverMode == carryoverMode) &&
            (identical(other.pointsCarriedOver, pointsCarriedOver) ||
                other.pointsCarriedOver == pointsCarriedOver));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    seasonId,
    nextSeasonId,
    userId,
    previousTree,
    currentTree,
    resetAt,
    carryoverMode,
    pointsCarriedOver,
  );

  /// Create a copy of SkillTreeReset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SkillTreeResetImplCopyWith<_$SkillTreeResetImpl> get copyWith =>
      __$$SkillTreeResetImplCopyWithImpl<_$SkillTreeResetImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SkillTreeResetImplToJson(this);
  }
}

abstract class _SkillTreeReset extends SkillTreeReset {
  const factory _SkillTreeReset({
    required final String seasonId,
    required final String nextSeasonId,
    required final String userId,
    required final SkillTree previousTree,
    required final SkillTree currentTree,
    required final DateTime resetAt,
    required final CarryoverMode carryoverMode,
    required final int pointsCarriedOver,
  }) = _$SkillTreeResetImpl;
  const _SkillTreeReset._() : super._();

  factory _SkillTreeReset.fromJson(Map<String, dynamic> json) =
      _$SkillTreeResetImpl.fromJson;

  @override
  String get seasonId;
  @override
  String get nextSeasonId;
  @override
  String get userId;
  @override
  SkillTree get previousTree; // Backup of last season
  @override
  SkillTree get currentTree; // Fresh allocation post-reset
  @override
  DateTime get resetAt;
  @override
  CarryoverMode get carryoverMode;
  @override
  int get pointsCarriedOver;

  /// Create a copy of SkillTreeReset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SkillTreeResetImplCopyWith<_$SkillTreeResetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProgressDelta _$ProgressDeltaFromJson(Map<String, dynamic> json) {
  return _ProgressDelta.fromJson(json);
}

/// @nodoc
mixin _$ProgressDelta {
  String get fromSeasonId => throw _privateConstructorUsedError;
  String get toSeasonId => throw _privateConstructorUsedError;
  int get pointsGained =>
      throw _privateConstructorUsedError; // Total new points allocated
  int get pointsLost =>
      throw _privateConstructorUsedError; // Points lost to reset
  double get carryoverPercentage =>
      throw _privateConstructorUsedError; // % of previous points kept
  Map<String, int> get treeDeltas =>
      throw _privateConstructorUsedError; // Per-tree point changes
  String get fromTier => throw _privateConstructorUsedError;
  String get toTier => throw _privateConstructorUsedError;
  bool get isPromotion => throw _privateConstructorUsedError;

  /// Serializes this ProgressDelta to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProgressDelta
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProgressDeltaCopyWith<ProgressDelta> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProgressDeltaCopyWith<$Res> {
  factory $ProgressDeltaCopyWith(
    ProgressDelta value,
    $Res Function(ProgressDelta) then,
  ) = _$ProgressDeltaCopyWithImpl<$Res, ProgressDelta>;
  @useResult
  $Res call({
    String fromSeasonId,
    String toSeasonId,
    int pointsGained,
    int pointsLost,
    double carryoverPercentage,
    Map<String, int> treeDeltas,
    String fromTier,
    String toTier,
    bool isPromotion,
  });
}

/// @nodoc
class _$ProgressDeltaCopyWithImpl<$Res, $Val extends ProgressDelta>
    implements $ProgressDeltaCopyWith<$Res> {
  _$ProgressDeltaCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProgressDelta
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fromSeasonId = null,
    Object? toSeasonId = null,
    Object? pointsGained = null,
    Object? pointsLost = null,
    Object? carryoverPercentage = null,
    Object? treeDeltas = null,
    Object? fromTier = null,
    Object? toTier = null,
    Object? isPromotion = null,
  }) {
    return _then(
      _value.copyWith(
            fromSeasonId: null == fromSeasonId
                ? _value.fromSeasonId
                : fromSeasonId // ignore: cast_nullable_to_non_nullable
                      as String,
            toSeasonId: null == toSeasonId
                ? _value.toSeasonId
                : toSeasonId // ignore: cast_nullable_to_non_nullable
                      as String,
            pointsGained: null == pointsGained
                ? _value.pointsGained
                : pointsGained // ignore: cast_nullable_to_non_nullable
                      as int,
            pointsLost: null == pointsLost
                ? _value.pointsLost
                : pointsLost // ignore: cast_nullable_to_non_nullable
                      as int,
            carryoverPercentage: null == carryoverPercentage
                ? _value.carryoverPercentage
                : carryoverPercentage // ignore: cast_nullable_to_non_nullable
                      as double,
            treeDeltas: null == treeDeltas
                ? _value.treeDeltas
                : treeDeltas // ignore: cast_nullable_to_non_nullable
                      as Map<String, int>,
            fromTier: null == fromTier
                ? _value.fromTier
                : fromTier // ignore: cast_nullable_to_non_nullable
                      as String,
            toTier: null == toTier
                ? _value.toTier
                : toTier // ignore: cast_nullable_to_non_nullable
                      as String,
            isPromotion: null == isPromotion
                ? _value.isPromotion
                : isPromotion // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProgressDeltaImplCopyWith<$Res>
    implements $ProgressDeltaCopyWith<$Res> {
  factory _$$ProgressDeltaImplCopyWith(
    _$ProgressDeltaImpl value,
    $Res Function(_$ProgressDeltaImpl) then,
  ) = __$$ProgressDeltaImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String fromSeasonId,
    String toSeasonId,
    int pointsGained,
    int pointsLost,
    double carryoverPercentage,
    Map<String, int> treeDeltas,
    String fromTier,
    String toTier,
    bool isPromotion,
  });
}

/// @nodoc
class __$$ProgressDeltaImplCopyWithImpl<$Res>
    extends _$ProgressDeltaCopyWithImpl<$Res, _$ProgressDeltaImpl>
    implements _$$ProgressDeltaImplCopyWith<$Res> {
  __$$ProgressDeltaImplCopyWithImpl(
    _$ProgressDeltaImpl _value,
    $Res Function(_$ProgressDeltaImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ProgressDelta
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fromSeasonId = null,
    Object? toSeasonId = null,
    Object? pointsGained = null,
    Object? pointsLost = null,
    Object? carryoverPercentage = null,
    Object? treeDeltas = null,
    Object? fromTier = null,
    Object? toTier = null,
    Object? isPromotion = null,
  }) {
    return _then(
      _$ProgressDeltaImpl(
        fromSeasonId: null == fromSeasonId
            ? _value.fromSeasonId
            : fromSeasonId // ignore: cast_nullable_to_non_nullable
                  as String,
        toSeasonId: null == toSeasonId
            ? _value.toSeasonId
            : toSeasonId // ignore: cast_nullable_to_non_nullable
                  as String,
        pointsGained: null == pointsGained
            ? _value.pointsGained
            : pointsGained // ignore: cast_nullable_to_non_nullable
                  as int,
        pointsLost: null == pointsLost
            ? _value.pointsLost
            : pointsLost // ignore: cast_nullable_to_non_nullable
                  as int,
        carryoverPercentage: null == carryoverPercentage
            ? _value.carryoverPercentage
            : carryoverPercentage // ignore: cast_nullable_to_non_nullable
                  as double,
        treeDeltas: null == treeDeltas
            ? _value._treeDeltas
            : treeDeltas // ignore: cast_nullable_to_non_nullable
                  as Map<String, int>,
        fromTier: null == fromTier
            ? _value.fromTier
            : fromTier // ignore: cast_nullable_to_non_nullable
                  as String,
        toTier: null == toTier
            ? _value.toTier
            : toTier // ignore: cast_nullable_to_non_nullable
                  as String,
        isPromotion: null == isPromotion
            ? _value.isPromotion
            : isPromotion // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ProgressDeltaImpl implements _ProgressDelta {
  const _$ProgressDeltaImpl({
    required this.fromSeasonId,
    required this.toSeasonId,
    required this.pointsGained,
    required this.pointsLost,
    required this.carryoverPercentage,
    required final Map<String, int> treeDeltas,
    required this.fromTier,
    required this.toTier,
    required this.isPromotion,
  }) : _treeDeltas = treeDeltas;

  factory _$ProgressDeltaImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProgressDeltaImplFromJson(json);

  @override
  final String fromSeasonId;
  @override
  final String toSeasonId;
  @override
  final int pointsGained;
  // Total new points allocated
  @override
  final int pointsLost;
  // Points lost to reset
  @override
  final double carryoverPercentage;
  // % of previous points kept
  final Map<String, int> _treeDeltas;
  // % of previous points kept
  @override
  Map<String, int> get treeDeltas {
    if (_treeDeltas is EqualUnmodifiableMapView) return _treeDeltas;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_treeDeltas);
  }

  // Per-tree point changes
  @override
  final String fromTier;
  @override
  final String toTier;
  @override
  final bool isPromotion;

  @override
  String toString() {
    return 'ProgressDelta(fromSeasonId: $fromSeasonId, toSeasonId: $toSeasonId, pointsGained: $pointsGained, pointsLost: $pointsLost, carryoverPercentage: $carryoverPercentage, treeDeltas: $treeDeltas, fromTier: $fromTier, toTier: $toTier, isPromotion: $isPromotion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProgressDeltaImpl &&
            (identical(other.fromSeasonId, fromSeasonId) ||
                other.fromSeasonId == fromSeasonId) &&
            (identical(other.toSeasonId, toSeasonId) ||
                other.toSeasonId == toSeasonId) &&
            (identical(other.pointsGained, pointsGained) ||
                other.pointsGained == pointsGained) &&
            (identical(other.pointsLost, pointsLost) ||
                other.pointsLost == pointsLost) &&
            (identical(other.carryoverPercentage, carryoverPercentage) ||
                other.carryoverPercentage == carryoverPercentage) &&
            const DeepCollectionEquality().equals(
              other._treeDeltas,
              _treeDeltas,
            ) &&
            (identical(other.fromTier, fromTier) ||
                other.fromTier == fromTier) &&
            (identical(other.toTier, toTier) || other.toTier == toTier) &&
            (identical(other.isPromotion, isPromotion) ||
                other.isPromotion == isPromotion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    fromSeasonId,
    toSeasonId,
    pointsGained,
    pointsLost,
    carryoverPercentage,
    const DeepCollectionEquality().hash(_treeDeltas),
    fromTier,
    toTier,
    isPromotion,
  );

  /// Create a copy of ProgressDelta
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProgressDeltaImplCopyWith<_$ProgressDeltaImpl> get copyWith =>
      __$$ProgressDeltaImplCopyWithImpl<_$ProgressDeltaImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProgressDeltaImplToJson(this);
  }
}

abstract class _ProgressDelta implements ProgressDelta {
  const factory _ProgressDelta({
    required final String fromSeasonId,
    required final String toSeasonId,
    required final int pointsGained,
    required final int pointsLost,
    required final double carryoverPercentage,
    required final Map<String, int> treeDeltas,
    required final String fromTier,
    required final String toTier,
    required final bool isPromotion,
  }) = _$ProgressDeltaImpl;

  factory _ProgressDelta.fromJson(Map<String, dynamic> json) =
      _$ProgressDeltaImpl.fromJson;

  @override
  String get fromSeasonId;
  @override
  String get toSeasonId;
  @override
  int get pointsGained; // Total new points allocated
  @override
  int get pointsLost; // Points lost to reset
  @override
  double get carryoverPercentage; // % of previous points kept
  @override
  Map<String, int> get treeDeltas; // Per-tree point changes
  @override
  String get fromTier;
  @override
  String get toTier;
  @override
  bool get isPromotion;

  /// Create a copy of ProgressDelta
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProgressDeltaImplCopyWith<_$ProgressDeltaImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SeasonResetConfig _$SeasonResetConfigFromJson(Map<String, dynamic> json) {
  return _SeasonResetConfig.fromJson(json);
}

/// @nodoc
mixin _$SeasonResetConfig {
  String get seasonId => throw _privateConstructorUsedError;
  String get nextSeasonId => throw _privateConstructorUsedError;
  DateTime get endDate => throw _privateConstructorUsedError;
  DateTime get resetDate =>
      throw _privateConstructorUsedError; // When resets occur
  CarryoverMode get defaultCarryoverMode => throw _privateConstructorUsedError;
  bool get allowManualReset => throw _privateConstructorUsedError;

  /// Serializes this SeasonResetConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SeasonResetConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SeasonResetConfigCopyWith<SeasonResetConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SeasonResetConfigCopyWith<$Res> {
  factory $SeasonResetConfigCopyWith(
    SeasonResetConfig value,
    $Res Function(SeasonResetConfig) then,
  ) = _$SeasonResetConfigCopyWithImpl<$Res, SeasonResetConfig>;
  @useResult
  $Res call({
    String seasonId,
    String nextSeasonId,
    DateTime endDate,
    DateTime resetDate,
    CarryoverMode defaultCarryoverMode,
    bool allowManualReset,
  });
}

/// @nodoc
class _$SeasonResetConfigCopyWithImpl<$Res, $Val extends SeasonResetConfig>
    implements $SeasonResetConfigCopyWith<$Res> {
  _$SeasonResetConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SeasonResetConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? seasonId = null,
    Object? nextSeasonId = null,
    Object? endDate = null,
    Object? resetDate = null,
    Object? defaultCarryoverMode = null,
    Object? allowManualReset = null,
  }) {
    return _then(
      _value.copyWith(
            seasonId: null == seasonId
                ? _value.seasonId
                : seasonId // ignore: cast_nullable_to_non_nullable
                      as String,
            nextSeasonId: null == nextSeasonId
                ? _value.nextSeasonId
                : nextSeasonId // ignore: cast_nullable_to_non_nullable
                      as String,
            endDate: null == endDate
                ? _value.endDate
                : endDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            resetDate: null == resetDate
                ? _value.resetDate
                : resetDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            defaultCarryoverMode: null == defaultCarryoverMode
                ? _value.defaultCarryoverMode
                : defaultCarryoverMode // ignore: cast_nullable_to_non_nullable
                      as CarryoverMode,
            allowManualReset: null == allowManualReset
                ? _value.allowManualReset
                : allowManualReset // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SeasonResetConfigImplCopyWith<$Res>
    implements $SeasonResetConfigCopyWith<$Res> {
  factory _$$SeasonResetConfigImplCopyWith(
    _$SeasonResetConfigImpl value,
    $Res Function(_$SeasonResetConfigImpl) then,
  ) = __$$SeasonResetConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String seasonId,
    String nextSeasonId,
    DateTime endDate,
    DateTime resetDate,
    CarryoverMode defaultCarryoverMode,
    bool allowManualReset,
  });
}

/// @nodoc
class __$$SeasonResetConfigImplCopyWithImpl<$Res>
    extends _$SeasonResetConfigCopyWithImpl<$Res, _$SeasonResetConfigImpl>
    implements _$$SeasonResetConfigImplCopyWith<$Res> {
  __$$SeasonResetConfigImplCopyWithImpl(
    _$SeasonResetConfigImpl _value,
    $Res Function(_$SeasonResetConfigImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SeasonResetConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? seasonId = null,
    Object? nextSeasonId = null,
    Object? endDate = null,
    Object? resetDate = null,
    Object? defaultCarryoverMode = null,
    Object? allowManualReset = null,
  }) {
    return _then(
      _$SeasonResetConfigImpl(
        seasonId: null == seasonId
            ? _value.seasonId
            : seasonId // ignore: cast_nullable_to_non_nullable
                  as String,
        nextSeasonId: null == nextSeasonId
            ? _value.nextSeasonId
            : nextSeasonId // ignore: cast_nullable_to_non_nullable
                  as String,
        endDate: null == endDate
            ? _value.endDate
            : endDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        resetDate: null == resetDate
            ? _value.resetDate
            : resetDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        defaultCarryoverMode: null == defaultCarryoverMode
            ? _value.defaultCarryoverMode
            : defaultCarryoverMode // ignore: cast_nullable_to_non_nullable
                  as CarryoverMode,
        allowManualReset: null == allowManualReset
            ? _value.allowManualReset
            : allowManualReset // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SeasonResetConfigImpl extends _SeasonResetConfig {
  const _$SeasonResetConfigImpl({
    required this.seasonId,
    required this.nextSeasonId,
    required this.endDate,
    required this.resetDate,
    required this.defaultCarryoverMode,
    required this.allowManualReset,
  }) : super._();

  factory _$SeasonResetConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$SeasonResetConfigImplFromJson(json);

  @override
  final String seasonId;
  @override
  final String nextSeasonId;
  @override
  final DateTime endDate;
  @override
  final DateTime resetDate;
  // When resets occur
  @override
  final CarryoverMode defaultCarryoverMode;
  @override
  final bool allowManualReset;

  @override
  String toString() {
    return 'SeasonResetConfig(seasonId: $seasonId, nextSeasonId: $nextSeasonId, endDate: $endDate, resetDate: $resetDate, defaultCarryoverMode: $defaultCarryoverMode, allowManualReset: $allowManualReset)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SeasonResetConfigImpl &&
            (identical(other.seasonId, seasonId) ||
                other.seasonId == seasonId) &&
            (identical(other.nextSeasonId, nextSeasonId) ||
                other.nextSeasonId == nextSeasonId) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.resetDate, resetDate) ||
                other.resetDate == resetDate) &&
            (identical(other.defaultCarryoverMode, defaultCarryoverMode) ||
                other.defaultCarryoverMode == defaultCarryoverMode) &&
            (identical(other.allowManualReset, allowManualReset) ||
                other.allowManualReset == allowManualReset));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    seasonId,
    nextSeasonId,
    endDate,
    resetDate,
    defaultCarryoverMode,
    allowManualReset,
  );

  /// Create a copy of SeasonResetConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SeasonResetConfigImplCopyWith<_$SeasonResetConfigImpl> get copyWith =>
      __$$SeasonResetConfigImplCopyWithImpl<_$SeasonResetConfigImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SeasonResetConfigImplToJson(this);
  }
}

abstract class _SeasonResetConfig extends SeasonResetConfig {
  const factory _SeasonResetConfig({
    required final String seasonId,
    required final String nextSeasonId,
    required final DateTime endDate,
    required final DateTime resetDate,
    required final CarryoverMode defaultCarryoverMode,
    required final bool allowManualReset,
  }) = _$SeasonResetConfigImpl;
  const _SeasonResetConfig._() : super._();

  factory _SeasonResetConfig.fromJson(Map<String, dynamic> json) =
      _$SeasonResetConfigImpl.fromJson;

  @override
  String get seasonId;
  @override
  String get nextSeasonId;
  @override
  DateTime get endDate;
  @override
  DateTime get resetDate; // When resets occur
  @override
  CarryoverMode get defaultCarryoverMode;
  @override
  bool get allowManualReset;

  /// Create a copy of SeasonResetConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SeasonResetConfigImplCopyWith<_$SeasonResetConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
