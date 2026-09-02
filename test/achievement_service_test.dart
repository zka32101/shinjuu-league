import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/services/achievement_service.dart';

void main() {
  group('AchievementService', () {
    late AchievementService achievementService;

    setUp(() {
      achievementService = AchievementService();
    });

    group('Initialization', () {
      test('init completes without error', () async {
        expect(
          () async => await achievementService.init(),
          returnsNormally,
        );
      });

      test('initially no achievements unlocked', () async {
        await achievementService.init();
        expect(achievementService.unlockedAchievements, isEmpty);
      });
    });

    group('Tutorial Achievement', () {
      test('tutorial_complete unlocks on event', () async {
        final event = AchievementProgressEvent(
          type: AchievementEventType.tutorialComplete,
        );

        final unlocked = achievementService.updateProgress(event);

        expect(unlocked, contains('tutorial_complete'));
        expect(
          achievementService.unlockedAchievements,
          contains('tutorial_complete'),
        );
      });

      test('tutorial_complete cannot be unlocked twice', () async {
        final event = AchievementProgressEvent(
          type: AchievementEventType.tutorialComplete,
        );

        achievementService.updateProgress(event);
        final secondUnlock = achievementService.updateProgress(event);

        expect(secondUnlock, isEmpty);
      });
    });

    group('Kill Achievements', () {
      test('first_kill unlocks on first kill event', () async {
        final event = AchievementProgressEvent(
          type: AchievementEventType.firstKill,
        );

        final unlocked = achievementService.updateProgress(event);

        expect(unlocked, contains('first_kill'));
      });

      test('ten_kills tracks cumulative kills', () async {
        for (int i = 0; i < 10; i++) {
          final event = AchievementProgressEvent(
            type: AchievementEventType.killCountIncrement,
          );
          final unlocked = achievementService.updateProgress(event);

          if (i < 9) {
            expect(unlocked, isEmpty);
          } else {
            expect(unlocked, contains('ten_kills'));
          }
        }
      });

      test('kill_streak_3 requires 3 consecutive kills', () async {
        final event = AchievementProgressEvent(
          type: AchievementEventType.killStreakIncrement,
          data: {'streak': 3},
        );

        final unlocked = achievementService.updateProgress(event);

        expect(unlocked, contains('kill_streak_3'));
      });
    });

    group('Ranked Achievements', () {
      test('first_ranked_match unlocks on ranked battle', () async {
        final event = AchievementProgressEvent(
          type: AchievementEventType.battleCompleted,
          data: {'is_ranked': true, 'is_win': false},
        );

        final unlocked = achievementService.updateProgress(event);

        expect(unlocked, contains('first_ranked_match'));
      });

      test('win_streak_5 requires 5 ranked wins', () async {
        final unlocked = <String>[];

        for (int i = 0; i < 5; i++) {
          final event = AchievementProgressEvent(
            type: AchievementEventType.battleCompleted,
            data: {'is_ranked': true, 'is_win': true},
          );

          final result = achievementService.updateProgress(event);
          unlocked.addAll(result);
        }

        expect(unlocked, contains('win_streak_5'));
      });

      test('non-ranked wins do not count toward win_streak_5', () async {
        for (int i = 0; i < 5; i++) {
          final event = AchievementProgressEvent(
            type: AchievementEventType.battleCompleted,
            data: {'is_ranked': false, 'is_win': true},
          );

          achievementService.updateProgress(event);
        }

        expect(
          achievementService.unlockedAchievements,
          isNot(contains('win_streak_5')),
        );
      });
    });

    group('Monetization Achievements', () {
      test('first_battlepass unlocks on purchase', () async {
        final event = AchievementProgressEvent(
          type: AchievementEventType.battlePassPurchased,
        );

        final unlocked = achievementService.updateProgress(event);

        expect(unlocked, contains('first_battlepass'));
      });

      test('skin_collector tracks owned skins', () async {
        final event = AchievementProgressEvent(
          type: AchievementEventType.skinPurchased,
          data: {'owned_skins': 3},
        );

        final unlocked = achievementService.updateProgress(event);

        expect(unlocked, contains('skin_collector'));
      });

      test('skin_collector requires 3 unique skins', () async {
        final event2 = AchievementProgressEvent(
          type: AchievementEventType.skinPurchased,
          data: {'owned_skins': 2},
        );

        final unlocked = achievementService.updateProgress(event2);

        expect(unlocked, isEmpty);
      });
    });

    group('Social Achievements', () {
      test('social_butterfly tracks friends', () async {
        final event = AchievementProgressEvent(
          type: AchievementEventType.friendAdded,
          data: {'friend_count': 3},
        );

        final unlocked = achievementService.updateProgress(event);

        expect(unlocked, contains('social_butterfly'));
      });

      test('guild_founder unlocks on creation', () async {
        final event = AchievementProgressEvent(
          type: AchievementEventType.guildCreated,
        );

        final unlocked = achievementService.updateProgress(event);

        expect(unlocked, contains('guild_founder'));
      });
    });

    group('Progress Tracking', () {
      test('getProgress returns correct value', () async {
        final killEvent = AchievementProgressEvent(
          type: AchievementEventType.killCountIncrement,
        );

        achievementService.updateProgress(killEvent);
        achievementService.updateProgress(killEvent);

        expect(achievementService.getProgress('total_kills'), equals(2));
      });

      test('level_up tracks player level', () async {
        final event = AchievementProgressEvent(
          type: AchievementEventType.levelUp,
          data: {'level': 5},
        );

        achievementService.updateProgress(event);

        expect(achievementService.getProgress('player_level'), equals(5));
      });

      test('level_10 achievement unlocks at level 10', () async {
        final event = AchievementProgressEvent(
          type: AchievementEventType.levelUp,
          data: {'level': 10},
        );

        final unlocked = achievementService.updateProgress(event);

        expect(unlocked, contains('level_10'));
      });
    });

    group('Achievement Catalog', () {
      test('getAllAchievements returns all 11 achievements', () async {
        final achievements = achievementService.getAllAchievements();

        expect(achievements.length, equals(11));
      });

      test('getAchievementDetails returns complete info', () async {
        final achievement =
            achievementService.getAchievementDetails('first_kill');

        expect(achievement, isNotNull);
        expect(achievement!.name, isNotEmpty);
        expect(achievement.description, isNotEmpty);
        expect(achievement.icon, isNotEmpty);
      });

      test('achievement has rarity level', () async {
        final achievement =
            achievementService.getAchievementDetails('first_kill');

        expect(achievement!.rarity, isA<AchievementRarity>());
      });

      test('all achievements have unique IDs', () async {
        final achievements = achievementService.getAllAchievements();
        final ids = achievements.map((a) => a.id).toSet();

        expect(ids.length, equals(achievements.length));
      });
    });

    group('Debug Utilities', () {
      test('debugDumpAchievements returns valid structure', () async {
        final dump = achievementService.debugDumpAchievements();

        expect(dump, containsPair('unlocked_count', isA<int>()));
        expect(dump, containsPair('total_count', isA<int>()));
        expect(dump, containsPair('unlocked_list', isA<List>()));
        expect(dump, containsPair('progress', isA<Map>()));
      });

      test('debug unlock adds achievement', () async {
        achievementService.debugUnlockAchievement('test_achievement');

        expect(
          achievementService.unlockedAchievements,
          contains('test_achievement'),
        );
      });
    });

    group('Singleton Pattern', () {
      test('multiple instances refer to same object', () {
        final service1 = AchievementService();
        final service2 = AchievementService();

        expect(identical(service1, service2), isTrue);
      });

      test('achievements persist across instances', () async {
        final service1 = AchievementService();
        final event = AchievementProgressEvent(
          type: AchievementEventType.tutorialComplete,
        );

        service1.updateProgress(event);

        final service2 = AchievementService();
        expect(
          service2.unlockedAchievements,
          contains('tutorial_complete'),
        );
      });
    });

    group('AchievementRarity', () {
      test('rarity enum has correct labels', () {
        expect(AchievementRarity.common.label, isNotEmpty);
        expect(AchievementRarity.rare.label, isNotEmpty);
        expect(AchievementRarity.legendary.label, isNotEmpty);
      });
    });
  });
}
