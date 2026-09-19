import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/services/achievement_service.dart';
import 'package:shinjuu_league/services/achievement_trigger_detector.dart';

class MockAchievementService extends Mock implements AchievementService {}

void main() {
  group('AchievementTriggerDetector', () {
    late AchievementTriggerDetector detector;
    late MockAchievementService mockAchievementService;

    const String userId = 'user_123';

    setUp(() {
      mockAchievementService = MockAchievementService();
      detector = AchievementTriggerDetector(
        achievementService: mockAchievementService,
      );
    });

    group('checkKillTriggers', () {
      test('triggers Aha Moment on first kill', () async {
        when(mockAchievementService.getProgress(userId, 'aha_moment'))
            .thenAnswer((_) async => PlayerAchievement(
                  userId: userId,
                  achievementId: 'aha_moment',
                ));

        when(mockAchievementService.unlockAchievement(userId, 'aha_moment'))
            .thenAnswer((_) async {});

        final result = await detector.checkKillTriggers(userId, 1, 1);

        expect(result, isNotEmpty);
        verify(mockAchievementService.unlockAchievement(
          userId,
          'aha_moment',
        )).called(1);
      });

      test('does not trigger Aha Moment on subsequent kills', () async {
        final result = await detector.checkKillTriggers(userId, 2, 5);
        expect(result, isEmpty);
      });

      test('returns empty list on error', () async {
        when(mockAchievementService.getProgress(userId, 'aha_moment'))
            .thenThrow(Exception('Service error'));

        final result = await detector.checkKillTriggers(userId, 1, 1);
        expect(result, isEmpty);
      });
    });

    group('checkBattleCompletionTriggers', () {
      test('triggers Rising Star on battle win', () async {
        when(mockAchievementService.getProgress(userId, 'rising_star'))
            .thenAnswer((_) async => PlayerAchievement(
                  userId: userId,
                  achievementId: 'rising_star',
                ));

        when(mockAchievementService.unlockAchievement(userId, 'rising_star'))
            .thenAnswer((_) async {});

        final result = await detector.checkBattleCompletionTriggers(
          userId,
          won: true,
          kills: 2,
          deaths: 1,
          assists: 1,
          damageDealt: 500,
          totalBattles: 5,
          winCount: 2,
        );

        expect(result, isNotEmpty);
        verify(mockAchievementService.unlockAchievement(
          userId,
          'rising_star',
        )).called(1);
      });

      test('does not trigger on battle loss', () async {
        final result = await detector.checkBattleCompletionTriggers(
          userId,
          won: false,
          kills: 1,
          deaths: 2,
          assists: 0,
          damageDealt: 300,
          totalBattles: 5,
          winCount: 1,
        );

        expect(result, isEmpty);
        verifyNever(mockAchievementService.unlockAchievement(
          any,
          any,
        ));
      });

      test('does not trigger if already unlocked', () async {
        when(mockAchievementService.getProgress(userId, 'rising_star'))
            .thenAnswer((_) async => PlayerAchievement(
                  userId: userId,
                  achievementId: 'rising_star',
                  unlockedAt: DateTime.now(),
                ));

        final result = await detector.checkBattleCompletionTriggers(
          userId,
          won: true,
          kills: 2,
          deaths: 1,
          assists: 1,
          damageDealt: 500,
          totalBattles: 5,
          winCount: 2,
        );

        expect(result, isEmpty);
      });
    });

    group('checkProgressTriggers', () {
      test('triggers Stat Master at 50+ stat points', () async {
        when(mockAchievementService.getProgress(userId, 'stat_master'))
            .thenAnswer((_) async => PlayerAchievement(
                  userId: userId,
                  achievementId: 'stat_master',
                ));

        when(mockAchievementService.unlockAchievement(userId, 'stat_master'))
            .thenAnswer((_) async {});

        final result = await detector.checkProgressTriggers(
          userId,
          statPoints: 50,
          pathDiversity: 1,
          seasonsParticipated: 1,
          consistentSeasons: 0,
          currentTier: 'Bronze',
        );

        expect(result, isNotEmpty);
        verify(mockAchievementService.unlockAchievement(
          userId,
          'stat_master',
        )).called(1);
      });

      test('triggers Balanced Fighter with 3-path diversity', () async {
        when(mockAchievementService.getProgress(userId, 'balanced_fighter'))
            .thenAnswer((_) async => PlayerAchievement(
                  userId: userId,
                  achievementId: 'balanced_fighter',
                ));

        when(mockAchievementService.unlockAchievement(
            userId, 'balanced_fighter'))
            .thenAnswer((_) async {});

        final result = await detector.checkProgressTriggers(
          userId,
          statPoints: 30,
          pathDiversity: 3,
          seasonsParticipated: 1,
          consistentSeasons: 0,
          currentTier: 'Silver',
        );

        expect(result, isNotEmpty);
        verify(mockAchievementService.unlockAchievement(
          userId,
          'balanced_fighter',
        )).called(1);
      });

      test('does not trigger Stat Master below 50 points', () async {
        when(mockAchievementService.getProgress(userId, 'stat_master'))
            .thenAnswer((_) async => PlayerAchievement(
                  userId: userId,
                  achievementId: 'stat_master',
                ));

        final result = await detector.checkProgressTriggers(
          userId,
          statPoints: 49,
          pathDiversity: 1,
          seasonsParticipated: 1,
          consistentSeasons: 0,
          currentTier: 'Bronze',
        );

        verifyNever(mockAchievementService.unlockAchievement(
          any,
          any,
        ));
      });

      test('does not trigger Balanced Fighter with insufficient diversity',
          () async {
        when(mockAchievementService.getProgress(userId, 'balanced_fighter'))
            .thenAnswer((_) async => PlayerAchievement(
                  userId: userId,
                  achievementId: 'balanced_fighter',
                ));

        final result = await detector.checkProgressTriggers(
          userId,
          statPoints: 50,
          pathDiversity: 2,
          seasonsParticipated: 1,
          consistentSeasons: 0,
          currentTier: 'Silver',
        );

        verifyNever(mockAchievementService.unlockAchievement(
          any,
          any,
        ));
      });
    });

    group('checkSeasonalTriggers', () {
      test('triggers Season Warrior at 10 seasons', () async {
        when(mockAchievementService.getProgress(userId, 'season_warrior'))
            .thenAnswer((_) async => PlayerAchievement(
                  userId: userId,
                  achievementId: 'season_warrior',
                ));

        when(mockAchievementService.unlockAchievement(userId, 'season_warrior'))
            .thenAnswer((_) async {});

        final result = await detector.checkSeasonalTriggers(
          userId,
          seasonsParticipated: 10,
          consistentSeasons: 3,
          currentTier: 'Gold',
          tierChanged: false,
        );

        expect(result, isNotEmpty);
        verify(mockAchievementService.unlockAchievement(
          userId,
          'season_warrior',
        )).called(1);
      });

      test('triggers Consistency at 3+ seasons in Gold tier', () async {
        when(mockAchievementService.getProgress(userId, 'consistency'))
            .thenAnswer((_) async => PlayerAchievement(
                  userId: userId,
                  achievementId: 'consistency',
                ));

        when(mockAchievementService.unlockAchievement(userId, 'consistency'))
            .thenAnswer((_) async {});

        final result = await detector.checkSeasonalTriggers(
          userId,
          seasonsParticipated: 10,
          consistentSeasons: 3,
          currentTier: 'Gold',
          tierChanged: false,
        );

        expect(result, isNotEmpty);
        verify(mockAchievementService.unlockAchievement(
          userId,
          'consistency',
        )).called(1);
      });

      test('does not trigger Consistency below 3 seasons', () async {
        when(mockAchievementService.getProgress(userId, 'consistency'))
            .thenAnswer((_) async => PlayerAchievement(
                  userId: userId,
                  achievementId: 'consistency',
                ));

        final result = await detector.checkSeasonalTriggers(
          userId,
          seasonsParticipated: 5,
          consistentSeasons: 2,
          currentTier: 'Gold',
          tierChanged: false,
        );

        verifyNever(mockAchievementService.unlockAchievement(
          any,
          any,
        ));
      });

      test('does not trigger Consistency in non-Gold tiers', () async {
        when(mockAchievementService.getProgress(userId, 'consistency'))
            .thenAnswer((_) async => PlayerAchievement(
                  userId: userId,
                  achievementId: 'consistency',
                ));

        final result = await detector.checkSeasonalTriggers(
          userId,
          seasonsParticipated: 5,
          consistentSeasons: 3,
          currentTier: 'Silver',
          tierChanged: false,
        );

        verifyNever(mockAchievementService.unlockAchievement(
          any,
          any,
        ));
      });
    });

    group('checkSpecialTriggers', () {
      test('identifies perfect win conditions', () async {
        final result = await detector.checkSpecialTriggers(
          userId,
          isFirstBattle: false,
          isPerfectWin: true,
          hasKilledAllEnemies: true,
        );

        // Special achievements deferred to achievement_service
        expect(result, isEmpty);
      });

      test('identifies first battle condition', () async {
        final result = await detector.checkSpecialTriggers(
          userId,
          isFirstBattle: true,
          isPerfectWin: false,
          hasKilledAllEnemies: false,
        );

        expect(result, isEmpty);
      });
    });

    group('checkAllTriggersForBattle', () {
      test('checks all trigger types in single call', () async {
        when(mockAchievementService.getProgress(userId, 'aha_moment'))
            .thenAnswer((_) async => PlayerAchievement(
                  userId: userId,
                  achievementId: 'aha_moment',
                ));

        when(mockAchievementService.getProgress(userId, 'rising_star'))
            .thenAnswer((_) async => PlayerAchievement(
                  userId: userId,
                  achievementId: 'rising_star',
                ));

        when(mockAchievementService.unlockAchievement(any, any))
            .thenAnswer((_) async {});

        final result = await detector.checkAllTriggersForBattle(
          userId,
          kills: 1,
          totalKills: 1,
          won: true,
          deaths: 0,
          assists: 2,
          damageDealt: 600,
          totalBattles: 5,
          winCount: 2,
          statPoints: 60,
          pathDiversity: 3,
          seasonsParticipated: 10,
          consistentSeasons: 3,
          currentTier: 'Gold',
        );

        // Should trigger both Aha Moment and Rising Star
        expect(result.length, greaterThanOrEqualTo(2));
      });

      test('handles multiple achievement unlocks', () async {
        when(mockAchievementService.getProgress(any, any))
            .thenAnswer((_) async => PlayerAchievement(
                  userId: userId,
                  achievementId: 'test_achievement',
                ));

        when(mockAchievementService.unlockAchievement(any, any))
            .thenAnswer((_) async {});

        final result = await detector.checkAllTriggersForBattle(
          userId,
          kills: 1,
          totalKills: 1,
          won: true,
          deaths: 0,
          assists: 0,
          damageDealt: 500,
          totalBattles: 1,
          winCount: 1,
          statPoints: 50,
          pathDiversity: 3,
          seasonsParticipated: 10,
          consistentSeasons: 3,
          currentTier: 'Gold',
        );

        expect(result, isA<List<Achievement>>());
      });

      test('returns empty list on error', () async {
        when(mockAchievementService.getProgress(any, any))
            .thenThrow(Exception('Service error'));

        final result = await detector.checkAllTriggersForBattle(
          userId,
          kills: 1,
          totalKills: 1,
          won: true,
          deaths: 0,
          assists: 0,
          damageDealt: 500,
          totalBattles: 1,
          winCount: 1,
          statPoints: 50,
          pathDiversity: 3,
          seasonsParticipated: 10,
          consistentSeasons: 3,
          currentTier: 'Gold',
        );

        expect(result, isEmpty);
      });
    });

    group('debugGetTriggerConditions', () {
      test('returns trigger info for Aha Moment', () {
        final info = detector.debugGetTriggerConditions('aha_moment');
        expect(info['type'], equals('kill'));
        expect(info['trigger_type'], equals('first_event'));
        expect(info['trigger_value'], equals(1));
      });

      test('returns trigger info for Rising Star', () {
        final info = detector.debugGetTriggerConditions('rising_star');
        expect(info['type'], equals('battle_completion'));
        expect(info['trigger_type'], equals('win_condition'));
      });

      test('returns trigger info for Stat Master', () {
        final info = detector.debugGetTriggerConditions('stat_master');
        expect(info['type'], equals('progress'));
        expect(info['trigger_value'], equals(50));
      });

      test('returns trigger info for Balanced Fighter', () {
        final info = detector.debugGetTriggerConditions('balanced_fighter');
        expect(info['type'], equals('progress'));
        expect(info['trigger_value'], equals(3));
      });

      test('returns trigger info for Season Warrior', () {
        final info = detector.debugGetTriggerConditions('season_warrior');
        expect(info['type'], equals('seasonal'));
        expect(info['trigger_value'], equals(10));
      });

      test('returns trigger info for Consistency', () {
        final info = detector.debugGetTriggerConditions('consistency');
        expect(info['type'], equals('seasonal'));
        expect(info['trigger_value'], equals(3));
      });

      test('returns trigger info for Speedrunner', () {
        final info = detector.debugGetTriggerConditions('speedrunner');
        expect(info['type'], equals('battle_completion'));
        expect(info['trigger_type'], equals('time_limit'));
        expect(info['trigger_value'], equals(120));
      });

      test('returns trigger info for Collector', () {
        final info = detector.debugGetTriggerConditions('collector');
        expect(info['type'], equals('special'));
        expect(info['trigger_type'], equals('meta'));
      });

      test('returns unknown for unrecognized achievement', () {
        final info = detector.debugGetTriggerConditions('unknown_achievement');
        expect(info['type'], equals('unknown'));
        expect(info['trigger_type'], equals('unknown'));
      });

      test('returns all trigger info keys', () {
        final info = detector.debugGetTriggerConditions('aha_moment');
        expect(info.containsKey('type'), isTrue);
        expect(info.containsKey('condition'), isTrue);
        expect(info.containsKey('trigger_value'), isTrue);
        expect(info.containsKey('trigger_type'), isTrue);
      });
    });
  });
}
