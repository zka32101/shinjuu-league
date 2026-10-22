import 'package:flutter/material.dart';
import 'package:shinjuu_league/config/theme.dart';
import 'package:shinjuu_league/data/models/resource_model.dart';
import 'package:shinjuu_league/services/skill_system_service.dart';

/// ゲーム中のマナ・ゴール・ステータス表示HUD
class ResourceHUD extends StatelessWidget {
  final PlayerResources resources;
  final int elapsedSeconds;
  final List<String> ownedItemIds;
  final Function(String) onItemPurchase;

  const ResourceHUD({
    super.key,
    required this.resources,
    required this.elapsedSeconds,
    this.ownedItemIds = const [],
    required this.onItemPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // マナバー
        _buildManaBar(),
        const SizedBox(height: 12),

        // ゴール表示
        _buildGoldDisplay(),
        const SizedBox(height: 12),

        // アイテムスロット
        _buildItemSlots(context),
      ],
    );
  }

  Widget _buildManaBar() {
    final manaPercent = resources.currentMana / resources.maxMana;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'マナ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF999999),
                ),
              ),
              Text(
                '${resources.currentMana.toInt()} / ${resources.maxMana}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: manaPercent,
              minHeight: 8,
              backgroundColor: Colors.grey.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                manaPercent > 0.5
                    ? Colors.blue
                    : manaPercent > 0.25
                    ? Colors.orange
                    : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoldDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.monetization_on, color: Colors.amber, size: 20),
              SizedBox(width: 6),
              Text(
                'ゴール',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Text(
            resources.gold.toString(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemSlots(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'アイテム',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF999999),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // 既購入アイテム表示
                ...ownedItemIds.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final itemId = entry.value;
                  final item = _getItemDefinition(itemId);

                  return Padding(
                    padding: EdgeInsets.only(
                      right: idx < ownedItemIds.length - 1 ? 8 : 0,
                    ),
                    child: _buildItemChip(item),
                  );
                }),

                // アイテム購入ボタン
                if (ownedItemIds.length < 5)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: GestureDetector(
                      onTap: () => _showItemShop(context),
                      child: Container(
                        width: 56,
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.accentBlue,
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.add, color: AppColors.accentBlue),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemChip(ItemDefinition? item) {
    if (item == null) {
      return Container(
        width: 56,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Center(child: Text('?', style: TextStyle(fontSize: 24))),
      );
    }

    return Container(
      width: 56,
      decoration: BoxDecoration(
        color: _getRarityColor(item.rarity).withValues(alpha: 0.2),
        border: Border.all(color: _getRarityColor(item.rarity)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Tooltip(
        message: '${item.name}\n${item.description}',
        child: Center(
          child: Text(
            item.name.substring(0, 1),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _getRarityColor(item.rarity),
            ),
          ),
        ),
      ),
    );
  }

  void _showItemShop(BuildContext context) {
    final items = SkillSystemService.getAllItems();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        // 画面高さの60%を上限に、アイテム数が少なければ縮むようMainAxisSize.min
        // ではなくSizedBoxで上限を固定しつつ、一覧はExpandedでスクロール可能にする。
        // 以前はListViewをConstrainedBox(maxHeight: 360固定)で囲んでいたため、
        // 小さい画面（テスト環境含む）でヘッダー分を考慮せずオーバーフローしていた。
        final maxSheetHeight = MediaQuery.sizeOf(sheetContext).height * 0.6;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxSheetHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'アイテムショップ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '所持ゴール: ${resources.gold}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final owned = ownedItemIds.contains(item.itemId);
                        final affordable = resources.canAffordGold(item.cost);
                        final disabled = owned || !affordable;

                        return ListTile(
                          tileColor: _getRarityColor(
                            item.rarity,
                          ).withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: _getRarityColor(item.rarity),
                            ),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: _getRarityColor(
                              item.rarity,
                            ).withValues(alpha: 0.3),
                            child: Text(
                              item.name.substring(0, 1),
                              style: TextStyle(
                                color: _getRarityColor(item.rarity),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(item.description),
                          trailing: owned
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : Text(
                                  '${item.cost}G',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: affordable
                                        ? Colors.amber
                                        : Colors.grey,
                                  ),
                                ),
                          enabled: !disabled,
                          onTap: disabled
                              ? null
                              : () {
                                  onItemPurchase(item.itemId);
                                  Navigator.of(sheetContext).pop();
                                },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getRarityColor(ItemRarity rarity) {
    switch (rarity) {
      case ItemRarity.common:
        return Colors.grey;
      case ItemRarity.uncommon:
        return Colors.green;
      case ItemRarity.rare:
        return Colors.blue;
      case ItemRarity.legendary:
        return Colors.orange;
    }
  }

  ItemDefinition? _getItemDefinition(String itemId) {
    return SkillSystemService.getItemDefinition(itemId);
  }
}
