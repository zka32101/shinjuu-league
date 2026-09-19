import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shinjuu_league/config/theme.dart';
import 'package:shinjuu_league/data/mecha_catalog.dart';
import 'package:shinjuu_league/data/models/mecha_model.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';
import 'package:shinjuu_league/game/mecha_glyph.dart';

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
              _MechaPortrait(mecha: mecha, size: 64),
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

/// 実キャラクターアート素材の代わりに、ステータス由来の[MechaGlyph]で
/// 球体ポートレートを自動生成して表示するウィジェット。
/// バトル画面の[MechaToken]と同じ生成ロジックを使うため、選択画面と
/// バトル中で同一キャラの見た目に一貫性が出る。
class _MechaPortrait extends StatelessWidget {
  const _MechaPortrait({required this.mecha, required this.size});

  final Mecha mecha;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MechaPortraitPainter(mecha)),
    );
  }
}

class _MechaPortraitPainter extends CustomPainter {
  _MechaPortraitPainter(this.mecha) : glyph = MechaGlyph.forMecha(mecha);

  final Mecha mecha;
  final MechaGlyph glyph;

  static const _eastBody = Color(0xFFE0533D);
  static const _westBody = Color(0xFF3D7FE0);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 * 0.62;
    final baseColor = mecha.origin == 'EAST' ? _eastBody : _westBody;

    final lightColor = Color.lerp(baseColor, Colors.white, 0.55)!;
    final darkColor = Color.lerp(baseColor, Colors.black, 0.45)!;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(center.dx - radius * 0.35, center.dy - radius * 0.35),
          radius * 1.3,
          [lightColor, baseColor, darkColor],
          const [0.0, 0.5, 1.0],
        ),
    );

    glyph.paint(canvas, center, radius, 1.0);

    canvas.drawCircle(
      Offset(center.dx - radius * 0.32, center.dy - radius * 0.32),
      radius * 0.22,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  @override
  bool shouldRepaint(covariant _MechaPortraitPainter oldDelegate) =>
      oldDelegate.mecha.mechaId != mecha.mechaId;
}
