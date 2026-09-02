import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/services/asset_service.dart';

void main() {
  group('AssetService', () {
    late AssetService assetService;

    setUp(() {
      assetService = AssetService();
    });

    group('Initialization', () {
      test('init completes without error even when assets missing', () async {
        expect(
          () async => await assetService.init(),
          returnsNormally,
        );
      });

      test('load state transitions from idle → loading → complete', () async {
        expect(assetService.loadState.value, AssetLoadState.idle);

        final future = assetService.init();
        // 初期化中は loading 状態
        expect(assetService.loadState.value, AssetLoadState.idle); // init 前

        await future;
        expect(assetService.loadState.value, AssetLoadState.complete);
      });

      test('load progress starts at 0 and increments', () async {
        expect(assetService.getLoadProgress(), greaterThanOrEqualTo(0.0));
        expect(assetService.getLoadProgress(), lessThanOrEqualTo(1.0));
      });
    });

    group('Animation Assets', () {
      test('getAnimationPath returns null for non-existent assets', () async {
        await assetService.init();
        expect(
          assetService.getAnimationPath('nonexistent.json'),
          isNull,
        );
      });

      test('hasAnimation returns false initially (assets not provided)', () async {
        await assetService.init();
        expect(assetService.hasAnimation('kill_burst.json'), isFalse);
      });

      test('getAnimationPath is consistent across calls', () async {
        await assetService.init();
        final path1 = assetService.getAnimationPath('test.json');
        final path2 = assetService.getAnimationPath('test.json');
        expect(path1, equals(path2));
      });
    });

    group('Sound Effects', () {
      test('getSoundEffectPath returns null for non-existent effects', () async {
        await assetService.init();
        expect(
          assetService.getSoundEffectPath('nonexistent.mp3'),
          isNull,
        );
      });

      test('hasSoundEffect returns false initially (assets not provided)',
          () async {
        await assetService.init();
        expect(assetService.hasSoundEffect('kill.mp3'), isFalse);
      });

      test('multiple sound effects can be queried safely', () async {
        await assetService.init();
        expect(assetService.getSoundEffectPath('kill.mp3'), isNull);
        expect(assetService.getSoundEffectPath('win.mp3'), isNull);
        expect(assetService.getSoundEffectPath('lose.mp3'), isNull);
      });
    });

    group('BGM Tracks', () {
      test('getBGMPath returns null for non-existent tracks', () async {
        await assetService.init();
        expect(assetService.getBGMPath('nonexistent.mp3'), isNull);
      });

      test('hasBGM returns false initially (assets not provided)', () async {
        await assetService.init();
        expect(assetService.hasBGM('battle.mp3'), isFalse);
      });

      test('all BGM track names can be queried without error', () async {
        await assetService.init();
        final tracks = ['lobby.mp3', 'matching.mp3', 'battle.mp3', 'result_win.mp3'];
        for (final track in tracks) {
          expect(assetService.getBGMPath(track), isNull);
        }
      });
    });

    group('Cache Management', () {
      test('clearCache removes all cached assets', () async {
        await assetService.init();
        assetService.clearCache();

        expect(assetService.getLoadProgress(), equals(0.0));
        expect(assetService.hasAnimation('test.json'), isFalse);
      });

      test('debugDumpAssets returns valid structure', () async {
        await assetService.init();
        final dump = assetService.debugDumpAssets();

        expect(dump, containsPair('loaded_count', isA<int>()));
        expect(dump, containsPair('total_count', isA<int>()));
        expect(dump, containsPair('cache_size', isA<int>()));
        expect(dump, containsPair('animations', isA<List>()));
        expect(dump, containsPair('sounds', isA<List>()));
        expect(dump, containsPair('bgm_tracks', isA<List>()));
        expect(dump, containsPair('load_state', isA<String>()));
      });

      test('debug dump shows load counts', () async {
        await assetService.init();
        final dump = assetService.debugDumpAssets();

        final loadedCount = dump['loaded_count'] as int;
        final totalCount = dump['total_count'] as int;

        expect(loadedCount, greaterThanOrEqualTo(0));
        expect(totalCount, greaterThanOrEqualTo(0));
        expect(loadedCount, lessThanOrEqualTo(totalCount));
      });
    });

    group('Load Progress', () {
      test('getLoadProgress returns value between 0 and 1', () async {
        await assetService.init();
        final progress = assetService.getLoadProgress();

        expect(progress, greaterThanOrEqualTo(0.0));
        expect(progress, lessThanOrEqualTo(1.0));
      });

      test('progress is 0 when nothing loaded', () async {
        assetService.clearCache();
        expect(assetService.getLoadProgress(), equals(0.0));
      });

      test('progress does not exceed 1.0', () async {
        // 複数回 init を呼び出す（カウンターが誤って増加する恐れ）
        await assetService.init();
        await assetService.init();

        final progress = assetService.getLoadProgress();
        expect(progress, lessThanOrEqualTo(1.0));
      });
    });

    group('Singleton Pattern', () {
      test('multiple instances refer to same object', () {
        final service1 = AssetService();
        final service2 = AssetService();

        expect(identical(service1, service2), isTrue);
      });

      test('state persists across instance references', () async {
        final service1 = AssetService();
        await service1.init();

        final service2 = AssetService();
        expect(service2.loadState.value, AssetLoadState.complete);
      });
    });

    group('Safe Fallback Behavior', () {
      test('asset service never throws on missing assets', () async {
        expect(
          () async => await assetService.init(),
          returnsNormally,
        );

        // 複数アクセスも安全
        expect(
          () {
            assetService.getAnimationPath('missing.json');
            assetService.getSoundEffectPath('missing.mp3');
            assetService.getBGMPath('missing.mp3');
          },
          returnsNormally,
        );
      });

      test('null returns trigger no side effects', () async {
        await assetService.init();

        final animations = [null, null, null];
        final sounds = [null, null, null];

        expect(animations.every((v) => v == null), isTrue);
        expect(sounds.every((v) => v == null), isTrue);
      });
    });
  });
}
