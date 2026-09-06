import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Season end ceremony widget displaying tier transitions with animations
/// Shows celebration/warning effects based on promotion/demotion
class SeasonEndCeremonyWidget extends StatefulWidget {
  final String fromTier;
  final String toTier;
  final bool isPromotion;
  final VoidCallback? onComplete;
  final Duration duration;

  const SeasonEndCeremonyWidget({
    required this.fromTier,
    required this.toTier,
    required this.isPromotion,
    this.onComplete,
    this.duration = const Duration(seconds: 3),
    Key? key,
  }) : super(key: key);

  @override
  State<SeasonEndCeremonyWidget> createState() => _SeasonEndCeremonyWidgetState();
}

class _SeasonEndCeremonyWidgetState extends State<SeasonEndCeremonyWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _particleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward().then((_) {
      widget.onComplete?.call();
    });

    _particleController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  String _getTierEmoji(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
      case 'copper':
        return '🥉';
      case 'silver':
      case 'argent':
        return '🥈';
      case 'gold':
      case 'or':
        return '🥇';
      case 'platinum':
      case 'platine':
        return '💎';
      default:
        return '⭐';
    }
  }

  String _getCeremonyMessage() {
    if (widget.isPromotion) {
      return '昇格おめでとうございます！';
    } else {
      return '次シーズンへのチャレンジを祈っています';
    }
  }

  Color _getCeremonyColor() {
    if (widget.isPromotion) {
      return const Color(0xFFFFD700); // Gold
    } else {
      return const Color(0xFF87CEEB); // Sky blue
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background blur/card
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _getCeremonyColor(),
                    width: 3,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      'シーズン終了',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 24),

                    // Tier transition display
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // From tier
                        Column(
                          children: [
                            Text(
                              _getTierEmoji(widget.fromTier),
                              style: const TextStyle(fontSize: 48),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.fromTier,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 32),

                        // Arrow
                        Icon(
                          widget.isPromotion
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: _getCeremonyColor(),
                          size: 32,
                        ),
                        const SizedBox(width: 32),

                        // To tier
                        Column(
                          children: [
                            Text(
                              _getTierEmoji(widget.toTier),
                              style: const TextStyle(fontSize: 48),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.toTier,
                              style: TextStyle(
                                color: _getCeremonyColor(),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Message
                    Text(
                      _getCeremonyMessage(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _getCeremonyColor(),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Particle effects
              if (widget.isPromotion)
                _buildPromotionParticles()
              else
                _buildDemotionParticles(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromotionParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return Stack(
          children: List.generate(8, (index) {
            final angle = (index / 8) * 2 * math.pi;
            final progress = _particleController.value;

            final offsetX = math.cos(angle) * 150 * progress;
            final offsetY = math.sin(angle) * 150 * progress;

            return Transform.translate(
              offset: Offset(offsetX, offsetY),
              child: Opacity(
                opacity: 1.0 - progress,
                child: const Text(
                  '⭐',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildDemotionParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return Stack(
          children: List.generate(6, (index) {
            final angle = (index / 6) * 2 * math.pi;
            final progress = _particleController.value;

            final offsetX = math.cos(angle) * 100 * progress;
            final offsetY = (math.sin(angle) * 100 + 50) * progress;

            return Transform.translate(
              offset: Offset(offsetX, offsetY),
              child: Opacity(
                opacity: 1.0 - progress,
                child: const Text(
                  '❄️',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Helper function to show season end ceremony
Future<void> showSeasonEndCeremony(
  BuildContext context, {
  required String fromTier,
  required String toTier,
  required bool isPromotion,
  VoidCallback? onComplete,
  Duration? duration,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      return SeasonEndCeremonyWidget(
        fromTier: fromTier,
        toTier: toTier,
        isPromotion: isPromotion,
        onComplete: () {
          onComplete?.call();
          Navigator.of(context).pop();
        },
        duration: duration ?? const Duration(seconds: 3),
      );
    },
  );
}
