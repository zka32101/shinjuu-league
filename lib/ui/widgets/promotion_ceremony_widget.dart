import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Promotion/Demotion ceremony animation widget
///
/// Displays animated tier transition with:
/// - Tier icons (from → to)
/// - Confetti/particles (promotion) or downward effects (demotion)
/// - Rating change display
/// - Smooth transitions
class PromotionCeremonyWidget extends StatefulWidget {
  final String fromTier;
  final String toTier;
  final int fromRating;
  final int toRating;
  final bool isPromotion;
  final VoidCallback? onAnimationComplete;

  const PromotionCeremonyWidget({
    required this.fromTier,
    required this.toTier,
    required this.fromRating,
    required this.toRating,
    required this.isPromotion,
    this.onAnimationComplete,
    super.key,
  });

  @override
  State<PromotionCeremonyWidget> createState() =>
      _PromotionCeremonyWidgetState();
}

class _PromotionCeremonyWidgetState extends State<PromotionCeremonyWidget>
    with TickerProviderStateMixin {
  late AnimationController _controllerMain;
  late AnimationController _controllerParticles;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Main animation controller (2 seconds)
    _controllerMain = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Particles controller (continuous during main animation)
    _controllerParticles = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Scale animation: starts small, scales up
    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controllerMain, curve: Curves.elasticOut),
    );

    // Opacity animation: fade in
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controllerMain, curve: Curves.easeIn),
    );

    // Slide animation: comes from top (promotion) or bottom (demotion)
    final startOffset =
        widget.isPromotion ? const Offset(0, -0.5) : const Offset(0, 0.5);
    _slideAnimation = Tween<Offset>(begin: startOffset, end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _controllerMain, curve: Curves.easeOut),
        );

    // Start animations
    _controllerMain.forward();
    _controllerParticles.repeat();

    // Callback when main animation completes
    _controllerMain.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _controllerMain.dispose();
    _controllerParticles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ratingDifference = widget.toRating - widget.fromRating;
    final ratingText =
        ratingDifference > 0 ? '+$ratingDifference' : '$ratingDifference';
    final ratingColor = ratingDifference > 0 ? Colors.green : Colors.red;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Particle effects
        if (widget.isPromotion)
          _PromotionParticles(
            animation: _controllerParticles,
          )
        else
          _DemotionParticles(
            animation: _controllerParticles,
          ),

        // Main ceremony card
        SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      widget.isPromotion ? '🎉 Promotion!' : '📉 Demotion',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.isPromotion ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tier transition (from → to)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _TierDisplay(tier: widget.fromTier),
                        const SizedBox(width: 16),
                        Icon(
                          widget.isPromotion
                              ? Icons.arrow_forward
                              : Icons.arrow_back,
                          size: 28,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 16),
                        _TierDisplay(tier: widget.toTier),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Rating change
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: ratingColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: ratingColor.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Rating Change',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${widget.fromRating}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      decoration:
                                          TextDecoration.lineThrough,
                                      color: Colors.grey,
                                    ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                ratingText,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: ratingColor,
                                    ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${widget.toRating}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: ratingColor,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Message
                    Text(
                      widget.isPromotion
                          ? 'Great job reaching ${widget.toTier}!'
                          : 'Keep practicing, you\'ll get back to ${widget.fromTier}!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tier display widget
class _TierDisplay extends StatelessWidget {
  final String tier;

  const _TierDisplay({required this.tier});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _getTierEmoji(tier),
          style: const TextStyle(fontSize: 48),
        ),
        const SizedBox(height: 8),
        Text(
          tier,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getTierEmoji(String tier) {
    switch (tier) {
      case 'Bronze':
        return '🥉';
      case 'Silver':
        return '🥈';
      case 'Gold':
        return '🥇';
      case 'Platinum':
        return '👑';
      case 'Legend':
        return '⭐';
      default:
        return '🎯';
    }
  }
}

/// Promotion particles animation
class _PromotionParticles extends StatelessWidget {
  final Animation<double> animation;

  const _PromotionParticles({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Stack(
          children: List.generate(
            8,
            (index) {
              final angle = (index / 8) * 2 * 3.14159;
              final distance = 100 + (animation.value * 50);
              final dx = distance * cos(angle);
              final dy = distance * sin(angle) - 100;
              final opacity = 1 - animation.value;

              return Positioned(
                left: MediaQuery.of(context).size.width / 2 + dx - 8,
                top: MediaQuery.of(context).size.height / 2 + dy - 8,
                child: Opacity(
                  opacity: opacity,
                  child: const Text(
                    '⭐',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  double cos(double angle) => math.cos(angle);
  double sin(double angle) => math.sin(angle);
}

/// Demotion particles animation (downward effect)
class _DemotionParticles extends StatelessWidget {
  final Animation<double> animation;

  const _DemotionParticles({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Stack(
          children: List.generate(
            6,
            (index) {
              final xOffset = (index - 2.5) * 30.0;
              final yOffset = animation.value * 80;
              final opacity = 1 - animation.value;

              return Positioned(
                left: MediaQuery.of(context).size.width / 2 + xOffset - 8,
                top: MediaQuery.of(context).size.height / 2 - 50 + yOffset,
                child: Opacity(
                  opacity: opacity,
                  child: const Text(
                    '💔',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Dialog helper to show promotion ceremony
Future<void> showPromotionCeremony(
  BuildContext context, {
  required String fromTier,
  required String toTier,
  required int fromRating,
  required int toRating,
  required bool isPromotion,
  VoidCallback? onDismiss,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: PromotionCeremonyWidget(
          fromTier: fromTier,
          toTier: toTier,
          fromRating: fromRating,
          toRating: toRating,
          isPromotion: isPromotion,
          onAnimationComplete: () {
            Navigator.of(context).pop();
            onDismiss?.call();
          },
        ),
      );
    },
  );
}
