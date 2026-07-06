import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/data/models/guild_model.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

class GuildState {
  const GuildState({
    required this.guild,
    required this.posts,
    required this.isLoading,
    required this.error,
  });

  factory GuildState.initial() =>
      const GuildState(guild: null, posts: [], isLoading: false, error: null);

  final Guild? guild;
  final List<GuildPost> posts;
  final bool isLoading;
  final String? error;

  GuildState copyWith({
    Guild? guild,
    List<GuildPost>? posts,
    bool? isLoading,
    String? error,
  }) {
    return GuildState(
      guild: guild ?? this.guild,
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class GuildViewModel extends StateNotifier<GuildState> {
  GuildViewModel({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService(),
      super(GuildState.initial());

  final FirestoreService _firestoreService;
  final _uuid = const Uuid();
  StreamSubscription<Guild?>? _guildSub;
  StreamSubscription<List<GuildPost>>? _postsSub;

  void watchGuild(String guildId) {
    _guildSub?.cancel();
    _postsSub?.cancel();

    _guildSub = _firestoreService.watchGuild(guildId).listen((guild) {
      state = state.copyWith(guild: guild);
    });
    _postsSub = _firestoreService.watchGuildPosts(guildId).listen((posts) {
      state = state.copyWith(posts: posts);
    });
  }

  Future<String> createGuild({
    required String name,
    required String ownerId,
    required int maxMembers,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final guildId = await _firestoreService.createGuild(
        name: name,
        ownerId: ownerId,
        maxMembers: maxMembers,
      );
      await _firestoreService.updateUserGuildId(ownerId, guildId);
      state = state.copyWith(isLoading: false);
      watchGuild(guildId);
      return guildId;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '$e');
      rethrow;
    }
  }

  Future<void> leaveGuild(String guildId, String userId) async {
    await _firestoreService.leaveGuild(guildId, userId);
    await _firestoreService.updateUserGuildId(userId, null);
    _guildSub?.cancel();
    _postsSub?.cancel();
    state = GuildState.initial();
  }

  Future<void> postMessage({
    required String authorId,
    required String authorName,
    required String message,
  }) async {
    final guild = state.guild;
    if (guild == null || message.trim().isEmpty) return;

    final post = GuildPost(
      postId: _uuid.v4(),
      authorId: authorId,
      authorName: authorName,
      message: message.trim(),
      createdAt: DateTime.now(),
    );
    await _firestoreService.postToGuildBoard(guild.guildId, post);
  }

  @override
  void dispose() {
    _guildSub?.cancel();
    _postsSub?.cancel();
    super.dispose();
  }
}
