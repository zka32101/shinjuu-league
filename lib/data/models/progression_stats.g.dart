// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progression_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SeasonStatsImpl _$$SeasonStatsImplFromJson(Map<String, dynamic> json) =>
    _$SeasonStatsImpl(
      seasonId: json['seasonId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
      finalTier: json['finalTier'] as String,
      maxTierReached: json['maxTierReached'] as String,
      pointsAllocated: (json['pointsAllocated'] as num).toInt(),
      totalGamesPlayed: (json['totalGamesPlayed'] as num).toInt(),
      gamesWon: (json['gamesWon'] as num).toInt(),
      gamesLost: (json['gamesLost'] as num).toInt(),
      totalPlayTime: Duration(
        microseconds: (json['totalPlayTime'] as num).toInt(),
      ),
      winRate: (json['winRate'] as num).toDouble(),
      eloProgression: (json['eloProgression'] as List<dynamic>)
          .map((e) => EloSnapshot.fromJson(e as Map<String, dynamic>))
          .toList(),
      seasonRewards: (json['seasonRewards'] as num).toInt(),
    );

Map<String, dynamic> _$$SeasonStatsImplToJson(_$SeasonStatsImpl instance) =>
    <String, dynamic>{
      'seasonId': instance.seasonId,
      'startedAt': instance.startedAt.toIso8601String(),
      'endedAt': instance.endedAt?.toIso8601String(),
      'finalTier': instance.finalTier,
      'maxTierReached': instance.maxTierReached,
      'pointsAllocated': instance.pointsAllocated,
      'totalGamesPlayed': instance.totalGamesPlayed,
      'gamesWon': instance.gamesWon,
      'gamesLost': instance.gamesLost,
      'totalPlayTime': instance.totalPlayTime.inMicroseconds,
      'winRate': instance.winRate,
      'eloProgression': instance.eloProgression,
      'seasonRewards': instance.seasonRewards,
    };

_$EloSnapshotImpl _$$EloSnapshotImplFromJson(Map<String, dynamic> json) =>
    _$EloSnapshotImpl(
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      rating: (json['rating'] as num).toDouble(),
      gamesPlayed: (json['gamesPlayed'] as num).toInt(),
    );

Map<String, dynamic> _$$EloSnapshotImplToJson(_$EloSnapshotImpl instance) =>
    <String, dynamic>{
      'recordedAt': instance.recordedAt.toIso8601String(),
      'rating': instance.rating,
      'gamesPlayed': instance.gamesPlayed,
    };

_$AggregateStatsImpl _$$AggregateStatsImplFromJson(Map<String, dynamic> json) =>
    _$AggregateStatsImpl(
      totalSeasonsPlayed: (json['totalSeasonsPlayed'] as num).toInt(),
      favoriteTree: json['favoriteTree'] as String,
      averageTier: json['averageTier'] as String,
      highestTierEver: json['highestTierEver'] as String,
      totalGamesPlayed: (json['totalGamesPlayed'] as num).toInt(),
      totalGamesWon: (json['totalGamesWon'] as num).toInt(),
      careerWinRate: (json['careerWinRate'] as num).toDouble(),
      totalRewardsClaimed: Map<String, int>.from(
        json['totalRewardsClaimed'] as Map,
      ),
      progression: ProgressionTrend.fromJson(
        json['progression'] as Map<String, dynamic>,
      ),
      firstSeasonAt: DateTime.parse(json['firstSeasonAt'] as String),
      lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
    );

Map<String, dynamic> _$$AggregateStatsImplToJson(
  _$AggregateStatsImpl instance,
) => <String, dynamic>{
  'totalSeasonsPlayed': instance.totalSeasonsPlayed,
  'favoriteTree': instance.favoriteTree,
  'averageTier': instance.averageTier,
  'highestTierEver': instance.highestTierEver,
  'totalGamesPlayed': instance.totalGamesPlayed,
  'totalGamesWon': instance.totalGamesWon,
  'careerWinRate': instance.careerWinRate,
  'totalRewardsClaimed': instance.totalRewardsClaimed,
  'progression': instance.progression,
  'firstSeasonAt': instance.firstSeasonAt.toIso8601String(),
  'lastUpdatedAt': instance.lastUpdatedAt.toIso8601String(),
};

_$ProgressionTrendImpl _$$ProgressionTrendImplFromJson(
  Map<String, dynamic> json,
) => _$ProgressionTrendImpl(
  seasonOverSeason: (json['seasonOverSeason'] as num).toDouble(),
  winRateTrend: (json['winRateTrend'] as num).toDouble(),
  eloTrend: (json['eloTrend'] as num).toDouble(),
  prediction: $enumDecode(_$ProgressionTrendTypeEnumMap, json['prediction']),
  dataPointsUsed: (json['dataPointsUsed'] as num).toInt(),
);

Map<String, dynamic> _$$ProgressionTrendImplToJson(
  _$ProgressionTrendImpl instance,
) => <String, dynamic>{
  'seasonOverSeason': instance.seasonOverSeason,
  'winRateTrend': instance.winRateTrend,
  'eloTrend': instance.eloTrend,
  'prediction': _$ProgressionTrendTypeEnumMap[instance.prediction]!,
  'dataPointsUsed': instance.dataPointsUsed,
};

const _$ProgressionTrendTypeEnumMap = {
  ProgressionTrendType.climbing: 'climbing',
  ProgressionTrendType.plateau: 'plateau',
  ProgressionTrendType.declining: 'declining',
};

_$ProgressionStatsImpl _$$ProgressionStatsImplFromJson(
  Map<String, dynamic> json,
) => _$ProgressionStatsImpl(
  userId: json['userId'] as String,
  currentSeason: json['currentSeason'] == null
      ? null
      : SeasonStats.fromJson(json['currentSeason'] as Map<String, dynamic>),
  allSeasons: (json['allSeasons'] as List<dynamic>)
      .map((e) => SeasonStats.fromJson(e as Map<String, dynamic>))
      .toList(),
  allTimeStats: AggregateStats.fromJson(
    json['allTimeStats'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$$ProgressionStatsImplToJson(
  _$ProgressionStatsImpl instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'currentSeason': instance.currentSeason,
  'allSeasons': instance.allSeasons,
  'allTimeStats': instance.allTimeStats,
};
