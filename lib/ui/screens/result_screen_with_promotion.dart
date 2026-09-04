import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/result_screen.dart';
import '../../data/models/battle_model.dart';
import '../../services/promotion_detector_service.dart';
import '../../viewmodels/season_viewmodel.dart';
import '../widgets/promotion_ceremony_widget.dart';

/// Enhanced ResultScreen wrapper that detects and shows promotion ceremonies
///
/// This widget wraps the ResultScreen to:
/// 1. Display the normal result screen
/// 2. After battle result is applied, detect if a promotion/demotion occurred
/// 3. Show promotion ceremony dialog if applicable
class ResultScreenWithPromotion extends ConsumerStatefulWidget {
  final Battle battle;
  final String? previousTier;
  final int? previousRating;

  const ResultScreenWithPromotion({
    required this.battle,
    this.previousTier,
    this.previousRating,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<ResultScreenWithPromotion> createState() =>
      _ResultScreenWithPromotionState();
}

class _ResultScreenWithPromotionState
    extends ConsumerState<ResultScreenWithPromotion> {
  bool _promotionShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_promotionShown) return;
      await Future.delayed(const Duration(seconds: 2)); // Wait for result screen animations

      if (!mounted) return;

      // Get the current season state to detect promotions
      final seasonState = ref.read(currentSeasonViewModelProvider);
      final previousTier = widget.previousTier;
      final previousRating = widget.previousRating;

      if (previousTier == null ||
          previousRating == null ||
          seasonState is! AsyncValue<SeasonalProgress?>) {
        return;
      }

      final progress = seasonState.maybeWhen(
        data: (p) => p,
        orElse: () => null,
      );

      if (progress == null) return;

      final currentTier = progress.userData.currentTier;
      final currentRating = progress.userData.currentRating;

      // Detect promotion/demotion
      final promotionEvent = PromotionDetectorService.detectPromotion(
        previousTier: previousTier,
        currentTier: currentTier,
        previousRating: previousRating,
        currentRating: currentRating,
        tierThresholds: progress.season.tierThresholds,
      );

      if (promotionEvent != null && mounted) {
        _promotionShown = true;
        await showPromotionCeremony(
          context,
          fromTier: promotionEvent.fromTier,
          toTier: promotionEvent.toTier,
          fromRating: promotionEvent.fromRating,
          toRating: promotionEvent.toRating,
          isPromotion: promotionEvent.isPromotion,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResultScreen(battle: widget.battle);
  }
}

/// Factory function to create ResultScreen or ResultScreenWithPromotion
/// based on availability of promotion detection data
Widget buildResultScreen({
  required Battle battle,
  String? previousTier,
  int? previousRating,
}) {
  if (previousTier != null && previousRating != null) {
    return ResultScreenWithPromotion(
      battle: battle,
      previousTier: previousTier,
      previousRating: previousRating,
    );
  }
  return ResultScreen(battle: battle);
}
