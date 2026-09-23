import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/data/models/achievement.dart';
import 'package:shinjuu_league/services/achievement_reward_service.dart';
import 'package:shinjuu_league/services/achievement_service.dart';
import 'package:shinjuu_league/services/achievement_trigger_detector.dart';

class MockAchievementService extends Mock implements AchievementService {
  @override
  Future<List<PlayerAchievement>> getUnlockedAchievements(String? userId) {
    return super.noSuchMethod(
          Invocation.method(#getUnlockedAchievements, [userId]),
          returnValue: Future<List<PlayerAchievement>>.value(
            <PlayerAchievement>[],
          ),
          returnValueForMissingStub: Future<List<PlayerAchievement>>.value(
            <PlayerAchievement>[],
          ),
        )
        as Future<List<PlayerAchievement>>;
  }
}

/// Records every unlock+reward call instead of actually granting anything -
/// this test suite only cares about WHICH achievement got unlocked, not the
/// reward amounts (AchievementRewardService's own tests cover those).
class FakeAchievementRewardService implements AchievementRewardService {
  final List<String> unlockedAchievementIds = [];

  @override
  Future<Map<String, dynamic>> processUnlock(
    String userId,
    Achievement achievement,
  ) async {
    unlockedAchievementIds.add(achievement.achievementId);
    return {'currency': 0, 'badges': 0, 'cosmetics': <String>[]};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AchievementTriggerDetector', () {
    late AchievementTriggerDetector detector;
    late MockAchievementService mockAchievementService;
    late FakeAchievementRewardService fakeRewardService;

    const String userId = 'user_123';

    setUp(() {
      mockAchievementService = MockAchievementService();
      fakeRewardService = FakeAchievementRewardService();
      detector = AchievementTriggerDetector(
        achievementService: mockAchievementService,
        rewardService: fakeRewardService,
      );
    });

    group('checkKillTriggers', () {
      test('triggers Aha Moment on first kill', () async {
        when(
          mockAchievementService.getUnlockedAchievements(userId),
        ).thenAnswer((_) async => []);

        final result = await detector.checkKillTriggers(userId, 1, 1);

        expect(result, isNotEmpty);
        expect(
          fakeRewardService.unlockedAchievementIds,
          contains('aha_moment'),
        );
      });

      // Real regression guard: this used to check `kills == 1` exactly, so
      // a player who got MORE than one kill in their very first battle
      // would never be credited with the flagship "aha_moment_reached" KPI
      // achievement at all. `kills >= 1` is the correct "got at least one
      // kill" condition.
      test(
        'also triggers Aha Moment when a player gets multiple kills',
        () async {
          when(
            mockAchievementService.getUnlockedAchievements(userId),
          ).thenAnswer((_) async => []);

          final result = await detector.checkKillTriggers(userId, 3, 5);

          expect(result, isNotEmpty);
          expect(
            fakeRewardService.unlockedAchievementIds,
            contains('aha_moment'),
          );
        },
      );

      test('does not trigger Aha Moment on zero kills', () async {
        final result = await detector.checkKillTriggers(userId, 0, 0);
        expect(result, isEmpty);
      });

      test('returns empty list on error', () async {
        when(
          mockAchievementService.getUnlockedAchievements(userId),
        ).thenThrow(Exception('Service error'));

        final result = await detector.checkKillTriggers(userId, 1, 1);
        expect(result, isEmpty);
      });
    });

    group('checkBattleCompletionTriggers', () {
      // Real regression guard: this used to unlock Rising Star on ANY
      // single win, contradicting its own catalog description ("最初の5
      // シーズンでシルバーティアに到達"). It now requires being within the
      // first 5 seasons AND at Silver tier or better.
      test(
        'triggers Rising Star within the first 5 seasons at Silver+ tier',
        () async {
          when(
            mockAchievementService.getUnlockedAchievements(userId),
          ).thenAnswer((_) async => []);

          final result = await detector.checkBattleCompletionTriggers(
            userId,
            won: true,
            kills: 2,
            deaths: 1,
            assists: 1,
            damageDealt: 500,
            totalBattles: 5,
            winCount: 2,
            seasonsParticipated: 3,
            currentTier: 'Silver',
          );

          expect(result, isNotEmpty);
          expect(
            fakeRewardService.unlockedAchievementIds,
            contains('rising_star'),
          );
        },
      );

      test(
        'does not trigger Rising Star past the first 5 seasons even at Silver+',
        () async {
          final result = await detector.checkBattleCompletionTriggers(
            userId,
            won: true,
            kills: 2,
            deaths: 1,
            assists: 1,
            damageDealt: 500,
            totalBattles: 20,
            winCount: 10,
            seasonsParticipated: 6,
            currentTier: 'Gold',
          );

          expect(result, isEmpty);
          expect(fakeRewardService.unlockedAchievementIds, isEmpty);
        },
      );

      test(
        'does not trigger Rising Star while still below Silver tier',
        () async {
          final result = await detector.checkBattleCompletionTriggers(
            userId,
            won: true,
            kills: 1,
            deaths: 2,
            assists: 0,
            damageDealt: 300,
            totalBattles: 2,
            winCount: 1,
            seasonsParticipated: 1,
            currentTier: 'Bronze',
          );

          expect(result, isEmpty);
          expect(fakeRewardService.unlockedAchievementIds, isEmpty);
        },
      );

      test('does not trigger if already unlocked', () async {
        when(mockAchievementService.getUnlockedAchievements(userId)).thenAnswer(
          (_) async => [
            PlayerAchievement(
              userId: userId,
              achievementId: 'rising_star',
              unlockedAt: DateTime.now(),
            ),
          ],
        );

        final result = await detector.checkBattleCompletionTriggers(
          userId,
          won: true,
          kills: 2,
          deaths: 1,
          assists: 1,
          damageDealt: 500,
          totalBattles: 5,
          winCount: 2,
          seasonsParticipated: 2,
          currentTier: 'Silver',
        );

        expect(result, isEmpty);
      });
    });

    group('checkProgressTriggers', () {
      // Real regression guard: statMaster's threshold used to be a
      // hard-coded 50, impossible under the real skill tree's 5-tier-per-
      // branch cap. It's read from AchievementsCatalog.statMaster.maxProgress
      // (5) now.
      test('triggers Stat Master at the catalog threshold (5)', () async {
        when(
          mockAchievementService.getUnlockedAchievements(userId),
        ).thenAnswer((_) async => []);

        final result = await detector.checkProgressTriggers(
          userId,
          statPoints: AchievementsCatalog.statMaster.maxProgress,
          pathDiversity: 1,
          seasonsParticipated: 1,
          consistentSeasons: 0,
          currentTier: 'Bronze',
        );

        expect(result, isNotEmpty);
        expect(
          fakeRewardService.unlockedAchievementIds,
          contains('stat_master'),
        );
      });

      test('triggers Balanced Fighter with 3-path diversity', () async {
        when(
          mockAchievementService.getUnlockedAchievements(userId),
        ).thenAnswer((_) async => []);

        final result = await detector.checkProgressTriggers(
          userId,
          statPoints: 2,
          pathDiversity: 3,
          seasonsParticipated: 1,
          consistentSeasons: 0,
          currentTier: 'Silver',
        );

        expect(result, isNotEmpty);
        expect(
          fakeRewardService.unlockedAchievementIds,
          contains('balanced_fighter'),
        );
      });

      test(
        'does not trigger Stat Master below the catalog threshold',
        () async {
          final result = await detector.checkProgressTriggers(
            userId,
            statPoints: AchievementsCatalog.statMaster.maxProgress - 1,
            pathDiversity: 1,
            seasonsParticipated: 1,
            consistentSeasons: 0,
            currentTier: 'Bronze',
          );

          expect(result, isEmpty);
          expect(fakeRewardService.unlockedAchievementIds, isEmpty);
        },
      );

      test(
        'does not trigger Balanced Fighter with insufficient diversity',
        () async {
          final result = await detector.checkProgressTriggers(
            userId,
            // statPoints must stay below the Stat Master threshold here, or
            // it would also satisfy that unrelated check and make `result`
            // non-empty regardless of this test's actual target (insufficient
            // path diversity).
            statPoints: 1,
            pathDiversity: 2,
            seasonsParticipated: 1,
            consistentSeasons: 0,
            currentTier: 'Silver',
          );

          expect(result, isEmpty);
          expect(fakeRewardService.unlockedAchievementIds, isEmpty);
        },
      );
    });

    group('checkSeasonalTriggers', () {
      test('triggers Season Warrior at 10 seasons', () async {
        when(
          mockAchievementService.getUnlockedAchievements(userId),
        ).thenAnswer((_) async => []);

        final result = await detector.checkSeasonalTriggers(
          userId,
          seasonsParticipated: 10,
          consistentSeasons: 3,
          currentTier: 'Gold',
          tierChanged: false,
        );

        expect(result, isNotEmpty);
        expect(
          fakeRewardService.unlockedAchievementIds,
          contains('season_warrior'),
        );
      });

      test('triggers Consistency at 3+ seasons in Gold tier', () async {
        when(
          mockAchievementService.getUnlockedAchievements(userId),
        ).thenAnswer((_) async => []);

        final result = await detector.checkSeasonalTriggers(
          userId,
          seasonsParticipated: 10,
          consistentSeasons: 3,
          currentTier: 'Gold',
          tierChanged: false,
        );

        expect(result, isNotEmpty);
        expect(
          fakeRewardService.unlockedAchievementIds,
          contains('consistency'),
        );
      });

      // Real regression guard: this used to require currentTier to be
      // EXACTLY 'gold' (case-insensitive), so a player who kept climbing to
      // Platinum or Diamond - still "Gold+" per the achievement's own
      // description - would never satisfy it.
      test('also triggers Consistency at tiers above Gold', () async {
        when(
          mockAchievementService.getUnlockedAchievements(userId),
        ).thenAnswer((_) async => []);

        final result = await detector.checkSeasonalTriggers(
          userId,
          seasonsParticipated: 10,
          consistentSeasons: 3,
          currentTier: 'Platinum',
          tierChanged: false,
        );

        expect(result, isNotEmpty);
        expect(
          fakeRewardService.unlockedAchievementIds,
          contains('consistency'),
        );
      });

      test('does not trigger Consistency below 3 seasons', () async {
        final result = await detector.checkSeasonalTriggers(
          userId,
          seasonsParticipated: 5,
          consistentSeasons: 2,
          currentTier: 'Gold',
          tierChanged: false,
        );

        expect(result, isEmpty);
        expect(fakeRewardService.unlockedAchievementIds, isEmpty);
      });

      test('does not trigger Consistency below Gold tier', () async {
        final result = await detector.checkSeasonalTriggers(
          userId,
          seasonsParticipated: 5,
          consistentSeasons: 3,
          currentTier: 'Silver',
          tierChanged: false,
        );

        expect(result, isEmpty);
        expect(fakeRewardService.unlockedAchievementIds, isEmpty);
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
        when(
          mockAchievementService.getUnlockedAchievements(userId),
        ).thenAnswer((_) async => []);

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
          statPoints: AchievementsCatalog.statMaster.maxProgress,
          pathDiversity: 3,
          seasonsParticipated: 3,
          consistentSeasons: 3,
          currentTier: 'Gold',
        );

        // Should trigger Aha Moment, Rising Star, Stat Master and
        // Balanced Fighter (season/tier/stat thresholds are all satisfied,
        // Season Warrior/Consistency need 10/3 seasons respectively -
        // seasonsParticipated=3 only satisfies Consistency's 3-season bar).
        expect(result.length, greaterThanOrEqualTo(4));
      });

      test('handles multiple achievement unlocks', () async {
        when(
          mockAchievementService.getUnlockedAchievements(any),
        ).thenAnswer((_) async => []);

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
          statPoints: AchievementsCatalog.statMaster.maxProgress,
          pathDiversity: 3,
          seasonsParticipated: 10,
          consistentSeasons: 3,
          currentTier: 'Gold',
        );

        expect(result, isA<List<Achievement>>());
      });

      test('returns empty list on error', () async {
        when(
          mockAchievementService.getUnlockedAchievements(any),
        ).thenThrow(Exception('Service error'));

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
          statPoints: AchievementsCatalog.statMaster.maxProgress,
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
        expect(info['type'], equals('seasonal'));
        expect(info['trigger_type'], equals('season_and_tier'));
      });

      test('returns trigger info for Stat Master', () {
        final info = detector.debugGetTriggerConditions('stat_master');
        expect(info['type'], equals('progress'));
        expect(
          info['trigger_value'],
          equals(AchievementsCatalog.statMaster.maxProgress),
        );
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

  group('tierAtLeast', () {
    test('is true for a tier exactly matching the minimum', () {
      expect(tierAtLeast('Gold', 'Gold'), isTrue);
    });

    test('is true for a tier above the minimum', () {
      expect(tierAtLeast('Platinum', 'Gold'), isTrue);
      expect(tierAtLeast('Diamond', 'Gold'), isTrue);
    });

    test('is false for a tier below the minimum', () {
      expect(tierAtLeast('Silver', 'Gold'), isFalse);
      expect(tierAtLeast('Bronze', 'Gold'), isFalse);
    });

    test('is false for an unrecognized tier name rather than throwing', () {
      expect(tierAtLeast('Unobtainium', 'Gold'), isFalse);
      expect(tierAtLeast('Gold', 'Unobtainium'), isFalse);
    });
  });
}
