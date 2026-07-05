class ReplaySummary {
  final String mvpUserId;
  final int topKills;
  final int totalScore;
  final String? keyMoment;

  ReplaySummary({
    required this.mvpUserId,
    required this.topKills,
    required this.totalScore,
    this.keyMoment,
  });

  factory ReplaySummary.fromJson(Map<String, dynamic> json) {
    return ReplaySummary(
      mvpUserId: json['mvpUserId'] as String,
      topKills: json['topKills'] as int? ?? 0,
      totalScore: json['totalScore'] as int? ?? 0,
      keyMoment: json['keyMoment'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'mvpUserId': mvpUserId,
    'topKills': topKills,
    'totalScore': totalScore,
    'keyMoment': keyMoment,
  };
}

class Replay {
  final String replayId;
  final String battleId;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String shareUrl;
  final ReplaySummary summary;
  final DateTime createdAt;

  Replay({
    required this.replayId,
    required this.battleId,
    this.videoUrl,
    this.thumbnailUrl,
    required this.shareUrl,
    required this.summary,
    required this.createdAt,
  });

  factory Replay.fromJson(Map<String, dynamic> json) {
    return Replay(
      replayId: json['replayId'] as String,
      battleId: json['battleId'] as String,
      videoUrl: json['videoUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      shareUrl: json['shareUrl'] as String,
      summary: json['summary'] != null
          ? ReplaySummary.fromJson(json['summary'] as Map<String, dynamic>)
          : ReplaySummary(mvpUserId: '', topKills: 0, totalScore: 0),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'replayId': replayId,
    'battleId': battleId,
    'videoUrl': videoUrl,
    'thumbnailUrl': thumbnailUrl,
    'shareUrl': shareUrl,
    'summary': summary.toJson(),
    'createdAt': createdAt.toIso8601String(),
  };
}
