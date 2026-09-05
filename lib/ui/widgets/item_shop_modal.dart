import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/config/theme.dart';
import 'package:shinjuu_league/data/models/item_model.dart';
import 'package:shinjuu_league/services/item_service.dart';
import 'package:shinjuu_league/services/auth_service.dart';
import 'package:shinjuu_league/ui/widgets/custom_button.dart';

/// アイテムショップのモーダルダイアログ
/// ItemCatalog から利用可能なアイテムを表示して購入できる
class ItemShopModal extends ConsumerStatefulWidget {
  final Function()? onPurchaseComplete;

  const ItemShopModal({
    Key? key,
    this.onPurchaseComplete,
  }) : super(key: key);

  /// モーダルを表示するヘルパーメソッド
  static Future<void> show(
    BuildContext context, {
    Function()? onPurchaseComplete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.dark1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) => ItemShopModal(
        onPurchaseComplete: onPurchaseComplete,
      ),
    );
  }

  @override
  ConsumerState<ItemShopModal> createState() => _ItemShopModalState();
}

class _ItemShopModalState extends ConsumerState<ItemShopModal> {
  int _selectedTabIndex = 0; // 0: All, 1: Weapon, 2: Armor, 3: Charm
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Column(
            children: [
              _buildHeader(context),
              _buildTabBar(context),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildItemsGrid(context),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// ヘッダー
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dark2,
        border: Border(
          bottom: BorderSide(color: AppColors.dark3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'アイテムショップ',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSearchField(context),
        ],
      ),
    );
  }

  /// 検索フィールド
  Widget _buildSearchField(BuildContext context) {
    return TextField(
      controller: _searchController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'アイテムを検索...',
        hintStyle: TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.dark3,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onChanged: (value) {
        setState(() {});
      },
    );
  }

  /// タブバー
  Widget _buildTabBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: AppColors.dark2,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTabButton(context, 'すべて', 0),
            const SizedBox(width: 8),
            _buildTabButton(context, '武器', 1),
            const SizedBox(width: 8),
            _buildTabButton(context, '防具', 2),
            const SizedBox(width: 8),
            _buildTabButton(context, '護符', 3),
          ],
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.dark3,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  /// アイテムグリッド
  Widget _buildItemsGrid(BuildContext context) {
    final allItems = ItemCatalog.availableItems;
    var displayItems = _filterItems(allItems);

    if (displayItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'アイテムが見つかりません',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: displayItems.length,
      itemBuilder: (context, index) {
        return _buildItemCard(context, displayItems[index]);
      },
    );
  }

  /// アイテムカード
  Widget _buildItemCard(BuildContext context, Item item) {
    return GestureDetector(
      onTap: () => _showItemDetail(context, item),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.dark3,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getRarityColor(item.rarity),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー（レアリティ表示）
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getRarityColor(item.rarity).withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              width: double.infinity,
              child: Text(
                _getRarityLabel(item.rarity),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getRarityColor(item.rarity),
                ),
              ),
            ),
            // コンテンツ
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (item.bonus != null) _buildBonusPreview(item.bonus!),
                    const Spacer(),
                    // 価格表示
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '💰 ${item.purchasePrice}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ボーナスプレビュー
  Widget _buildBonusPreview(ItemBonus bonus) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (bonus.attackBonus != null)
          Text(
            '⚔️ +${bonus.attackBonus!.toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 10),
          ),
        if (bonus.defenseBonus != null)
          Text(
            '🛡️ +${bonus.defenseBonus!.toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 10),
          ),
        if (bonus.hpBonus != null)
          Text(
            '❤️ +${bonus.hpBonus!.toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 10),
          ),
      ],
    );
  }

  /// アイテム詳細ダイアログを表示
  void _showItemDetail(BuildContext context, Item item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.dark2,
        title: Text(item.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.description),
            const SizedBox(height: 16),
            if (item.bonus != null) ...[
              const Text('ボーナス:'),
              if (item.bonus!.attackBonus != null)
                Text('  ⚔️  攻撃力: +${item.bonus!.attackBonus!.toStringAsFixed(1)}%'),
              if (item.bonus!.defenseBonus != null)
                Text('  🛡️  防御力: +${item.bonus!.defenseBonus!.toStringAsFixed(1)}%'),
              if (item.bonus!.hpBonus != null)
                Text('  ❤️  体力: +${item.bonus!.hpBonus!.toStringAsFixed(1)}%'),
              const SizedBox(height: 12),
            ],
            Text(
              '価格: 💰 ${item.purchasePrice}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _purchaseItem(context, item);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('購入'),
          ),
        ],
      ),
    );
  }

  /// アイテムを購入
  Future<void> _purchaseItem(BuildContext context, Item item) async {
    try {
      final authService = AuthService();
      final itemService = ItemService();
      final userId = authService.currentUser?.uid;

      if (userId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ログインが必要です')),
        );
        return;
      }

      // 購入処理（実装ではゴールドチェックなど追加予定）
      await itemService.purchaseItem(
        userId,
        item.itemId,
        item.purchasePrice,
      );

      if (!mounted) return;
      Navigator.pop(context); // Detail dialog を閉じる

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('購入しました！')),
      );

      widget.onPurchaseComplete?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('購入に失敗しました: $e')),
      );
    }
  }

  /// フィルタリング済みアイテムリストを取得
  List<Item> _filterItems(List<Item> items) {
    var filtered = items;

    // タイプフィルタ
    if (_selectedTabIndex == 1) {
      filtered = filtered.where((i) => i.type == ItemType.weapon).toList();
    } else if (_selectedTabIndex == 2) {
      filtered = filtered.where((i) => i.type == ItemType.armor).toList();
    } else if (_selectedTabIndex == 3) {
      filtered = filtered.where((i) => i.type == ItemType.charm).toList();
    }

    // 検索フィルタ
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered
          .where(
            (i) =>
                i.name.toLowerCase().contains(query) ||
                i.description.toLowerCase().contains(query),
          )
          .toList();
    }

    return filtered;
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
}
