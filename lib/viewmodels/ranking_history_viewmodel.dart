import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';
import 'package:shinjuu_league/services/ranking_service.dart';

/// Fetches a user's season-over-season rating/tier history for the
/// ranking history screen. autoDispose + family(userId) so switching
/// between users (or leaving the screen) doesn't leak stale state.
final rankingHistoryProvider = FutureProvider.family
    .autoDispose<List<SeasonHistoryEntry>, String>((ref, userId) async {
      final rankingService = ref.watch(rankingServiceProvider);
      final seasonService = ref.watch(seasonServiceProvider);
      return rankingService.getSeasonHistory(
        userId,
        seasonService: seasonService,
      );
    });
