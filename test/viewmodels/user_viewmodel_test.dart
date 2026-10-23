import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/data/models/battle_model.dart';
import 'package:shinjuu_league/data/models/skill_model.dart';
import 'package:shinjuu_league/data/models/user_model.dart' as app;
import 'package:shinjuu_league/services/auth_service.dart';
import 'package:shinjuu_league/services/firestore_service.dart';
import 'package:shinjuu_league/services/ranking_service.dart';
import 'package:shinjuu_league/services/season_service.dart';
import 'package:shinjuu_league/services/skill_tree_reset_service.dart';
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

  group('UserViewModel season-transition skill tree reset', () {
    const uid = 'test_user_2';
    late FakeFirebaseFirestore firestore;
    late MockAuthService mockAuthService;
    late UserViewModel viewModel;

    Battle battle() {
      return Battle(
        battleId: 'battle_2',
        userId: uid,
        opponentIds: const [],
        mapId: 'map_01',
        mode: BattleMode.quick,
        durationSeconds: 300,
        playerStats: const [],
        result: BattleResult.win,
        eloChange: 16.0,
        startedAt: DateTime(2026, 2, 1),
        endedAt: DateTime(2026, 2, 1, 0, 5),
      );
    }

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      mockAuthService = MockAuthService();
      when(mockAuthService.currentUser).thenReturn(MockUser(uid));

      final baseUser = app.User(
        uid: uid,
        name: 'Tester2',
        rank: 0,
        level: 1,
        eloRating: 1500.0,
        winRate: 0.0,
        totalWins: 0,
        totalBattles: 0,
        gems: 0,
        gold: 0,
        createdAt: DateTime(2026, 1, 1),
        lastBattleAt: DateTime(2026, 1, 1),
      );
      await firestore
          .collection('users')
          .doc(uid)
          .set({...baseUser.toJson(), 'skillTree': SkillTree.create().toJson()});

      // 旧シーズン(season_1)を実際にプレイ済み（season_data に記録あり）
      // だが、まだスキルツリーのスナップショットは一度も取られていない
      // 状態 -- これが season_snapshots が永遠に空になっていた再現条件。
      await firestore
          .collection('users/$uid/season_data')
          .doc('season_1')
          .set({
        'userId': uid,
        'seasonId': 'season_1',
        'startingRating': 1200,
        'peakRating': 1600,
        'currentRating': 1550,
        'currentTier': 'Gold',
        'peakTier': 'Gold',
        'seasonWins': 10,
        'seasonLosses': 4,
      });

      // 新シーズン(season_2)がアクティブ
      await firestore.collection('seasons').doc('season_2').set({
        'seasonId': 'season_2',
        'name': 'Season 2',
        'startedAt': DateTime(2026, 2, 1).toIso8601String(),
        'endsAt': DateTime(2026, 3, 1).toIso8601String(),
        'isActive': true,
        'tierThresholds': <String, int>{},
        'rewardsByTier': <String, List<String>>{},
        'rules': <String, dynamic>{},
      });

      viewModel = UserViewModel(
        firestoreService: FirestoreService.forFirestore(firestore),
        authService: mockAuthService,
        rankingService: RankingService(firestore: firestore),
        seasonService: SeasonService(firestore: firestore),
        skillTreeResetService: SkillTreeResetService(
          FirestoreService.forFirestore(firestore),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 50));
    });

    tearDown(() {
      viewModel.dispose();
    });

    test(
      'auto-triggers a default-carryover skill tree reset when the active season has moved on',
      () async {
        await viewModel.applyBattleResult(battle());

        final snapshot = await firestore
            .doc('users/$uid/season_snapshots/season_1')
            .get();
        expect(snapshot.exists, isTrue);
        expect(snapshot.data()!['finalTier'], 'Gold');

        final reset = await firestore
            .doc('users/$uid/season_resets/season_2')
            .get();
        expect(reset.exists, isTrue);
        expect(reset.data()!['carryoverMode'], 'partial');
      },
    );

    test('does not re-trigger once the transition has already been recorded', () async {
      await viewModel.applyBattleResult(battle());
      await viewModel.applyBattleResult(battle());

      final resets = await firestore.collection('users/$uid/season_resets').get();
      expect(resets.docs, hasLength(1));
    });
  });
}
