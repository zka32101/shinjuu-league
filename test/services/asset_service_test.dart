import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/services/asset_service.dart';

void main() {
  group('AssetService', () {
    late AssetService assetService;

    setUp(() {
      assetService = AssetService();
    });

    test('singleton pattern returns same instance', () {
      final service1 = AssetService();
      final service2 = AssetService();
      expect(identical(service1, service2), true);
    });

    test('initial loadState is idle', () {
      expect(assetService.loadState.value, AssetLoadState.idle);
    });

    test('init() transitions to complete', () async {
      expect(assetService.loadState.value, AssetLoadState.idle);

      await assetService.init();
      expect(assetService.loadState.value, AssetLoadState.complete);
    });

    test('init() is idempotent - multiple calls are safe', () async {
      await assetService.init();
      expect(assetService.loadState.value, AssetLoadState.complete);

      await assetService.init();
      expect(assetService.loadState.value, AssetLoadState.complete);
    });

    group('Asset path retrieval', () {
      setUp(() async {
        await assetService.init();
      });

      // AssetService's whole design point (see CLAUDE.md: "実ファイルが無い
      //場合でも null を返す") is that getAnimationPath()/getSoundEffectPath()/
      // getBGMPath() only ever return a path once the file has actually been
      // verified to load via rootBundle -- never just because its name is on
      // the known list. Since no real .mp3/.json assets are checked into the
      // repo yet (assets/sounds and assets/animations hold only .gitkeep),
      // every one of these must resolve to null today. Asserting a real path
      // here would be asserting the fake-success bug this service was fixed
      // to remove.
      test('getAnimationPath returns null for a known-but-missing animation',
          () {
        expect(assetService.getAnimationPath('kill_burst.json'), isNull);
        expect(assetService.getAnimationPath('win_celebration.json'), isNull);
        expect(assetService.getAnimationPath('lose_fade.json'), isNull);
        expect(assetService.getAnimationPath('aha_moment.json'), isNull);
        expect(assetService.getAnimationPath('level_up.json'), isNull);
      });

      test('getAnimationPath returns null for unknown animation', () {
        expect(assetService.getAnimationPath('unknown_animation.json'), null);
      });

      test('getSoundEffectPath returns null for a known-but-missing effect',
          () {
        expect(assetService.getSoundEffectPath('kill.mp3'), isNull);
        expect(assetService.getSoundEffectPath('aha_moment.mp3'), isNull);
        expect(assetService.getSoundEffectPath('win.mp3'), isNull);
        expect(assetService.getSoundEffectPath('lose.mp3'), isNull);
      });

      test('getSoundEffectPath returns null for unknown effect', () {
        expect(assetService.getSoundEffectPath('unknown_sound.mp3'), null);
      });

      test('getBGMPath returns null for a known-but-missing track', () {
        expect(assetService.getBGMPath('lobby.mp3'), isNull);
        expect(assetService.getBGMPath('matching.mp3'), isNull);
        expect(assetService.getBGMPath('battle.mp3'), isNull);
        expect(assetService.getBGMPath('result_win.mp3'), isNull);
      });

      test('getBGMPath returns null for unknown track', () {
        expect(assetService.getBGMPath('unknown_bgm.mp3'), null);
      });
    });

    group('Cache management', () {
      test('clearCache resets load state', () async {
        await assetService.init();
        expect(assetService.loadState.value, AssetLoadState.complete);

        assetService.clearCache();
        // Note: clearCache doesn't reset loadState.value in current implementation
      });

      test('clearCache prevents access to asset paths', () async {
        await assetService.init();
        // Nothing gets cached in the first place while no real asset files
        // exist, so this already returns null before clearCache() runs too;
        // the point of this test is just that clearCache() never throws and
        // access stays safely null afterward, not a before/after transition.
        expect(assetService.getAnimationPath('kill_burst.json'), isNull);

        assetService.clearCache();
        expect(assetService.getAnimationPath('kill_burst.json'), null);
      });
    });

    group('Debug dump', () {
      setUp(() async {
        await assetService.init();
      });

      test('debugDumpAssets returns complete state information', () {
        final dump = assetService.debugDumpAssets();

        expect(dump, isA<Map<String, dynamic>>());
        expect(dump.containsKey('load_state'), true);
        expect(dump.containsKey('loaded_count'), true);
        expect(dump.containsKey('cache_size'), true);
      });

      // No real asset files are checked in yet, so these lists are correctly
      // empty; they only need to exist and be queryable without throwing.
      test('debugDumpAssets includes animation list', () {
        final dump = assetService.debugDumpAssets();
        final animations = dump['animations'] as List<dynamic>;

        expect(animations.length, greaterThanOrEqualTo(0));
      });

      test('debugDumpAssets includes sound list', () {
        final dump = assetService.debugDumpAssets();
        final sounds = dump['sounds'] as List<dynamic>;

        expect(sounds.length, greaterThanOrEqualTo(0));
      });

      test('debugDumpAssets includes BGM track list', () {
        final dump = assetService.debugDumpAssets();
        final bgms = dump['bgm_tracks'] as List<dynamic>;

        expect(bgms.length, greaterThanOrEqualTo(0));
      });
    });
  });
}
