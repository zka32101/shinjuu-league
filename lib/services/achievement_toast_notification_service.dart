import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/services/audio_service.dart';
import 'package:shinjuu_league/services/haptic_service.dart';

/// Achievement unlock toast notification state
class AchievementToastNotification {
  final Achievement achievement;
  final DateTime createdAt;
  final String id;

  AchievementToastNotification({
    required this.achievement,
    required this.createdAt,
    required this.id,
  });
}

/// Service to manage in-game achievement toast notifications
/// Handles queueing, display duration, and lifecycle of toast notifications
class AchievementToastNotificationService {
  final _notificationStream = StreamController<AchievementToastNotification>.broadcast();
  final _dismissStream = StreamController<String>.broadcast();
  final Queue<AchievementToastNotification> _queue = Queue();
  final Set<String> _displayedIds = {};

  static int _idCounter = 0;

  // Configuration
  final Duration displayDuration;
  final Duration transitionDuration;
  final int maxConcurrentNotifications;

  AchievementToastNotificationService({
    this.displayDuration = const Duration(seconds: 3),
    this.transitionDuration = const Duration(milliseconds: 400),
    this.maxConcurrentNotifications = 3,
  });

  /// Stream of achievement toast notifications to display
  Stream<AchievementToastNotification> get notifications => _notificationStream.stream;

  /// Stream of notification IDs to dismiss
  Stream<String> get dismissals => _dismissStream.stream;

  /// Show an achievement toast notification
  /// Returns the notification ID
  Future<String> showAchievementToast(Achievement achievement) async {
    try {
      final notificationId = _generateId();
      final notification = AchievementToastNotification(
        achievement: achievement,
        createdAt: DateTime.now(),
        id: notificationId,
      );

      // Play haptic and audio feedback
      HapticService.onAchievementUnlock();
      AudioService().playAchievementUnlockedSe();

      // Add to queue
      _queue.addLast(notification);
      _processQueue();

      return notificationId;
    } catch (e) {
      debugPrint('Error showing achievement toast: $e');
      rethrow;
    }
  }

  /// Process the notification queue
  void _processQueue() {
    if (_queue.isEmpty) {
      return;
    }

    // Don't exceed max concurrent notifications
    if (_displayedIds.length >= maxConcurrentNotifications) {
      return;
    }

    final notification = _queue.removeFirst();
    _displayedIds.add(notification.id);
    _notificationStream.add(notification);

    // Schedule automatic dismissal
    Future.delayed(displayDuration, () {
      _dismissNotification(notification.id);
    });
  }

  /// Dismiss a specific notification
  void _dismissNotification(String notificationId) {
    if (!_displayedIds.contains(notificationId)) {
      return;
    }

    _displayedIds.remove(notificationId);
    _dismissStream.add(notificationId);

    // Process next in queue if available
    if (_queue.isNotEmpty) {
      _processQueue();
    }
  }

  /// Manually dismiss a notification by ID
  void dismiss(String notificationId) {
    _dismissNotification(notificationId);
  }

  /// Clear all pending notifications
  void clearAll() {
    _queue.clear();
    for (final id in _displayedIds.toList()) {
      _dismissNotification(id);
    }
  }

  /// Get current number of displayed notifications
  int get displayedCount => _displayedIds.length;

  /// Get current queue size
  int get queueSize => _queue.length;

  /// Check if a notification is currently displayed
  bool isDisplayed(String notificationId) {
    return _displayedIds.contains(notificationId);
  }

  /// Debug: get all displayed notification IDs
  List<String> debugGetDisplayedIds() {
    return _displayedIds.toList();
  }

  /// Debug: get notification stats
  Map<String, dynamic> debugGetStats() {
    return {
      'displayed_count': _displayedIds.length,
      'queue_size': _queue.length,
      'max_concurrent': maxConcurrentNotifications,
      'display_duration_ms': displayDuration.inMilliseconds,
    };
  }

  void dispose() {
    _notificationStream.close();
    _dismissStream.close();
  }

  /// Generate unique notification ID
  static String _generateId() {
    return 'achievement_toast_${_idCounter++}_${DateTime.now().millisecondsSinceEpoch}';
  }
}
