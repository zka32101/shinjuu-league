// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ab_test_variant.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ABTestVariant _$ABTestVariantFromJson(Map<String, dynamic> json) {
  return _ABTestVariant.fromJson(json);
}

/// @nodoc
mixin _$ABTestVariant {
  String get featureName => throw _privateConstructorUsedError;
  String get variantName => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  DateTime get assignedAt => throw _privateConstructorUsedError;
  String get cohortName => throw _privateConstructorUsedError;
  bool get isControl => throw _privateConstructorUsedError;

  /// Serializes this ABTestVariant to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ABTestVariant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ABTestVariantCopyWith<ABTestVariant> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ABTestVariantCopyWith<$Res> {
  factory $ABTestVariantCopyWith(
    ABTestVariant value,
    $Res Function(ABTestVariant) then,
  ) = _$ABTestVariantCopyWithImpl<$Res, ABTestVariant>;
  @useResult
  $Res call({
    String featureName,
    String variantName,
    String userId,
    DateTime assignedAt,
    String cohortName,
    bool isControl,
  });
}

/// @nodoc
class _$ABTestVariantCopyWithImpl<$Res, $Val extends ABTestVariant>
    implements $ABTestVariantCopyWith<$Res> {
  _$ABTestVariantCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ABTestVariant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? featureName = null,
    Object? variantName = null,
    Object? userId = null,
    Object? assignedAt = null,
    Object? cohortName = null,
    Object? isControl = null,
  }) {
    return _then(
      _value.copyWith(
            featureName: null == featureName
                ? _value.featureName
                : featureName // ignore: cast_nullable_to_non_nullable
                      as String,
            variantName: null == variantName
                ? _value.variantName
                : variantName // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            assignedAt: null == assignedAt
                ? _value.assignedAt
                : assignedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            cohortName: null == cohortName
                ? _value.cohortName
                : cohortName // ignore: cast_nullable_to_non_nullable
                      as String,
            isControl: null == isControl
                ? _value.isControl
                : isControl // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ABTestVariantImplCopyWith<$Res>
    implements $ABTestVariantCopyWith<$Res> {
  factory _$$ABTestVariantImplCopyWith(
    _$ABTestVariantImpl value,
    $Res Function(_$ABTestVariantImpl) then,
  ) = __$$ABTestVariantImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String featureName,
    String variantName,
    String userId,
    DateTime assignedAt,
    String cohortName,
    bool isControl,
  });
}

/// @nodoc
class __$$ABTestVariantImplCopyWithImpl<$Res>
    extends _$ABTestVariantCopyWithImpl<$Res, _$ABTestVariantImpl>
    implements _$$ABTestVariantImplCopyWith<$Res> {
  __$$ABTestVariantImplCopyWithImpl(
    _$ABTestVariantImpl _value,
    $Res Function(_$ABTestVariantImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ABTestVariant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? featureName = null,
    Object? variantName = null,
    Object? userId = null,
    Object? assignedAt = null,
    Object? cohortName = null,
    Object? isControl = null,
  }) {
    return _then(
      _$ABTestVariantImpl(
        featureName: null == featureName
            ? _value.featureName
            : featureName // ignore: cast_nullable_to_non_nullable
                  as String,
        variantName: null == variantName
            ? _value.variantName
            : variantName // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        assignedAt: null == assignedAt
            ? _value.assignedAt
            : assignedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        cohortName: null == cohortName
            ? _value.cohortName
            : cohortName // ignore: cast_nullable_to_non_nullable
                  as String,
        isControl: null == isControl
            ? _value.isControl
            : isControl // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ABTestVariantImpl implements _ABTestVariant {
  const _$ABTestVariantImpl({
    required this.featureName,
    required this.variantName,
    required this.userId,
    required this.assignedAt,
    required this.cohortName,
    this.isControl = false,
  });

  factory _$ABTestVariantImpl.fromJson(Map<String, dynamic> json) =>
      _$$ABTestVariantImplFromJson(json);

  @override
  final String featureName;
  @override
  final String variantName;
  @override
  final String userId;
  @override
  final DateTime assignedAt;
  @override
  final String cohortName;
  @override
  @JsonKey()
  final bool isControl;

  @override
  String toString() {
    return 'ABTestVariant(featureName: $featureName, variantName: $variantName, userId: $userId, assignedAt: $assignedAt, cohortName: $cohortName, isControl: $isControl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ABTestVariantImpl &&
            (identical(other.featureName, featureName) ||
                other.featureName == featureName) &&
            (identical(other.variantName, variantName) ||
                other.variantName == variantName) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.assignedAt, assignedAt) ||
                other.assignedAt == assignedAt) &&
            (identical(other.cohortName, cohortName) ||
                other.cohortName == cohortName) &&
            (identical(other.isControl, isControl) ||
                other.isControl == isControl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    featureName,
    variantName,
    userId,
    assignedAt,
    cohortName,
    isControl,
  );

  /// Create a copy of ABTestVariant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ABTestVariantImplCopyWith<_$ABTestVariantImpl> get copyWith =>
      __$$ABTestVariantImplCopyWithImpl<_$ABTestVariantImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ABTestVariantImplToJson(this);
  }
}

abstract class _ABTestVariant implements ABTestVariant {
  const factory _ABTestVariant({
    required final String featureName,
    required final String variantName,
    required final String userId,
    required final DateTime assignedAt,
    required final String cohortName,
    final bool isControl,
  }) = _$ABTestVariantImpl;

  factory _ABTestVariant.fromJson(Map<String, dynamic> json) =
      _$ABTestVariantImpl.fromJson;

  @override
  String get featureName;
  @override
  String get variantName;
  @override
  String get userId;
  @override
  DateTime get assignedAt;
  @override
  String get cohortName;
  @override
  bool get isControl;

  /// Create a copy of ABTestVariant
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ABTestVariantImplCopyWith<_$ABTestVariantImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ABTestExperiment _$ABTestExperimentFromJson(Map<String, dynamic> json) {
  return _ABTestExperiment.fromJson(json);
}

/// @nodoc
mixin _$ABTestExperiment {
  String get experimentId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  DateTime get startDate => throw _privateConstructorUsedError;
  DateTime? get endDate => throw _privateConstructorUsedError;
  List<String> get variants => throw _privateConstructorUsedError;
  String get controlVariant => throw _privateConstructorUsedError;
  int get rolloutPercentage => throw _privateConstructorUsedError;
  Map<String, int> get variantDistribution =>
      throw _privateConstructorUsedError; // variantName -> percentage
  ABTestStatus get status => throw _privateConstructorUsedError;

  /// Serializes this ABTestExperiment to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ABTestExperiment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ABTestExperimentCopyWith<ABTestExperiment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ABTestExperimentCopyWith<$Res> {
  factory $ABTestExperimentCopyWith(
    ABTestExperiment value,
    $Res Function(ABTestExperiment) then,
  ) = _$ABTestExperimentCopyWithImpl<$Res, ABTestExperiment>;
  @useResult
  $Res call({
    String experimentId,
    String name,
    String description,
    DateTime startDate,
    DateTime? endDate,
    List<String> variants,
    String controlVariant,
    int rolloutPercentage,
    Map<String, int> variantDistribution,
    ABTestStatus status,
  });
}

/// @nodoc
class _$ABTestExperimentCopyWithImpl<$Res, $Val extends ABTestExperiment>
    implements $ABTestExperimentCopyWith<$Res> {
  _$ABTestExperimentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ABTestExperiment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? experimentId = null,
    Object? name = null,
    Object? description = null,
    Object? startDate = null,
    Object? endDate = freezed,
    Object? variants = null,
    Object? controlVariant = null,
    Object? rolloutPercentage = null,
    Object? variantDistribution = null,
    Object? status = null,
  }) {
    return _then(
      _value.copyWith(
            experimentId: null == experimentId
                ? _value.experimentId
                : experimentId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            startDate: null == startDate
                ? _value.startDate
                : startDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            endDate: freezed == endDate
                ? _value.endDate
                : endDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            variants: null == variants
                ? _value.variants
                : variants // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            controlVariant: null == controlVariant
                ? _value.controlVariant
                : controlVariant // ignore: cast_nullable_to_non_nullable
                      as String,
            rolloutPercentage: null == rolloutPercentage
                ? _value.rolloutPercentage
                : rolloutPercentage // ignore: cast_nullable_to_non_nullable
                      as int,
            variantDistribution: null == variantDistribution
                ? _value.variantDistribution
                : variantDistribution // ignore: cast_nullable_to_non_nullable
                      as Map<String, int>,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as ABTestStatus,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ABTestExperimentImplCopyWith<$Res>
    implements $ABTestExperimentCopyWith<$Res> {
  factory _$$ABTestExperimentImplCopyWith(
    _$ABTestExperimentImpl value,
    $Res Function(_$ABTestExperimentImpl) then,
  ) = __$$ABTestExperimentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String experimentId,
    String name,
    String description,
    DateTime startDate,
    DateTime? endDate,
    List<String> variants,
    String controlVariant,
    int rolloutPercentage,
    Map<String, int> variantDistribution,
    ABTestStatus status,
  });
}

/// @nodoc
class __$$ABTestExperimentImplCopyWithImpl<$Res>
    extends _$ABTestExperimentCopyWithImpl<$Res, _$ABTestExperimentImpl>
    implements _$$ABTestExperimentImplCopyWith<$Res> {
  __$$ABTestExperimentImplCopyWithImpl(
    _$ABTestExperimentImpl _value,
    $Res Function(_$ABTestExperimentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ABTestExperiment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? experimentId = null,
    Object? name = null,
    Object? description = null,
    Object? startDate = null,
    Object? endDate = freezed,
    Object? variants = null,
    Object? controlVariant = null,
    Object? rolloutPercentage = null,
    Object? variantDistribution = null,
    Object? status = null,
  }) {
    return _then(
      _$ABTestExperimentImpl(
        experimentId: null == experimentId
            ? _value.experimentId
            : experimentId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        startDate: null == startDate
            ? _value.startDate
            : startDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        endDate: freezed == endDate
            ? _value.endDate
            : endDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        variants: null == variants
            ? _value._variants
            : variants // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        controlVariant: null == controlVariant
            ? _value.controlVariant
            : controlVariant // ignore: cast_nullable_to_non_nullable
                  as String,
        rolloutPercentage: null == rolloutPercentage
            ? _value.rolloutPercentage
            : rolloutPercentage // ignore: cast_nullable_to_non_nullable
                  as int,
        variantDistribution: null == variantDistribution
            ? _value._variantDistribution
            : variantDistribution // ignore: cast_nullable_to_non_nullable
                  as Map<String, int>,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as ABTestStatus,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ABTestExperimentImpl implements _ABTestExperiment {
  const _$ABTestExperimentImpl({
    required this.experimentId,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    required final List<String> variants,
    required this.controlVariant,
    required this.rolloutPercentage,
    required final Map<String, int> variantDistribution,
    this.status = ABTestStatus.active,
  }) : _variants = variants,
       _variantDistribution = variantDistribution;

  factory _$ABTestExperimentImpl.fromJson(Map<String, dynamic> json) =>
      _$$ABTestExperimentImplFromJson(json);

  @override
  final String experimentId;
  @override
  final String name;
  @override
  final String description;
  @override
  final DateTime startDate;
  @override
  final DateTime? endDate;
  final List<String> _variants;
  @override
  List<String> get variants {
    if (_variants is EqualUnmodifiableListView) return _variants;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_variants);
  }

  @override
  final String controlVariant;
  @override
  final int rolloutPercentage;
  final Map<String, int> _variantDistribution;
  @override
  Map<String, int> get variantDistribution {
    if (_variantDistribution is EqualUnmodifiableMapView)
      return _variantDistribution;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_variantDistribution);
  }

  // variantName -> percentage
  @override
  @JsonKey()
  final ABTestStatus status;

  @override
  String toString() {
    return 'ABTestExperiment(experimentId: $experimentId, name: $name, description: $description, startDate: $startDate, endDate: $endDate, variants: $variants, controlVariant: $controlVariant, rolloutPercentage: $rolloutPercentage, variantDistribution: $variantDistribution, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ABTestExperimentImpl &&
            (identical(other.experimentId, experimentId) ||
                other.experimentId == experimentId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            const DeepCollectionEquality().equals(other._variants, _variants) &&
            (identical(other.controlVariant, controlVariant) ||
                other.controlVariant == controlVariant) &&
            (identical(other.rolloutPercentage, rolloutPercentage) ||
                other.rolloutPercentage == rolloutPercentage) &&
            const DeepCollectionEquality().equals(
              other._variantDistribution,
              _variantDistribution,
            ) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    experimentId,
    name,
    description,
    startDate,
    endDate,
    const DeepCollectionEquality().hash(_variants),
    controlVariant,
    rolloutPercentage,
    const DeepCollectionEquality().hash(_variantDistribution),
    status,
  );

  /// Create a copy of ABTestExperiment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ABTestExperimentImplCopyWith<_$ABTestExperimentImpl> get copyWith =>
      __$$ABTestExperimentImplCopyWithImpl<_$ABTestExperimentImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ABTestExperimentImplToJson(this);
  }
}

abstract class _ABTestExperiment implements ABTestExperiment {
  const factory _ABTestExperiment({
    required final String experimentId,
    required final String name,
    required final String description,
    required final DateTime startDate,
    required final DateTime? endDate,
    required final List<String> variants,
    required final String controlVariant,
    required final int rolloutPercentage,
    required final Map<String, int> variantDistribution,
    final ABTestStatus status,
  }) = _$ABTestExperimentImpl;

  factory _ABTestExperiment.fromJson(Map<String, dynamic> json) =
      _$ABTestExperimentImpl.fromJson;

  @override
  String get experimentId;
  @override
  String get name;
  @override
  String get description;
  @override
  DateTime get startDate;
  @override
  DateTime? get endDate;
  @override
  List<String> get variants;
  @override
  String get controlVariant;
  @override
  int get rolloutPercentage;
  @override
  Map<String, int> get variantDistribution; // variantName -> percentage
  @override
  ABTestStatus get status;

  /// Create a copy of ABTestExperiment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ABTestExperimentImplCopyWith<_$ABTestExperimentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ABTestResults _$ABTestResultsFromJson(Map<String, dynamic> json) {
  return _ABTestResults.fromJson(json);
}

/// @nodoc
mixin _$ABTestResults {
  String get experimentId => throw _privateConstructorUsedError;
  String get variantName => throw _privateConstructorUsedError;
  int get sampleSize => throw _privateConstructorUsedError;
  double get conversionRate => throw _privateConstructorUsedError;
  double get engagementRate => throw _privateConstructorUsedError;
  double get retentionRate => throw _privateConstructorUsedError;
  String? get statisticalSignificance => throw _privateConstructorUsedError;

  /// Serializes this ABTestResults to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ABTestResults
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ABTestResultsCopyWith<ABTestResults> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ABTestResultsCopyWith<$Res> {
  factory $ABTestResultsCopyWith(
    ABTestResults value,
    $Res Function(ABTestResults) then,
  ) = _$ABTestResultsCopyWithImpl<$Res, ABTestResults>;
  @useResult
  $Res call({
    String experimentId,
    String variantName,
    int sampleSize,
    double conversionRate,
    double engagementRate,
    double retentionRate,
    String? statisticalSignificance,
  });
}

/// @nodoc
class _$ABTestResultsCopyWithImpl<$Res, $Val extends ABTestResults>
    implements $ABTestResultsCopyWith<$Res> {
  _$ABTestResultsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ABTestResults
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? experimentId = null,
    Object? variantName = null,
    Object? sampleSize = null,
    Object? conversionRate = null,
    Object? engagementRate = null,
    Object? retentionRate = null,
    Object? statisticalSignificance = freezed,
  }) {
    return _then(
      _value.copyWith(
            experimentId: null == experimentId
                ? _value.experimentId
                : experimentId // ignore: cast_nullable_to_non_nullable
                      as String,
            variantName: null == variantName
                ? _value.variantName
                : variantName // ignore: cast_nullable_to_non_nullable
                      as String,
            sampleSize: null == sampleSize
                ? _value.sampleSize
                : sampleSize // ignore: cast_nullable_to_non_nullable
                      as int,
            conversionRate: null == conversionRate
                ? _value.conversionRate
                : conversionRate // ignore: cast_nullable_to_non_nullable
                      as double,
            engagementRate: null == engagementRate
                ? _value.engagementRate
                : engagementRate // ignore: cast_nullable_to_non_nullable
                      as double,
            retentionRate: null == retentionRate
                ? _value.retentionRate
                : retentionRate // ignore: cast_nullable_to_non_nullable
                      as double,
            statisticalSignificance: freezed == statisticalSignificance
                ? _value.statisticalSignificance
                : statisticalSignificance // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ABTestResultsImplCopyWith<$Res>
    implements $ABTestResultsCopyWith<$Res> {
  factory _$$ABTestResultsImplCopyWith(
    _$ABTestResultsImpl value,
    $Res Function(_$ABTestResultsImpl) then,
  ) = __$$ABTestResultsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String experimentId,
    String variantName,
    int sampleSize,
    double conversionRate,
    double engagementRate,
    double retentionRate,
    String? statisticalSignificance,
  });
}

/// @nodoc
class __$$ABTestResultsImplCopyWithImpl<$Res>
    extends _$ABTestResultsCopyWithImpl<$Res, _$ABTestResultsImpl>
    implements _$$ABTestResultsImplCopyWith<$Res> {
  __$$ABTestResultsImplCopyWithImpl(
    _$ABTestResultsImpl _value,
    $Res Function(_$ABTestResultsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ABTestResults
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? experimentId = null,
    Object? variantName = null,
    Object? sampleSize = null,
    Object? conversionRate = null,
    Object? engagementRate = null,
    Object? retentionRate = null,
    Object? statisticalSignificance = freezed,
  }) {
    return _then(
      _$ABTestResultsImpl(
        experimentId: null == experimentId
            ? _value.experimentId
            : experimentId // ignore: cast_nullable_to_non_nullable
                  as String,
        variantName: null == variantName
            ? _value.variantName
            : variantName // ignore: cast_nullable_to_non_nullable
                  as String,
        sampleSize: null == sampleSize
            ? _value.sampleSize
            : sampleSize // ignore: cast_nullable_to_non_nullable
                  as int,
        conversionRate: null == conversionRate
            ? _value.conversionRate
            : conversionRate // ignore: cast_nullable_to_non_nullable
                  as double,
        engagementRate: null == engagementRate
            ? _value.engagementRate
            : engagementRate // ignore: cast_nullable_to_non_nullable
                  as double,
        retentionRate: null == retentionRate
            ? _value.retentionRate
            : retentionRate // ignore: cast_nullable_to_non_nullable
                  as double,
        statisticalSignificance: freezed == statisticalSignificance
            ? _value.statisticalSignificance
            : statisticalSignificance // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ABTestResultsImpl implements _ABTestResults {
  const _$ABTestResultsImpl({
    required this.experimentId,
    required this.variantName,
    required this.sampleSize,
    required this.conversionRate,
    required this.engagementRate,
    required this.retentionRate,
    required this.statisticalSignificance,
  });

  factory _$ABTestResultsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ABTestResultsImplFromJson(json);

  @override
  final String experimentId;
  @override
  final String variantName;
  @override
  final int sampleSize;
  @override
  final double conversionRate;
  @override
  final double engagementRate;
  @override
  final double retentionRate;
  @override
  final String? statisticalSignificance;

  @override
  String toString() {
    return 'ABTestResults(experimentId: $experimentId, variantName: $variantName, sampleSize: $sampleSize, conversionRate: $conversionRate, engagementRate: $engagementRate, retentionRate: $retentionRate, statisticalSignificance: $statisticalSignificance)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ABTestResultsImpl &&
            (identical(other.experimentId, experimentId) ||
                other.experimentId == experimentId) &&
            (identical(other.variantName, variantName) ||
                other.variantName == variantName) &&
            (identical(other.sampleSize, sampleSize) ||
                other.sampleSize == sampleSize) &&
            (identical(other.conversionRate, conversionRate) ||
                other.conversionRate == conversionRate) &&
            (identical(other.engagementRate, engagementRate) ||
                other.engagementRate == engagementRate) &&
            (identical(other.retentionRate, retentionRate) ||
                other.retentionRate == retentionRate) &&
            (identical(
                  other.statisticalSignificance,
                  statisticalSignificance,
                ) ||
                other.statisticalSignificance == statisticalSignificance));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    experimentId,
    variantName,
    sampleSize,
    conversionRate,
    engagementRate,
    retentionRate,
    statisticalSignificance,
  );

  /// Create a copy of ABTestResults
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ABTestResultsImplCopyWith<_$ABTestResultsImpl> get copyWith =>
      __$$ABTestResultsImplCopyWithImpl<_$ABTestResultsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ABTestResultsImplToJson(this);
  }
}

abstract class _ABTestResults implements ABTestResults {
  const factory _ABTestResults({
    required final String experimentId,
    required final String variantName,
    required final int sampleSize,
    required final double conversionRate,
    required final double engagementRate,
    required final double retentionRate,
    required final String? statisticalSignificance,
  }) = _$ABTestResultsImpl;

  factory _ABTestResults.fromJson(Map<String, dynamic> json) =
      _$ABTestResultsImpl.fromJson;

  @override
  String get experimentId;
  @override
  String get variantName;
  @override
  int get sampleSize;
  @override
  double get conversionRate;
  @override
  double get engagementRate;
  @override
  double get retentionRate;
  @override
  String? get statisticalSignificance;

  /// Create a copy of ABTestResults
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ABTestResultsImplCopyWith<_$ABTestResultsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CohortAssignment _$CohortAssignmentFromJson(Map<String, dynamic> json) {
  return _CohortAssignment.fromJson(json);
}

/// @nodoc
mixin _$CohortAssignment {
  String get userId => throw _privateConstructorUsedError;
  String get cohortName => throw _privateConstructorUsedError;
  DateTime get assignedAt => throw _privateConstructorUsedError;
  Map<String, String> get experimentVariants =>
      throw _privateConstructorUsedError;

  /// Serializes this CohortAssignment to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CohortAssignment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CohortAssignmentCopyWith<CohortAssignment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CohortAssignmentCopyWith<$Res> {
  factory $CohortAssignmentCopyWith(
    CohortAssignment value,
    $Res Function(CohortAssignment) then,
  ) = _$CohortAssignmentCopyWithImpl<$Res, CohortAssignment>;
  @useResult
  $Res call({
    String userId,
    String cohortName,
    DateTime assignedAt,
    Map<String, String> experimentVariants,
  });
}

/// @nodoc
class _$CohortAssignmentCopyWithImpl<$Res, $Val extends CohortAssignment>
    implements $CohortAssignmentCopyWith<$Res> {
  _$CohortAssignmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CohortAssignment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? cohortName = null,
    Object? assignedAt = null,
    Object? experimentVariants = null,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            cohortName: null == cohortName
                ? _value.cohortName
                : cohortName // ignore: cast_nullable_to_non_nullable
                      as String,
            assignedAt: null == assignedAt
                ? _value.assignedAt
                : assignedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            experimentVariants: null == experimentVariants
                ? _value.experimentVariants
                : experimentVariants // ignore: cast_nullable_to_non_nullable
                      as Map<String, String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CohortAssignmentImplCopyWith<$Res>
    implements $CohortAssignmentCopyWith<$Res> {
  factory _$$CohortAssignmentImplCopyWith(
    _$CohortAssignmentImpl value,
    $Res Function(_$CohortAssignmentImpl) then,
  ) = __$$CohortAssignmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    String cohortName,
    DateTime assignedAt,
    Map<String, String> experimentVariants,
  });
}

/// @nodoc
class __$$CohortAssignmentImplCopyWithImpl<$Res>
    extends _$CohortAssignmentCopyWithImpl<$Res, _$CohortAssignmentImpl>
    implements _$$CohortAssignmentImplCopyWith<$Res> {
  __$$CohortAssignmentImplCopyWithImpl(
    _$CohortAssignmentImpl _value,
    $Res Function(_$CohortAssignmentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CohortAssignment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? cohortName = null,
    Object? assignedAt = null,
    Object? experimentVariants = null,
  }) {
    return _then(
      _$CohortAssignmentImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        cohortName: null == cohortName
            ? _value.cohortName
            : cohortName // ignore: cast_nullable_to_non_nullable
                  as String,
        assignedAt: null == assignedAt
            ? _value.assignedAt
            : assignedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        experimentVariants: null == experimentVariants
            ? _value._experimentVariants
            : experimentVariants // ignore: cast_nullable_to_non_nullable
                  as Map<String, String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CohortAssignmentImpl implements _CohortAssignment {
  const _$CohortAssignmentImpl({
    required this.userId,
    required this.cohortName,
    required this.assignedAt,
    required final Map<String, String> experimentVariants,
  }) : _experimentVariants = experimentVariants;

  factory _$CohortAssignmentImpl.fromJson(Map<String, dynamic> json) =>
      _$$CohortAssignmentImplFromJson(json);

  @override
  final String userId;
  @override
  final String cohortName;
  @override
  final DateTime assignedAt;
  final Map<String, String> _experimentVariants;
  @override
  Map<String, String> get experimentVariants {
    if (_experimentVariants is EqualUnmodifiableMapView)
      return _experimentVariants;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_experimentVariants);
  }

  @override
  String toString() {
    return 'CohortAssignment(userId: $userId, cohortName: $cohortName, assignedAt: $assignedAt, experimentVariants: $experimentVariants)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CohortAssignmentImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.cohortName, cohortName) ||
                other.cohortName == cohortName) &&
            (identical(other.assignedAt, assignedAt) ||
                other.assignedAt == assignedAt) &&
            const DeepCollectionEquality().equals(
              other._experimentVariants,
              _experimentVariants,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    userId,
    cohortName,
    assignedAt,
    const DeepCollectionEquality().hash(_experimentVariants),
  );

  /// Create a copy of CohortAssignment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CohortAssignmentImplCopyWith<_$CohortAssignmentImpl> get copyWith =>
      __$$CohortAssignmentImplCopyWithImpl<_$CohortAssignmentImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CohortAssignmentImplToJson(this);
  }
}

abstract class _CohortAssignment implements CohortAssignment {
  const factory _CohortAssignment({
    required final String userId,
    required final String cohortName,
    required final DateTime assignedAt,
    required final Map<String, String> experimentVariants,
  }) = _$CohortAssignmentImpl;

  factory _CohortAssignment.fromJson(Map<String, dynamic> json) =
      _$CohortAssignmentImpl.fromJson;

  @override
  String get userId;
  @override
  String get cohortName;
  @override
  DateTime get assignedAt;
  @override
  Map<String, String> get experimentVariants;

  /// Create a copy of CohortAssignment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CohortAssignmentImplCopyWith<_$CohortAssignmentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
