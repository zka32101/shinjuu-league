import 'package:flutter/material.dart';
import 'package:shinjuu_league/config/theme.dart';
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/services/achievement_toast_notification_service.dart';

/// Toast widget for displaying achievement unlock notifications
/// Shows compact achievement card with animation and optional tier color
class AchievementToastWidget extends StatefulWidget {
  final AchievementToastNotification notification;
  final VoidCallback? onDismiss;
  final Duration animationDuration;

  const AchievementToastWidget({
    super.key,
    required this.notification,
    this.onDismiss,
    this.animationDuration = const Duration(milliseconds: 400),
  });

  @override
  State<AchievementToastWidget> createState() => _AchievementToastWidgetState();
}

class _AchievementToastWidgetState extends State<AchievementToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    // Slide from right to left
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Fade in
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getRewardTierColor(AchievementRewardTier tier) {
    switch (tier) {
      case AchievementRewardTier.common:
        return const Color(0xFF808080);
      case AchievementRewardTier.uncommon:
        return const Color(0xFF00AA00);
      case AchievementRewardTier.rare:
        return const Color(0xFF0099FF);
      case AchievementRewardTier.epic:
        return const Color(0xFF9933FF);
      case AchievementRewardTier.legendary:
        return const Color(0xFFFFAA00);
      case AchievementRewardTier.mythic:
        return const Color(0xFFFF0000);
      case AchievementRewardTier.silver:
        return const Color(0xFFC0C0C0);
      case AchievementRewardTier.gold:
        return const Color(0xFFFFD700);
    }
  }

  @override
  Widget build(BuildContext context) {
    final achievement = widget.notification.achievement;
    final tierColor = _getRewardTierColor(achievement.rewardTier);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: tierColor.withOpacity(0.6),
                width: 2,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tierColor.withOpacity(0.15),
                  tierColor.withOpacity(0.05),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: tierColor.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Achievement emoji
                  const Text(
                    '🏆',
                    style: TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 12),
                  // Achievement name and description
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '成果を解除！',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: tierColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          achievement.name,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tier badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: tierColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _tierToShortLabel(achievement.rewardTier),
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontSize: 9,
                                color: tierColor,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _tierToShortLabel(AchievementRewardTier tier) {
    switch (tier) {
      case AchievementRewardTier.common:
        return 'C';
      case AchievementRewardTier.uncommon:
        return 'U';
      case AchievementRewardTier.rare:
        return 'R';
      case AchievementRewardTier.epic:
        return 'E';
      case AchievementRewardTier.legendary:
        return 'L';
      case AchievementRewardTier.mythic:
        return 'M';
      case AchievementRewardTier.silver:
        return 'S';
      case AchievementRewardTier.gold:
        return 'G';
    }
  }
}

/// Overlay container for displaying multiple achievement toasts
/// Should be placed near the top/corner of the screen (e.g., in Stack)
class AchievementToastOverlay extends StatefulWidget {
  final Stream<AchievementToastNotification> notifications;
  final Stream<String> dismissals;
  final Alignment alignment;

  const AchievementToastOverlay({
    super.key,
    required this.notifications,
    required this.dismissals,
    this.alignment = Alignment.topRight,
  });

  @override
  State<AchievementToastOverlay> createState() =>
      _AchievementToastOverlayState();
}

class _AchievementToastOverlayState extends State<AchievementToastOverlay> {
  final Map<String, AchievementToastNotification> _displayedToasts = {};

  @override
  void initState() {
    super.initState();
    widget.notifications.listen((notification) {
      if (mounted) {
        setState(() {
          _displayedToasts[notification.id] = notification;
        });
      }
    });

    widget.dismissals.listen((notificationId) {
      if (mounted) {
        setState(() {
          _displayedToasts.remove(notificationId);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_displayedToasts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: widget.alignment,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final notification in _displayedToasts.values)
              AchievementToastWidget(
                notification: notification,
              ),
          ],
        ),
      ),
    );
  }
}
