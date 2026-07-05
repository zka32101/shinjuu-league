import 'package:flutter/material.dart';

/// フレンド・ギルドのバックエンド実装は Step 12（今後実装予定）。
/// ここでは画面遷移フローを完結させるためのプレースホルダーUIのみ用意する。
class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('フレンド・ギルド'),
          bottom: const TabBar(tabs: [Tab(text: 'フレンド'), Tab(text: 'ギルド')]),
        ),
        body: const TabBarView(
          children: [
            _EmptyState(icon: Icons.person_add, message: 'フレンド機能は近日公開予定です'),
            _EmptyState(icon: Icons.groups_2, message: 'ギルド機能は近日公開予定です'),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
