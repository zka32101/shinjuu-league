import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/services/promotion_detector_service.dart';

void main() {
  group('PromotionDetectorService', () {
    test('detects promotion when tier increases', () {
      final tierThresholds = {
        'Bronze': 400,
        'Silver': 1400,
        'Gold': 1800,
        'Platinum': 2200,
        'Legend': 2800,
      };

      final event = PromotionDetectorService.detectPromotion(
        previousTier: 'Bronze',
        currentTier: 'Silver',
        previousRating: 1200,
        currentRating: 1450,
        tierThresholds: tierThresholds,
      );

      expect(event, isNotNull);
      expect(event!.isPromotion, isTrue);
      expect(event.fromTier, equals('Bronze'));
      expect(event.toTier, equals('Silver'));
      expect(event.fromRating, equals(1200));
      expect(event.toRating, equals(1450));
    });

    test('detects demotion when tier decreases', () {
      final tierThresholds = {
        'Bronze': 400,
        'Silver': 1400,
        'Gold': 1800,
        'Platinum': 2200,
        'Legend': 2800,
      };

      final event = PromotionDetectorService.detectPromotion(
        previousTier: 'Silver',
        currentTier: 'Bronze',
        previousRating: 1450,
        currentRating: 1200,
        tierThresholds: tierThresholds,
      );

      expect(event, isNotNull);
      expect(event!.isPromotion, isFalse);
      expect(event.fromTier, equals('Silver'));
      expect(event.toTier, equals('Bronze'));
      expect(event.fromRating, equals(1450));
      expect(event.toRating, equals(1200));
    });

    test('returns null when tier does not change', () {
      final tierThresholds = {
        'Bronze': 400,
        'Silver': 1400,
        'Gold': 1800,
        'Platinum': 2200,
        'Legend': 2800,
      };

      final event = PromotionDetectorService.detectPromotion(
        previousTier: 'Silver',
        currentTier: 'Silver',
        previousRating: 1300,
        currentRating: 1500,
        tierThresholds: tierThresholds,
      );

      expect(event, isNull);
    });

    test('detects promotion from lowest to highest tier', () {
      final tierThresholds = {
        'Bronze': 400,
        'Silver': 1400,
        'Gold': 1800,
        'Platinum': 2200,
        'Legend': 2800,
      };

      final event = PromotionDetectorService.detectPromotion(
        previousTier: 'Bronze',
        currentTier: 'Legend',
        previousRating: 800,
        currentRating: 2900,
        tierThresholds: tierThresholds,
      );

      expect(event, isNotNull);
      expect(event!.isPromotion, isTrue);
      expect(event.toTier, equals('Legend'));
    });

    test('detects demotion from highest to lowest tier', () {
      final tierThresholds = {
        'Bronze': 400,
        'Silver': 1400,
        'Gold': 1800,
        'Platinum': 2200,
        'Legend': 2800,
      };

      final event = PromotionDetectorService.detectPromotion(
        previousTier: 'Legend',
        currentTier: 'Bronze',
        previousRating: 2900,
        currentRating: 500,
        tierThresholds: tierThresholds,
      );

      expect(event, isNotNull);
      expect(event!.isPromotion, isFalse);
      expect(event.toTier, equals('Bronze'));
    });

    test('uses default thresholds when custom thresholds are null', () {
      final event = PromotionDetectorService.detectPromotion(
        previousTier: 'Bronze',
        currentTier: 'Silver',
        previousRating: 1200,
        currentRating: 1450,
        tierThresholds: null,
      );

      expect(event, isNotNull);
      expect(event!.isPromotion, isTrue);
    });

    test('handles unknown tier names with default threshold', () {
      final tierThresholds = {
        'Bronze': 400,
        'Silver': 1400,
        'Gold': 1800,
        'Platinum': 2200,
        'Legend': 2800,
      };

      final event = PromotionDetectorService.detectPromotion(
        previousTier: 'UnknownTier1',
        currentTier: 'UnknownTier2',
        previousRating: 1200,
        currentRating: 1450,
        tierThresholds: tierThresholds,
      );

      // Both unknown tiers get default threshold of 400
      // So they're at the same threshold, not a promotion
      expect(event, isNull);
    });

    test('promotion event has correct tier emojis', () {
      final tierThresholds = {
        'Bronze': 400,
        'Silver': 1400,
        'Gold': 1800,
        'Platinum': 2200,
        'Legend': 2800,
      };

      final event = PromotionDetectorService.detectPromotion(
        previousTier: 'Silver',
        currentTier: 'Gold',
        previousRating: 1500,
        currentRating: 1850,
        tierThresholds: tierThresholds,
      );

      expect(event!.fromTierEmoji, equals('🥈'));
      expect(event.toTierEmoji, equals('🥇'));
    });

    test('demotion event has correct tier emojis', () {
      final tierThresholds = {
        'Bronze': 400,
        'Silver': 1400,
        'Gold': 1800,
        'Platinum': 2200,
        'Legend': 2800,
      };

      final event = PromotionDetectorService.detectPromotion(
        previousTier: 'Gold',
        currentTier: 'Silver',
        previousRating: 1850,
        currentRating: 1200,
        tierThresholds: tierThresholds,
      );

      expect(event!.fromTierEmoji, equals('🥇'));
      expect(event.toTierEmoji, equals('🥈'));
    });

    test('promotion message for promotion event', () {
      final tierThresholds = {
        'Bronze': 400,
        'Silver': 1400,
        'Gold': 1800,
        'Platinum': 2200,
        'Legend': 2800,
      };

      final event = PromotionDetectorService.detectPromotion(
        previousTier: 'Silver',
        currentTier: 'Gold',
        previousRating: 1500,
        currentRating: 1850,
        tierThresholds: tierThresholds,
      );

      expect(event!.message, contains('Congratulations'));
      expect(event.message, contains('Gold'));
    });

    test('demotion message for demotion event', () {
      final tierThresholds = {
        'Bronze': 400,
        'Silver': 1400,
        'Gold': 1800,
        'Platinum': 2200,
        'Legend': 2800,
      };

      final event = PromotionDetectorService.detectPromotion(
        previousTier: 'Gold',
        currentTier: 'Silver',
        previousRating: 1850,
        currentRating: 1200,
        tierThresholds: tierThresholds,
      );

      expect(event!.message, contains('demoted'));
      expect(event.message, contains('Silver'));
    });

    test('promotion event with Platinum tier', () {
      final tierThresholds = {
        'Bronze': 400,
        'Silver': 1400,
        'Gold': 1800,
        'Platinum': 2200,
        'Legend': 2800,
      };

      final event = PromotionDetectorService.detectPromotion(
        previousTier: 'Gold',
        currentTier: 'Platinum',
        previousRating: 1900,
        currentRating: 2250,
        tierThresholds: tierThresholds,
      );

      expect(event!.isPromotion, isTrue);
      expect(event.fromTierEmoji, equals('🥇'));
      expect(event.toTierEmoji, equals('👑'));
    });

    test('promotion event with Legend tier', () {
      final tierThresholds = {
        'Bronze': 400,
        'Silver': 1400,
        'Gold': 1800,
        'Platinum': 2200,
        'Legend': 2800,
      };

      final event = PromotionDetectorService.detectPromotion(
        previousTier: 'Platinum',
        currentTier: 'Legend',
        previousRating: 2300,
        currentRating: 2850,
        tierThresholds: tierThresholds,
      );

      expect(event!.isPromotion, isTrue);
      expect(event.fromTierEmoji, equals('👑'));
      expect(event.toTierEmoji, equals('⭐'));
    });

    test('default tier thresholds are correct', () {
      final thresholds = PromotionDetectorService.detectPromotion(
        previousTier: 'Bronze',
        currentTier: 'Silver',
        previousRating: 800,
        currentRating: 1500,
        tierThresholds: null,
      );

      expect(thresholds, isNotNull);
      expect(thresholds!.isPromotion, isTrue);
    });
  });
}
