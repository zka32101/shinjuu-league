import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/stage_catalog.dart';

void main() {
  group('stageCatalog データ整合性', () {
    test('5つ程度のステージが用意されている', () {
      expect(stageCatalog.length, greaterThanOrEqualTo(5));
    });

    test('stageId が重複していない', () {
      final ids = stageCatalog.map((s) => s.stageId).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('全てのステージが name/description を持つ（空文字禁止）', () {
      for (final stage in stageCatalog) {
        expect(stage.name, isNotEmpty, reason: stage.stageId);
        expect(stage.description, isNotEmpty, reason: stage.stageId);
      }
    });

    test('全てのステージが2レーン分のlaneColorsを持つ', () {
      for (final stage in stageCatalog) {
        expect(stage.laneColors.length, 2, reason: stage.stageId);
      }
    });

    test('同一ステージ内でレーン色が重複していない（視覚的に区別できること）', () {
      for (final stage in stageCatalog) {
        expect(
          stage.laneColors.toSet().length,
          stage.laneColors.length,
          reason: stage.stageId,
        );
      }
    });

    test('defaultStageId がカタログに実在する', () {
      expect(stageCatalog.any((s) => s.stageId == defaultStageId), isTrue);
    });

    test('stageById は存在しないIDに対してフォールバックする（例外を投げない）', () {
      final fallback = stageById('存在しないID');
      expect(fallback, isNotNull);
    });

    test('stageById は正しいステージを返す', () {
      final stage = stageById(stageCatalog.last.stageId);
      expect(stage.stageId, stageCatalog.last.stageId);
    });
  });
}
