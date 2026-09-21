import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';
import 'package:shinjuu_league/services/firestore_service.dart';
import 'package:shinjuu_league/services/season_reward_service.dart';
import 'package:shinjuu_league/viewmodels/season_reward_viewmodel.dart';

void main() {
  group('seasonRewardServiceProvider', () {
    test(
      'resolves to a real SeasonRewardService instead of throwing UnimplementedError',
      () {
        // Regression guard: this provider used to be a bare
        // `throw UnimplementedError('...must be provided by the
        // application')` placeholder that nothing in the app ever
        // overrode, so opening SeasonRewardsScreen (or anything else
        // reading this provider) would have crashed immediately.
        final container = ProviderContainer(
          overrides: [
            firestoreServiceProvider.overrideWithValue(
              FirestoreService.forFirestore(FakeFirebaseFirestore()),
            ),
          ],
        );
        addTearDown(container.dispose);

        expect(
          () => container.read(seasonRewardServiceProvider),
          returnsNormally,
        );
        expect(
          container.read(seasonRewardServiceProvider),
          isA<SeasonRewardService>(),
        );
      },
    );
  });
}
