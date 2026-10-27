import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/config/app_config.dart';
import 'package:shinjuu_league/data/models/battlepass_model.dart';
import 'package:shinjuu_league/services/battle_pass_service.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

void main() {
  group('BattlePassService', () {
    const userId = 'user_1';
    late FakeFirebaseFirestore firestore;
    late FirestoreService firestoreService;
    late BattlePassService service;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      firestoreService = FirestoreService.forFirestore(firestore);
      service = BattlePassService(firestoreService);
      // incrementUserGems/addUserCosmetic use Firestore's plain update(),
      // which throws for a document that doesn't exist yet - a real user
      // always has their own users/{uid} doc by the time they're claiming
      // battle pass rewards, so seed one here.
      await firestore.collection('users').doc(userId).set({
        'gems': 0,
        'ownedCosmetics': <String>[],
      });
    });

    group('addProgressForBattle', () {
      test(
        'F2Pユーザー（未購読）でもバトルパスドキュメントを新規作成し進捗を記録する',
        () async {
          await service.addProgressForBattle(userId);

          final pass = await firestoreService.getBattlePass(
            userId,
            AppConfig.currentSeasonId,
          );
          expect(pass, isNotNull);
          expect(pass!.progress, BattlePassService.progressPerBattle);
          expect(pass.isPremium, isFalse);
        },
      );

      test('既存のバトルパスに対して進捗を加算する', () async {
        await service.addProgressForBattle(userId);
        await service.addProgressForBattle(userId);

        final pass = await firestoreService.getBattlePass(
          userId,
          AppConfig.currentSeasonId,
        );
        expect(pass!.progress, BattlePassService.progressPerBattle * 2);
      });

      test('進捗は100でクランプされる（それ以上は書き込まない）', () async {
        for (var i = 0; i < 15; i++) {
          await service.addProgressForBattle(userId);
        }

        final pass = await firestoreService.getBattlePass(
          userId,
          AppConfig.currentSeasonId,
        );
        expect(pass!.progress, 100);
      });

      test('プレミアム加入状態は進捗加算で書き換わらない', () async {
        final now = DateTime.now();
        await firestoreService.saveBattlePass(
          BattlePass(
            seasonId: AppConfig.currentSeasonId,
            userId: userId,
            progress: 0,
            level: 1,
            claimedRewards: const [],
            isPremium: true,
            startDate: now,
            endDate: now.add(const Duration(days: 90)),
          ),
        );

        await service.addProgressForBattle(userId);

        final pass = await firestoreService.getBattlePass(
          userId,
          AppConfig.currentSeasonId,
        );
        expect(pass!.isPremium, isTrue);
      });
    });

    group('claimTier', () {
      Future<void> seedPass({
        required int progress,
        bool isPremium = false,
        List<BattlePassReward> claimedRewards = const [],
      }) async {
        final now = DateTime.now();
        await firestoreService.saveBattlePass(
          BattlePass(
            seasonId: AppConfig.currentSeasonId,
            userId: userId,
            progress: progress,
            level: 1,
            claimedRewards: claimedRewards,
            isPremium: isPremium,
            startDate: now,
            endDate: now.add(const Duration(days: 90)),
          ),
        );
      }

      test('バトルパスが存在しない場合は失敗する', () async {
        expect(await service.claimTier(userId, 1), isFalse);
      });

      test('進捗がタイア閾値未満なら失敗する', () async {
        await seedPass(progress: 5);
        expect(await service.claimTier(userId, 1), isFalse);
      });

      test('無課金タイア（非プレミアム）を受け取るとジェムが付与される', () async {
        await seedPass(progress: 10);

        final claimed = await service.claimTier(userId, 1);

        expect(claimed, isTrue);
        final userDoc = await firestore.collection('users').doc(userId).get();
        expect(userDoc.data()!['gems'], greaterThan(0));

        final pass = await firestoreService.getBattlePass(
          userId,
          AppConfig.currentSeasonId,
        );
        expect(pass!.claimedRewards, hasLength(1));
        expect(pass.claimedRewards.first.tier, 1);
        expect(pass.claimedRewards.first.type, RewardType.gems);
      });

      test('プレミアムタイア（3の倍数）は未加入だと受け取れない', () async {
        await seedPass(progress: 30, isPremium: false);
        expect(await service.claimTier(userId, 3), isFalse);
      });

      test('プレミアムタイアは加入済みならスキンが付与される', () async {
        await seedPass(progress: 30, isPremium: true);

        final claimed = await service.claimTier(userId, 3);

        expect(claimed, isTrue);
        final userDoc = await firestore.collection('users').doc(userId).get();
        expect(
          userDoc.data()!['ownedCosmetics'],
          contains('bp_${AppConfig.currentSeasonId}_tier3_skin'),
        );
      });

      test('同じタイアを二重に受け取ることはできない', () async {
        await seedPass(progress: 10);
        await service.claimTier(userId, 1);

        expect(await service.claimTier(userId, 1), isFalse);
      });
    });
  });
}
