enum FriendRequestStatus {
  pending,
  accepted,
  rejected;

  String get displayName {
    switch (this) {
      case FriendRequestStatus.pending:
        return '申請中';
      case FriendRequestStatus.accepted:
        return 'フレンド';
      case FriendRequestStatus.rejected:
        return '拒否済み';
      default:
        return 'Unknown';
    }
  }
}

class FriendRequest {
  final String requestId;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final FriendRequestStatus status;
  final DateTime createdAt;

  FriendRequest({
    required this.requestId,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.status,
    required this.createdAt,
  });

  String otherUserId(String selfUserId) =>
      fromUserId == selfUserId ? toUserId : fromUserId;

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      requestId: json['requestId'] as String,
      fromUserId: json['fromUserId'] as String,
      fromUserName: json['fromUserName'] as String? ?? '',
      toUserId: json['toUserId'] as String,
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'pending'),
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'requestId': requestId,
    'fromUserId': fromUserId,
    'fromUserName': fromUserName,
    'toUserId': toUserId,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
  };
}
