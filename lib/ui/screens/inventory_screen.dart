import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/config/theme.dart';
import 'package:shinjuu_league/data/models/item_model.dart';
import 'package:shinjuu_league/viewmodels/inventory_viewmodel.dart';
import 'package:shinjuu_league/ui/widgets/custom_button.dart';
import 'package:shinjuu_league/ui/widgets/loading_skeleton.dart';

/// ユーザーのアイテムインベントリを表示・管理する画面
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  int _selectedTabIndex = 0; // 0: All, 1: Equipped, 2: By Type

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryViewModelProvider);
    final totalBonusAsync = ref.watch(totalEquippedBonusProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('アイテムインベントリ'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.dark1,
      ),
      body: inventoryAsync.when(
        loading: () => const LoadingSkeleton(),
        error: (error, st) => _buildErrorView(context, error),
        data: (items) => SingleChildScrollView(
          child: Column(
            children: [
              _buildStatsSection(context, items, totalBonusAsync),
              const Divider(height: 32),
              _buildTabBar(context),
              _buildItemsSection(context, items),
            ],
          ),
        ),
      ),
    );
  }

  /// ステータスセクション（装備ボーナス表示）
  Widget _buildStatsSection(
    BuildContext context,
    List<Item> items,
    AsyncValue<ItemBonus> totalBonusAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.dark2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'インベントリ統計',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatChip(
                context,
                'アイテム数',
                '${items.length}',
              ),
              _buildStatChip(
                context,
                '装備中',
                '${items.where((i) => i.isEquipped).length}/3',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '装備ボーナス',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          totalBonusAsync.when(
            data: (bonus) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (bonus.attackBonus != null)
                  Text('⚔️  攻撃力: +${bonus.attackBonus!.toStringAsFixed(1)}%'),
                if (bonus.defenseBonus != null)
                  Text('🛡️  防御力: +${bonus.defenseBonus!.toStringAsFixed(1)}%'),
                if (bonus.hpBonus != null)
                  Text('❤️  体力: +${bonus.hpBonus!.toStringAsFixed(1)}%'),
                if (bonus.attackBonus == null &&
                    bonus.defenseBonus == null &&
                    bonus.hpBonus == null)
                  Text(
                    'ボーナスなし',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('エラー'),
          ),
        ],
      ),
    );
  }

  /// ステータスチップ
  Widget _buildStatChip(
    BuildContext context,
    String label,
    String value,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  /// タブバー
  Widget _buildTabBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTabButton(context, 'すべて', 0),
          const SizedBox(width: 8),
          _buildTabButton(context, '装備中', 1),
          const SizedBox(width: 8),
          _buildTabButton(context, 'タイプ別', 2),
        ],
      ),
    );
  }

  /// タブボタン
  Widget _buildTabButton(
    BuildContext context,
    String label,
    int index,
  ) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.dark2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.dark3,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// アイテムセクション
  Widget _buildItemsSection(
    BuildContext context,
    List<Item> items,
  ) {
    final displayItems = _getDisplayItems(items);

    if (displayItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'アイテムがありません',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: displayItems
            .map((item) => _buildItemCard(context, item))
            .toList(),
      ),
    );
  }

  /// 表示するアイテムのリストを取得
  List<Item> _getDisplayItems(List<Item> items) {
    switch (_selectedTabIndex) {
      case 0: // すべて
        return items;
      case 1: // 装備中
        return items.where((item) => item.isEquipped).toList();
      case 2: // タイプ別
        // weapon, armor, charm の順序で表示
        final weapons = items.where((i) => i.type == ItemType.weapon).toList();
        final armors = items.where((i) => i.type == ItemType.armor).toList();
        final charms = items.where((i) => i.type == ItemType.charm).toList();
        return [...weapons, ...armors, ...charms];
      default:
        return items;
    }
  }

  /// アイテムカード
  Widget _buildItemCard(BuildContext context, Item item) {
    final viewModel = ref.read(inventoryViewModelProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dark2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getRarityColor(item.rarity),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildRarityBadge(item.rarity),
                        const SizedBox(width: 8),
                        _buildTypeBadge(item.type),
                      ],
                    ),
                  ],
                ),
              ),
              if (item.isEquipped)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '装備中',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // 説明
          Text(
            item.description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          // ボーナス表示
          if (item.bonus != null) _buildBonusDisplay(context, item.bonus!),
          const SizedBox(height: 12),
          // アクションボタン
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: item.isEquipped ? '外す' : '装備',
                  onPressed: () async {
                    if (item.isEquipped) {
                      await viewModel.unequipItem(item.itemId);
                    } else {
                      if (viewModel.canEquipItem(item)) {
                        await viewModel.equipItem(item.itemId);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('同じタイプのアイテムは1つだけ装備できます'),
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// レアリティバッジ
  Widget _buildRarityBadge(ItemRarity rarity) {
    final color = _getRarityColor(rarity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        _getRarityLabel(rarity),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  /// タイプバッジ
  Widget _buildTypeBadge(ItemType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.dark3,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.textSecondary, width: 1),
      ),
      child: Text(
        _getTypeLabel(type),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// ボーナス表示
  Widget _buildBonusDisplay(BuildContext context, ItemBonus bonus) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (bonus.attackBonus != null)
          Text(
            '⚔️  攻撃力: +${bonus.attackBonus!.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        if (bonus.defenseBonus != null)
          Text(
            '🛡️  防御力: +${bonus.defenseBonus!.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        if (bonus.hpBonus != null)
          Text(
            '❤️  体力: +${bonus.hpBonus!.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.labelSmall,
          ),
      ],
    );
  }

  /// エラービュー
  Widget _buildErrorView(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('エラーが発生しました'),
          const SizedBox(height: 16),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// レアリティの色を取得
  Color _getRarityColor(ItemRarity rarity) {
    switch (rarity) {
      case ItemRarity.common:
        return Colors.grey;
      case ItemRarity.rare:
        return Colors.blue;
      case ItemRarity.epic:
        return Colors.purple;
      case ItemRarity.legend:
        return Colors.amber;
    }
  }

  /// レアリティのラベルを取得
  String _getRarityLabel(ItemRarity rarity) {
    switch (rarity) {
      case ItemRarity.common:
        return 'コモン';
      case ItemRarity.rare:
        return 'レア';
      case ItemRarity.epic:
        return 'エピック';
      case ItemRarity.legend:
        return 'レジェンダリー';
    }
  }

  /// タイプのラベルを取得
  String _getTypeLabel(ItemType type) {
    switch (type) {
      case ItemType.weapon:
        return '武器';
      case ItemType.armor:
        return '防具';
      case ItemType.charm:
        return '護符';
    }
  }
}
