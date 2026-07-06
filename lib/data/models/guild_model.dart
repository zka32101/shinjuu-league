class Guild {
  final String guildId;
  final String name;
  final String ownerId;
  final List<String> memberIds;
  final int maxMembers;
  final DateTime createdAt;

  Guild({
    required this.guildId,
    required this.name,
    required this.ownerId,
    required this.memberIds,
    required this.maxMembers,
    required this.createdAt,
  });

  bool get isFull => memberIds.length >= maxMembers;

  factory Guild.fromJson(Map<String, dynamic> json) {
    return Guild(
      guildId: json['guildId'] as String,
      name: json['name'] as String,
      ownerId: json['ownerId'] as String,
      memberIds: List<String>.from(json['memberIds'] as List<dynamic>? ?? []),
      maxMembers: json['maxMembers'] as int? ?? 30,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'guildId': guildId,
    'name': name,
    'ownerId': ownerId,
    'memberIds': memberIds,
    'maxMembers': maxMembers,
    'createdAt': createdAt.toIso8601String(),
  };
}

class GuildPost {
  final String postId;
  final String authorId;
  final String authorName;
  final String message;
  final DateTime createdAt;

  GuildPost({
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.message,
    required this.createdAt,
  });

  factory GuildPost.fromJson(Map<String, dynamic> json) {
    return GuildPost(
      postId: json['postId'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'postId': postId,
    'authorId': authorId,
    'authorName': authorName,
    'message': message,
    'createdAt': createdAt.toIso8601String(),
  };
}
