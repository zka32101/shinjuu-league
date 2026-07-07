import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shinjuu_league/config/theme.dart';
import 'package:shinjuu_league/data/mecha_catalog.dart';
import 'package:shinjuu_league/data/models/mecha_model.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';

class MechaSelectScreen extends ConsumerWidget {
  const MechaSelectScreen({super.key});

  Color _rarityColor(String rarity) {
    switch (rarity) {
      case 'RARE':
        return AppColors.rarityRare;
      case 'EPIC':
        return AppColors.rarityEpic;
      case 'LEGEND':
        return AppColors.rarityLegend;
      default:
        return AppColors.rarityCommon;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('神獣を選択')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('読み込みエラー: $e')),
        data: (user) {
          if (user == null) return const Center(child: Text('ユーザー情報が見つかりません'));

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: mechaCatalog.length,
            itemBuilder: (context, i) {
              final mecha = mechaCatalog[i];
              final isSelected = mecha.mechaId == user.selectedMechaId;

              return _MechaCard(
                mecha: mecha,
                isSelected: isSelected,
                rarityColor: _rarityColor(mecha.rarity),
                onTap: () async {
                  await ref
                      .read(userViewModelProvider.notifier)
                      .selectMecha(mecha.mechaId);
                  if (context.mounted) context.pop();
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _MechaCard extends StatelessWidget {
  const _MechaCard({
    required this.mecha,
    required this.isSelected,
    required this.rarityColor,
    required this.onTap,
  });

  final Mecha mecha;
  final bool isSelected;
  final Color rarityColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 3)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(
                      mecha.rarity,
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                    backgroundColor: rarityColor,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Icon(
                mecha.origin == 'EAST'
                    ? Icons.local_fire_department
                    : Icons.ac_unit,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                mecha.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'HP${mecha.baseStats.hp} / ATK${mecha.baseStats.atk} / SPD${mecha.baseStats.spd}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  mecha.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
