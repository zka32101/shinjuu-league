import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/services/ranking_service.dart';
import 'package:shinjuu_league/services/season_service.dart';

void main() {
  group('RankingService.getSeasonHistory', () {
    late FakeFirebaseFirestore firestore;
    late RankingService rankingService;
    late SeasonService seasonService;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      rankingService = RankingService(firestore: firestore);
      seasonService = SeasonService(firestore: firestore);
    });

    Future<void> seedSeason(
      String seasonId,
      String name,
      DateTime startedAt,
    ) async {
      await firestore.collection('seasons').doc(seasonId).set({
        'seasonId': seasonId,
        'name': name,
        'startedAt': startedAt.toIso8601String(),
        'endsAt': startedAt.add(const Duration(days: 30)).toIso8601String(),
        'isActive': false,
        'tierThresholds': <String, int>{},
        'rewardsByTier': <String, List<String>>{},
        'rules': {
          'kFactorMultiplier': 1.0,
          'minEntryRating': 400,
          'theme': 'Standard',
        },
        'createdAt': startedAt.toIso8601String(),
        'updatedAt': startedAt.toIso8601String(),
      });
    }

    Future<void> seedSeasonData(
      String userId,
      String seasonId, {
      required int startingRating,
      required int peakRating,
      required int currentRating,
      required String peakTier,
      int seasonWins = 0,
      int seasonLosses = 0,
    }) async {
      await firestore
          .collection('users/$userId/season_data')
          .doc(seasonId)
          .set({
            'userId': userId,
            'seasonId': seasonId,
            'startingRating': startingRating,
            'peakRating': peakRating,
            'currentRating': currentRating,
            'peakTier': peakTier,
            'seasonWins': seasonWins,
            'seasonLosses': seasonLosses,
          });
    }

    test('returns an empty list for a user with no season history', () async {
      final history = await rankingService.getSeasonHistory(
        'no-such-user',
        seasonService: seasonService,
      );
      expect(history, isEmpty);
    });

    test(
      'returns entries ordered oldest-to-newest by season start date',
      () async {
        await seedSeason('season-2', 'Season 2', DateTime(2026, 3, 1));
        await seedSeason('season-1', 'Season 1', DateTime(2026, 1, 1));
        await seedSeason('season-3', 'Season 3', DateTime(2026, 5, 1));

        // Seeded out of chronological order on purpose, to prove sorting works.
        await seedSeasonData(
          'user-a',
          'season-2',
          startingRating: 1200,
          peakRating: 1500,
          currentRating: 1400,
          peakTier: 'Silver',
        );
        await seedSeasonData(
          'user-a',
          'season-1',
          startingRating: 1200,
          peakRating: 1300,
          currentRating: 1250,
          peakTier: 'Bronze',
        );
        await seedSeasonData(
          'user-a',
          'season-3',
          startingRating: 1400,
          peakRating: 1900,
          currentRating: 1800,
          peakTier: 'Gold',
        );

        final history = await rankingService.getSeasonHistory(
          'user-a',
          seasonService: seasonService,
        );

        expect(history.map((e) => e.seasonId).toList(), [
          'season-1',
          'season-2',
          'season-3',
        ]);
        expect(history.map((e) => e.seasonName).toList(), [
          'Season 1',
          'Season 2',
          'Season 3',
        ]);
      },
    );

    test(
      'carries over rating and tier fields correctly for a season',
      () async {
        await seedSeason('season-1', 'Season 1', DateTime(2026, 1, 1));
        await seedSeasonData(
          'user-a',
          'season-1',
          startingRating: 1200,
          peakRating: 1650,
          currentRating: 1600,
          peakTier: 'Silver',
          seasonWins: 20,
          seasonLosses: 12,
        );

        final history = await rankingService.getSeasonHistory(
          'user-a',
          seasonService: seasonService,
        );

        expect(history, hasLength(1));
        final entry = history.first;
        expect(entry.startingRating, 1200);
        expect(entry.peakRating, 1650);
        expect(entry.finalRating, 1600);
        expect(entry.peakTier, 'Silver');
        expect(entry.seasonWins, 20);
        expect(entry.seasonLosses, 12);
      },
    );

    test(
      'falls back to the seasonId as a display name if the season document was deleted',
      () async {
        // No matching doc in `seasons` for this seasonId — simulates a
        // deleted/missing season document without crashing the history screen.
        await seedSeasonData(
          'user-a',
          'orphaned-season',
          startingRating: 1200,
          peakRating: 1300,
          currentRating: 1250,
          peakTier: 'Bronze',
        );

        final history = await rankingService.getSeasonHistory(
          'user-a',
          seasonService: seasonService,
        );

        expect(history, hasLength(1));
        expect(history.first.seasonName, 'orphaned-season');
        expect(history.first.startedAt, isNull);
      },
    );

    test('does not mix up season history between different users', () async {
      await seedSeason('season-1', 'Season 1', DateTime(2026, 1, 1));
      await seedSeasonData(
        'user-a',
        'season-1',
        startingRating: 1200,
        peakRating: 1300,
        currentRating: 1250,
        peakTier: 'Bronze',
      );
      await seedSeasonData(
        'user-b',
        'season-1',
        startingRating: 1200,
        peakRating: 2000,
        currentRating: 1900,
        peakTier: 'Platinum',
      );

      final historyA = await rankingService.getSeasonHistory(
        'user-a',
        seasonService: seasonService,
      );
      final historyB = await rankingService.getSeasonHistory(
        'user-b',
        seasonService: seasonService,
      );

      expect(historyA.single.peakTier, 'Bronze');
      expect(historyB.single.peakTier, 'Platinum');
    });
  });
}
