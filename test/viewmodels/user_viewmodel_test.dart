import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/models/user_model.dart' as app;
import 'package:shinjuu_league/services/auth_service.dart';
import 'package:shinjuu_league/services/firestore_service.dart';
import 'package:shinjuu_league/services/ranking_service.dart';
import 'package:shinjuu_league/services/season_service.dart';
import 'package:shinjuu_league/viewmodels/user_viewmodel.dart';

class MockAuthService extends Mock implements AuthService {}

class MockUser implements User {
  MockUser(this.uid);

  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('UserViewModel.applyBattleResult', () {
    const uid = 'test_user';
    late FakeFirebaseFirestore firestore;
    late MockAuthService mockAuthService;
    late UserViewModel viewModel;

    Battle battle({
      required BattleResult result,
      required List<String> opponentIds,
    }) {
      return Battle(
        battleId: 'battle_1',
        userId: uid,
        opponentIds: opponentIds,
        mapId: 'map_01',
        mode: BattleMode.quick,
        durationSeconds: 300,
        playerStats: const [],
        result: result,
        eloChange: 16.0,
        startedAt: DateTime(2026, 1, 1),
        endedAt: DateTime(2026, 1, 1, 0, 5),
      );
    }

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      mockAuthService = MockAuthService();
      when(mockAuthService.currentUser).thenReturn(MockUser(uid));

      final baseUser = app.User(
        uid: uid,
        name: 'Tester',
        rank: 0,
        level: 1,
        eloRating: 1000.0,
        winRate: 0.0,
        totalWins: 0,
        totalBattles: 0,
        gems: 0,
        gold: 0,
        createdAt: DateTime(2026, 1, 1),
        lastBattleAt: DateTime(2026, 1, 1),
      );
      await firestore.collection('users').doc(uid).set(baseUser.toJson());

      viewModel = UserViewModel(
        firestoreService: FirestoreService.forFirestore(firestore),
        authService: mockAuthService,
        rankingService: RankingService(firestore: firestore),
        seasonService: SeasonService(firestore: firestore),
      );

      // Let _init()'s watchUser stream deliver the seeded document.
      await Future.delayed(const Duration(milliseconds: 50));
    });

    tearDown(() {
      viewModel.dispose();
    });

    test(
      'submits a battle_results document instead of writing eloRating/stats directly',
      () async {
        await viewModel.applyBattleResult(
          battle(
            result: BattleResult.win,
            opponentIds: ['real_opp_1', 'bot_abcd1234', 'real_opp_2'],
          ),
        );

        final results = await firestore.collection('battle_results').get();
        expect(results.docs, hasLength(1));
        final data = results.docs.first.data();
        expect(data['battleId'], 'battle_1');
        expect(data['userId'], uid);
        expect(data['result'], 'win');
        expect(
          data['opponentUserIds'],
          containsAll(<String>['real_opp_1', 'real_opp_2']),
        );
        expect(data['opponentUserIds'], hasLength(2));

        // The client must never write eloRating/winRate/totalWins/totalBattles
        // directly any more - Firestore Rules now block that, and the real
        // update is reserved for the elo-validator Cloud Function reacting
        // to the battle_results document above.
        final userDoc = await firestore.collection('users').doc(uid).get();
        expect(userDoc.data()!['eloRating'], 1000.0);
        expect(userDoc.data()!['totalWins'], 0);
        expect(userDoc.data()!['totalBattles'], 0);
        expect(userDoc.data()!['winRate'], 0.0);
      },
    );

    test('filters an all-bot opposing team down to an empty list', () async {
      await viewModel.applyBattleResult(
        battle(result: BattleResult.loss, opponentIds: ['bot_1', 'bot_2']),
      );

      final results = await firestore.collection('battle_results').get();
      expect(results.docs, hasLength(1));
      final data = results.docs.first.data();
      expect(data['opponentUserIds'], isEmpty);
      expect(data['result'], 'loss');
    });
  });
}
