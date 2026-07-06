import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/data/models/guild_model.dart';
import 'package:shinjuu_league/data/models/user_model.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';
import 'package:shinjuu_league/ui/widgets/custom_button.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('フレンド・ギルド'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'フレンド'),
              Tab(text: 'ギルド'),
            ],
          ),
        ),
        body: const TabBarView(children: [_FriendsTab(), _GuildTab()]),
      ),
    );
  }
}

class _FriendsTab extends ConsumerStatefulWidget {
  const _FriendsTab();

  @override
  ConsumerState<_FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends ConsumerState<_FriendsTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest(String selfName, String toUserId) async {
    try {
      await ref
          .read(friendViewModelProvider.notifier)
          .sendFriendRequest(selfName, toUserId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('申請に失敗しました: $e')));
    }
  }

  Future<void> _respond(String requestId, bool accept) async {
    try {
      await ref
          .read(friendViewModelProvider.notifier)
          .respondToRequest(requestId, accept);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('処理に失敗しました: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userViewModelProvider).value;
    final friendState = ref.watch(friendViewModelProvider);

    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'ユーザー名で検索',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (query) => ref
                    .read(friendViewModelProvider.notifier)
                    .searchUsers(query),
              ),
            ),
          ],
        ),
        if (friendState.isSearching)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (friendState.searchResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('検索結果', style: TextStyle(fontWeight: FontWeight.bold)),
          ...friendState.searchResults.map(
            (user) => ListTile(
              leading: const Icon(Icons.person),
              title: Text(user.name),
              trailing: TextButton(
                onPressed: () => _sendRequest(currentUser.name, user.uid),
                child: const Text('申請'),
              ),
            ),
          ),
        ],
        if (friendState.incomingRequests.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('届いた申請', style: TextStyle(fontWeight: FontWeight.bold)),
          ...friendState.incomingRequests.map(
            (req) => ListTile(
              leading: const Icon(Icons.person_add),
              title: Text(req.fromUserName),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => _respond(req.requestId, true),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => _respond(req.requestId, false),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        const Text('フレンド一覧', style: TextStyle(fontWeight: FontWeight.bold)),
        if (friendState.friends.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('まだフレンドがいません', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ...friendState.friends.map(
            (friend) => ListTile(
              leading: const Icon(Icons.person),
              title: Text(friend.name),
              subtitle: Text('Elo ${friend.eloRating.toStringAsFixed(0)}'),
            ),
          ),
      ],
    );
  }
}

class _GuildTab extends ConsumerStatefulWidget {
  const _GuildTab();

  @override
  ConsumerState<_GuildTab> createState() => _GuildTabState();
}

class _GuildTabState extends ConsumerState<_GuildTab> {
  final _nameController = TextEditingController();
  final _postController = TextEditingController();
  bool _watchStarted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _postController.dispose();
    super.dispose();
  }

  void _ensureWatching(User user) {
    if (_watchStarted || user.guildId == null) return;
    _watchStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(guildViewModelProvider.notifier).watchGuild(user.guildId!);
    });
  }

  Future<void> _createGuild(User user) async {
    if (_nameController.text.trim().isEmpty) return;
    try {
      await ref
          .read(guildViewModelProvider.notifier)
          .createGuild(
            name: _nameController.text.trim(),
            ownerId: user.uid,
            maxMembers: 30,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ギルド作成に失敗しました: $e')));
    }
  }

  Future<void> _leaveGuild(String guildId, String userId) async {
    try {
      await ref
          .read(guildViewModelProvider.notifier)
          .leaveGuild(guildId, userId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('脱退に失敗しました: $e')));
    }
  }

  Future<void> _postMessage(
    String authorId,
    String authorName,
    String message,
  ) async {
    try {
      await ref
          .read(guildViewModelProvider.notifier)
          .postMessage(
            authorId: authorId,
            authorName: authorName,
            message: message,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('投稿に失敗しました: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userViewModelProvider).value;
    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    _ensureWatching(currentUser);
    final guildState = ref.watch(guildViewModelProvider);

    if (currentUser.guildId == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.groups_2, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('まだギルドに所属していません', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'ギルド名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            CustomButton(
              label: 'ギルドを作成',
              icon: Icons.add,
              isLoading: guildState.isLoading,
              onPressed: () => _createGuild(currentUser),
            ),
          ],
        ),
      );
    }

    final guild = guildState.guild;
    if (guild == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: ListTile(
            leading: const Icon(Icons.groups_2),
            title: Text(guild.name),
            subtitle: Text(
              'メンバー ${guild.memberIds.length}/${guild.maxMembers}',
            ),
            trailing: TextButton(
              onPressed: () => _leaveGuild(guild.guildId, currentUser.uid),
              child: const Text('脱退'),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: guildState.posts.length,
            itemBuilder: (context, i) {
              final post = guildState.posts[i];
              return _GuildPostTile(post: post);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _postController,
                  decoration: const InputDecoration(
                    hintText: '掲示板に投稿',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  _postMessage(
                    currentUser.uid,
                    currentUser.name,
                    _postController.text,
                  );
                  _postController.clear();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuildPostTile extends StatelessWidget {
  const _GuildPostTile({required this.post});
  final GuildPost post;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.authorName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(post.message),
        ],
      ),
    );
  }
}
