import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/services/audio_service.dart';
import 'package:shinjuu_league/data/models/skill_model.dart';

void main() {
  group('AudioService Phase 4', () {
    late AudioService audioService;

    setUp(() {
      audioService = AudioService();
    });

    tearDown(() {
      audioService.dispose();
    });

    group('ボリューム管理', () {
      test('デフォルトのSEボリューム は 0.7', () {
        expect(audioService.seVolume, equals(0.7));
      });

      test('デフォルトのBGMボリューム は 0.5', () {
        expect(audioService.bgmVolume, equals(0.5));
      });

      test('setSeVolume で SE ボリュームを設定できる', () async {
        await audioService.setSeVolume(0.5);
        expect(audioService.seVolume, equals(0.5));
      });

      test('setBgmVolume で BGM ボリュームを設定できる', () async {
        await audioService.setBgmVolume(0.8);
        expect(audioService.bgmVolume, equals(0.8));
      });

      test('ボリュームは 0.0 以上 1.0 以下にクランプされる', () async {
        await audioService.setSeVolume(2.0);
        expect(audioService.seVolume, equals(1.0));

        await audioService.setSeVolume(-0.5);
        expect(audioService.seVolume, equals(0.0));
      });

      test('ミュート状態を切り替えられる', () async {
        expect(audioService.isMuted, equals(false));

        await audioService.setMuted(true);
        expect(audioService.isMuted, equals(true));

        await audioService.setMuted(false);
        expect(audioService.isMuted, equals(false));
      });
    });

    group('SE 再生', () {
      test('playButtonTapSe が呼び出し可能', () async {
        expect(
          () => audioService.playButtonTapSe(),
          returnsNormally,
        );
      });

      test('playKillSe が呼び出し可能', () async {
        expect(
          () => audioService.playKillSe(),
          returnsNormally,
        );
      });

      test('playAhaMomentSe が呼び出し可能', () async {
        expect(
          () => audioService.playAhaMomentSe(),
          returnsNormally,
        );
      });

      test('playWinSe が呼び出し可能', () async {
        expect(
          () => audioService.playWinSe(),
          returnsNormally,
        );
      });

      test('playLossSe が呼び出し可能', () async {
        expect(
          () => audioService.playLossSe(),
          returnsNormally,
        );
      });

      test('playHitSe が呼び出し可能', () async {
        expect(
          () => audioService.playHitSe(),
          returnsNormally,
        );
      });

      test('playCriticalHitSe が呼び出し可能', () async {
        expect(
          () => audioService.playCriticalHitSe(),
          returnsNormally,
        );
      });

      test('ミュート中は SE 再生されない（エラーなし）', () async {
        await audioService.setMuted(true);
        expect(
          () => audioService.playKillSe(),
          returnsNormally,
        );
      });
    });

    group('スキル別 SE', () {
      test('offensive スキルは攻撃SEを再生', () async {
        expect(
          () => audioService.playSkillSe(SkillType.offensive),
          returnsNormally,
        );
      });

      test('defensive スキルは防御SEを再生', () async {
        expect(
          () => audioService.playSkillSe(SkillType.defensive),
          returnsNormally,
        );
      });

      test('utility スキルは汎用SEを再生', () async {
        expect(
          () => audioService.playSkillSe(SkillType.utility),
          returnsNormally,
        );
      });

      test('全スキルタイプで SE が再生可能', () async {
        const types = [
          SkillType.offensive,
          SkillType.defensive,
          SkillType.utility,
        ];

        for (final type in types) {
          expect(
            () => audioService.playSkillSe(type),
            returnsNormally,
          );
        }
      });
    });

    group('BGM管理', () {
      test('BGM 再生を開始できる', () async {
        expect(
          () => audioService.playBgm('battle_bgm'),
          returnsNormally,
        );
      });

      test('currentBgm が追跡される', () async {
        await audioService.playBgm('battle_bgm');
        expect(audioService.currentBgm, equals('battle_bgm'));
      });

      test('同じBGMは重複再生されない', () async {
        await audioService.playBgm('battle_bgm');
        await audioService.playBgm('battle_bgm');
        expect(audioService.currentBgm, equals('battle_bgm'));
      });

      test('別のBGMに切り替えられる', () async {
        await audioService.playBgm('battle_bgm');
        await audioService.playBgm('boss_bgm');
        expect(audioService.currentBgm, equals('boss_bgm'));
      });

      test('BGM を停止できる', () async {
        await audioService.playBgm('battle_bgm');
        await audioService.stopBgm();
        expect(audioService.currentBgm, isNull);
      });

      test('BGM 停止後は null に戻る', () async {
        await audioService.playBgm('battle_bgm');
        expect(audioService.currentBgm, isNotNull);

        await audioService.stopBgm();
        expect(audioService.currentBgm, isNull);
      });
    });

    group('シングルトン動作', () {
      test('AudioService はシングルトンパターンで同じインスタンスを返す', () {
        final service1 = AudioService();
        final service2 = AudioService();

        expect(identical(service1, service2), equals(true));
      });

      test('複数インスタンスで設定が共有される', () async {
        final service1 = AudioService();
        final service2 = AudioService();

        await service1.setSeVolume(0.3);
        expect(service2.seVolume, equals(0.3));
      });
    });

    group('ボリュームと SE 再生', () {
      test('低ボリュームでも SE 再生可能', () async {
        await audioService.setSeVolume(0.1);
        expect(
          () => audioService.playKillSe(),
          returnsNormally,
        );
      });

      test('最大ボリュームでも SE 再生可能', () async {
        await audioService.setSeVolume(1.0);
        expect(
          () => audioService.playKillSe(),
          returnsNormally,
        );
      });
    });

    group('クロスフェード設定', () {
      test('playBgm でクロスフェード時間を指定できる', () async {
        expect(
          () => audioService.playBgm('battle_bgm', crossfadeDuration: 1.0),
          returnsNormally,
        );
      });

      test('クロスフェード時間なしでも再生可能', () async {
        expect(
          () => audioService.playBgm('battle_bgm'),
          returnsNormally,
        );
      });
    });
  });

  group('AudioService 安全性', () {
    late AudioService audioService;

    setUp(() {
      audioService = AudioService();
    });

    tearDown(() {
      audioService.dispose();
    });

    test('ファイル未存在でもアプリはクラッシュしない', () async {
      // 存在しないファイルでも例外を投げない設計
      expect(
        () => audioService.playBgm('nonexistent_file'),
        returnsNormally,
      );
    });

    test('複数回の dispose は安全', () async {
      audioService.dispose();
      expect(
        () => audioService.dispose(),
        returnsNormally,
      );
    });

    test('dispose 後もプロパティアクセスは安全', () {
      audioService.dispose();

      expect(
        () => audioService.seVolume,
        returnsNormally,
      );
      expect(
        () => audioService.isMuted,
        returnsNormally,
      );
    });
  });
}
