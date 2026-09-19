// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'progression_analytics_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SeasonComparison _$SeasonComparisonFromJson(Map<String, dynamic> json) {
  return _SeasonComparison.fromJson(json);
}

/// @nodoc
mixin _$SeasonComparison {
  SeasonStats get season1 => throw _privateConstructorUsedError;
  SeasonStats get season2 => throw _privateConstructorUsedError;
  String get tierChange => throw _privateConstructorUsedError;
  Map<String, int> get pointsChangePerTree =>
      throw _privateConstructorUsedError;

  /// Serializes this SeasonComparison to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SeasonComparison
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SeasonComparisonCopyWith<SeasonComparison> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SeasonComparisonCopyWith<$Res> {
  factory $SeasonComparisonCopyWith(
    SeasonComparison value,
    $Res Function(SeasonComparison) then,
  ) = _$SeasonComparisonCopyWithImpl<$Res, SeasonComparison>;
  @useResult
  $Res call({
    SeasonStats season1,
    SeasonStats season2,
    String tierChange,
    Map<String, int> pointsChangePerTree,
  });

  $SeasonStatsCopyWith<$Res> get season1;
  $SeasonStatsCopyWith<$Res> get season2;
}

/// @nodoc
class _$SeasonComparisonCopyWithImpl<$Res, $Val extends SeasonComparison>
    implements $SeasonComparisonCopyWith<$Res> {
  _$SeasonComparisonCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SeasonComparison
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? season1 = null,
    Object? season2 = null,
    Object? tierChange = null,
    Object? pointsChangePerTree = null,
  }) {
    return _then(
      _value.copyWith(
            season1: null == season1
                ? _value.season1
                : season1 // ignore: cast_nullable_to_non_nullable
                      as SeasonStats,
            season2: null == season2
                ? _value.season2
                : season2 // ignore: cast_nullable_to_non_nullable
                      as SeasonStats,
            tierChange: null == tierChange
                ? _value.tierChange
                : tierChange // ignore: cast_nullable_to_non_nullable
                      as String,
            pointsChangePerTree: null == pointsChangePerTree
                ? _value.pointsChangePerTree
                : pointsChangePerTree // ignore: cast_nullable_to_non_nullable
                      as Map<String, int>,
          )
          as $Val,
    );
  }

  /// Create a copy of SeasonComparison
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SeasonStatsCopyWith<$Res> get season1 {
    return $SeasonStatsCopyWith<$Res>(_value.season1, (value) {
      return _then(_value.copyWith(season1: value) as $Val);
    });
  }

  /// Create a copy of SeasonComparison
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SeasonStatsCopyWith<$Res> get season2 {
    return $SeasonStatsCopyWith<$Res>(_value.season2, (value) {
      return _then(_value.copyWith(season2: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SeasonComparisonImplCopyWith<$Res>
    implements $SeasonComparisonCopyWith<$Res> {
  factory _$$SeasonComparisonImplCopyWith(
    _$SeasonComparisonImpl value,
    $Res Function(_$SeasonComparisonImpl) then,
  ) = __$$SeasonComparisonImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    SeasonStats season1,
    SeasonStats season2,
    String tierChange,
    Map<String, int> pointsChangePerTree,
  });

  @override
  $SeasonStatsCopyWith<$Res> get season1;
  @override
  $SeasonStatsCopyWith<$Res> get season2;
}

/// @nodoc
class __$$SeasonComparisonImplCopyWithImpl<$Res>
    extends _$SeasonComparisonCopyWithImpl<$Res, _$SeasonComparisonImpl>
    implements _$$SeasonComparisonImplCopyWith<$Res> {
  __$$SeasonComparisonImplCopyWithImpl(
    _$SeasonComparisonImpl _value,
    $Res Function(_$SeasonComparisonImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SeasonComparison
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? season1 = null,
    Object? season2 = null,
    Object? tierChange = null,
    Object? pointsChangePerTree = null,
  }) {
    return _then(
      _$SeasonComparisonImpl(
        season1: null == season1
            ? _value.season1
            : season1 // ignore: cast_nullable_to_non_nullable
                  as SeasonStats,
        season2: null == season2
            ? _value.season2
            : season2 // ignore: cast_nullable_to_non_nullable
                  as SeasonStats,
        tierChange: null == tierChange
            ? _value.tierChange
            : tierChange // ignore: cast_nullable_to_non_nullable
                  as String,
        pointsChangePerTree: null == pointsChangePerTree
            ? _value._pointsChangePerTree
            : pointsChangePerTree // ignore: cast_nullable_to_non_nullable
                  as Map<String, int>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SeasonComparisonImpl implements _SeasonComparison {
  const _$SeasonComparisonImpl({
    required this.season1,
    required this.season2,
    required this.tierChange,
    required final Map<String, int> pointsChangePerTree,
  }) : _pointsChangePerTree = pointsChangePerTree;

  factory _$SeasonComparisonImpl.fromJson(Map<String, dynamic> json) =>
      _$$SeasonComparisonImplFromJson(json);

  @override
  final SeasonStats season1;
  @override
  final SeasonStats season2;
  @override
  final String tierChange;
  final Map<String, int> _pointsChangePerTree;
  @override
  Map<String, int> get pointsChangePerTree {
    if (_pointsChangePerTree is EqualUnmodifiableMapView)
      return _pointsChangePerTree;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_pointsChangePerTree);
  }

  @override
  String toString() {
    return 'SeasonComparison(season1: $season1, season2: $season2, tierChange: $tierChange, pointsChangePerTree: $pointsChangePerTree)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SeasonComparisonImpl &&
            (identical(other.season1, season1) || other.season1 == season1) &&
            (identical(other.season2, season2) || other.season2 == season2) &&
            (identical(other.tierChange, tierChange) ||
                other.tierChange == tierChange) &&
            const DeepCollectionEquality().equals(
              other._pointsChangePerTree,
              _pointsChangePerTree,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    season1,
    season2,
    tierChange,
    const DeepCollectionEquality().hash(_pointsChangePerTree),
  );

  /// Create a copy of SeasonComparison
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SeasonComparisonImplCopyWith<_$SeasonComparisonImpl> get copyWith =>
      __$$SeasonComparisonImplCopyWithImpl<_$SeasonComparisonImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SeasonComparisonImplToJson(this);
  }
}

abstract class _SeasonComparison implements SeasonComparison {
  const factory _SeasonComparison({
    required final SeasonStats season1,
    required final SeasonStats season2,
    required final String tierChange,
    required final Map<String, int> pointsChangePerTree,
  }) = _$SeasonComparisonImpl;

  factory _SeasonComparison.fromJson(Map<String, dynamic> json) =
      _$SeasonComparisonImpl.fromJson;

  @override
  SeasonStats get season1;
  @override
  SeasonStats get season2;
  @override
  String get tierChange;
  @override
  Map<String, int> get pointsChangePerTree;

  /// Create a copy of SeasonComparison
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SeasonComparisonImplCopyWith<_$SeasonComparisonImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TierPrediction _$TierPredictionFromJson(Map<String, dynamic> json) {
  return _TierPrediction.fromJson(json);
}

/// @nodoc
mixin _$TierPrediction {
  String get currentTier => throw _privateConstructorUsedError;
  String get predictedTier => throw _privateConstructorUsedError;
  double get confidence => throw _privateConstructorUsedError; // 0.0 - 1.0
  int get daysToReach => throw _privateConstructorUsedError;

  /// Serializes this TierPrediction to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TierPrediction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TierPredictionCopyWith<TierPrediction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TierPredictionCopyWith<$Res> {
  factory $TierPredictionCopyWith(
    TierPrediction value,
    $Res Function(TierPrediction) then,
  ) = _$TierPredictionCopyWithImpl<$Res, TierPrediction>;
  @useResult
  $Res call({
    String currentTier,
    String predictedTier,
    double confidence,
    int daysToReach,
  });
}

/// @nodoc
class _$TierPredictionCopyWithImpl<$Res, $Val extends TierPrediction>
    implements $TierPredictionCopyWith<$Res> {
  _$TierPredictionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TierPrediction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentTier = null,
    Object? predictedTier = null,
    Object? confidence = null,
    Object? daysToReach = null,
  }) {
    return _then(
      _value.copyWith(
            currentTier: null == currentTier
                ? _value.currentTier
                : currentTier // ignore: cast_nullable_to_non_nullable
                      as String,
            predictedTier: null == predictedTier
                ? _value.predictedTier
                : predictedTier // ignore: cast_nullable_to_non_nullable
                      as String,
            confidence: null == confidence
                ? _value.confidence
                : confidence // ignore: cast_nullable_to_non_nullable
                      as double,
            daysToReach: null == daysToReach
                ? _value.daysToReach
                : daysToReach // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TierPredictionImplCopyWith<$Res>
    implements $TierPredictionCopyWith<$Res> {
  factory _$$TierPredictionImplCopyWith(
    _$TierPredictionImpl value,
    $Res Function(_$TierPredictionImpl) then,
  ) = __$$TierPredictionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String currentTier,
    String predictedTier,
    double confidence,
    int daysToReach,
  });
}

/// @nodoc
class __$$TierPredictionImplCopyWithImpl<$Res>
    extends _$TierPredictionCopyWithImpl<$Res, _$TierPredictionImpl>
    implements _$$TierPredictionImplCopyWith<$Res> {
  __$$TierPredictionImplCopyWithImpl(
    _$TierPredictionImpl _value,
    $Res Function(_$TierPredictionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TierPrediction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentTier = null,
    Object? predictedTier = null,
    Object? confidence = null,
    Object? daysToReach = null,
  }) {
    return _then(
      _$TierPredictionImpl(
        currentTier: null == currentTier
            ? _value.currentTier
            : currentTier // ignore: cast_nullable_to_non_nullable
                  as String,
        predictedTier: null == predictedTier
            ? _value.predictedTier
            : predictedTier // ignore: cast_nullable_to_non_nullable
                  as String,
        confidence: null == confidence
            ? _value.confidence
            : confidence // ignore: cast_nullable_to_non_nullable
                  as double,
        daysToReach: null == daysToReach
            ? _value.daysToReach
            : daysToReach // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TierPredictionImpl implements _TierPrediction {
  const _$TierPredictionImpl({
    required this.currentTier,
    required this.predictedTier,
    required this.confidence,
    required this.daysToReach,
  });

  factory _$TierPredictionImpl.fromJson(Map<String, dynamic> json) =>
      _$$TierPredictionImplFromJson(json);

  @override
  final String currentTier;
  @override
  final String predictedTier;
  @override
  final double confidence;
  // 0.0 - 1.0
  @override
  final int daysToReach;

  @override
  String toString() {
    return 'TierPrediction(currentTier: $currentTier, predictedTier: $predictedTier, confidence: $confidence, daysToReach: $daysToReach)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TierPredictionImpl &&
            (identical(other.currentTier, currentTier) ||
                other.currentTier == currentTier) &&
            (identical(other.predictedTier, predictedTier) ||
                other.predictedTier == predictedTier) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.daysToReach, daysToReach) ||
                other.daysToReach == daysToReach));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    currentTier,
    predictedTier,
    confidence,
    daysToReach,
  );

  /// Create a copy of TierPrediction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TierPredictionImplCopyWith<_$TierPredictionImpl> get copyWith =>
      __$$TierPredictionImplCopyWithImpl<_$TierPredictionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TierPredictionImplToJson(this);
  }
}

abstract class _TierPrediction implements TierPrediction {
  const factory _TierPrediction({
    required final String currentTier,
    required final String predictedTier,
    required final double confidence,
    required final int daysToReach,
  }) = _$TierPredictionImpl;

  factory _TierPrediction.fromJson(Map<String, dynamic> json) =
      _$TierPredictionImpl.fromJson;

  @override
  String get currentTier;
  @override
  String get predictedTier;
  @override
  double get confidence; // 0.0 - 1.0
  @override
  int get daysToReach;

  /// Create a copy of TierPrediction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TierPredictionImplCopyWith<_$TierPredictionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
