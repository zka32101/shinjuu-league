import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/data/models/friend_model.dart';
import 'package:shinjuu_league/data/models/user_model.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

class FriendState {
  const FriendState({
    required this.incomingRequests,
    required this.friends,
    required this.searchResults,
    required this.isSearching,
    required this.error,
  });

  factory FriendState.initial() => const FriendState(
    incomingRequests: [],
    friends: [],
    searchResults: [],
    isSearching: false,
    error: null,
  );

  final List<FriendRequest> incomingRequests;
  final List<User> friends;
  final List<User> searchResults;
  final bool isSearching;
  final String? error;

  FriendState copyWith({
    List<FriendRequest>? incomingRequests,
    List<User>? friends,
    List<User>? searchResults,
    bool? isSearching,
    String? error,
  }) {
    return FriendState(
      incomingRequests: incomingRequests ?? this.incomingRequests,
      friends: friends ?? this.friends,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      error: error,
    );
  }
}

class FriendViewModel extends StateNotifier<FriendState> {
  FriendViewModel({required this.selfUserId, FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService(),
      super(FriendState.initial()) {
    _init();
  }

  final String selfUserId;
  final FirestoreService _firestoreService;
  StreamSubscription<List<FriendRequest>>? _incomingSub;
  StreamSubscription<List<FriendRequest>>? _friendshipsSub;

  void _init() {
    _incomingSub = _firestoreService.watchIncomingRequests(selfUserId).listen((requests) {
      state = state.copyWith(incomingRequests: requests);
    });

    _friendshipsSub = _firestoreService.watchFriendships(selfUserId).listen((friendships) async {
      final friendUserIds = friendships.map((f) => f.otherUserId(selfUserId)).toList();
      final friends = await Future.wait(friendUserIds.map((id) => _firestoreService.getUserById(id)));
      state = state.copyWith(friends: friends.whereType<User>().toList());
    });
  }

  Future<void> searchUsers(String query) async {
    state = state.copyWith(isSearching: true, error: null);
    try {
      final results = await _firestoreService.searchUsersByName(query);
      state = state.copyWith(isSearching: false, searchResults: results.where((u) => u.uid != selfUserId).toList());
    } catch (e) {
      state = state.copyWith(isSearching: false, error: '$e');
    }
  }

  Future<void> sendFriendRequest(String selfUserName, String toUserId) async {
    await _firestoreService.sendFriendRequest(
      fromUserId: selfUserId,
      fromUserName: selfUserName,
      toUserId: toUserId,
    );
  }

  Future<void> respondToRequest(String requestId, bool accept) async {
    await _firestoreService.respondToFriendRequest(requestId, accept);
  }

  @override
  void dispose() {
    _incomingSub?.cancel();
    _friendshipsSub?.cancel();
    super.dispose();
  }
}
