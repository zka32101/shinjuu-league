import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/services/firestore_service.dart';
import 'package:shinjuu_league/services/leveling_service.dart';

void main() {
  group('LevelingService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late LevelingService service;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      service = LevelingService.forFirestore(
        FirestoreService.forFirestore(fakeFirestore),
      );
    });

    test('xpRequiredForLevel はレベル×100', () {
      expect(LevelingService.xpRequiredForLevel(1), equals(100));
      expect(LevelingService.xpRequiredForLevel(2), equals(200));
      expect(LevelingService.xpRequiredForLevel(5), equals(500));
    });

    test('未初期化ユーザーはlevel=1/experience=0から開始する', () async {
      final result = await service.addExperience('new_user', 30);

      expect(result.newLevel, equals(1));
      expect(result.newExperience, equals(30));
      expect(result.leveledUp, isFalse);
    });

    test('閾値未満のXP加算ではレベルアップしない', () async {
      await fakeFirestore.collection('users').doc('u1').set({
        'level': 1,
        'experience': 0,
      });

      final result = await service.addExperience('u1', 99);

      expect(result.newLevel, equals(1));
      expect(result.newExperience, equals(99));
      expect(result.levelsGained, equals(0));
    });

    test('閾値ちょうどでレベルアップし、経験値は0にリセットされる', () async {
      await fakeFirestore.collection('users').doc('u2').set({
        'level': 1,
        'experience': 0,
      });

      final result = await service.addExperience('u2', 100);

      expect(result.newLevel, equals(2));
      expect(result.newExperience, equals(0));
      expect(result.levelsGained, equals(1));
    });

    test('余剰XPは繰り越される', () async {
      await fakeFirestore.collection('users').doc('u3').set({
        'level': 1,
        'experience': 0,
      });

      final result = await service.addExperience('u3', 130);

      expect(result.newLevel, equals(2));
      expect(result.newExperience, equals(30)); // 130 - 100
    });

    test('一度に複数レベル分のXPを得ると複数回レベルアップする', () async {
      await fakeFirestore.collection('users').doc('u4').set({
        'level': 1,
        'experience': 0,
      });

      // レベル1→2(100) + レベル2→3(200) = 300ちょうど
      final result = await service.addExperience('u4', 300);

      expect(result.newLevel, equals(3));
      expect(result.newExperience, equals(0));
      expect(result.levelsGained, equals(2));
    });

    test('結果はFirestoreに永続化される', () async {
      await fakeFirestore.collection('users').doc('u5').set({
        'level': 3,
        'experience': 50,
      });

      await service.addExperience('u5', 10);

      final doc = await fakeFirestore.collection('users').doc('u5').get();
      expect(doc.data()!['level'], equals(3));
      expect(doc.data()!['experience'], equals(60));
    });

    test('0以下のXPは何もせず現在値を返す', () async {
      await fakeFirestore.collection('users').doc('u6').set({
        'level': 4,
        'experience': 77,
      });

      final result = await service.addExperience('u6', 0);

      expect(result.newLevel, equals(4));
      expect(result.newExperience, equals(77));
      expect(result.leveledUp, isFalse);
    });
  });
}
