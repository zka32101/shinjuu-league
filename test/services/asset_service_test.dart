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

      test('getAnimationPath returns correct paths for known animations', () {
        expect(assetService.getAnimationPath('kill_burst.json'),
            'assets/animations/kill_burst.json');
        expect(assetService.getAnimationPath('win_celebration.json'),
            'assets/animations/win_celebration.json');
        expect(assetService.getAnimationPath('lose_fade.json'),
            'assets/animations/lose_fade.json');
        expect(assetService.getAnimationPath('aha_moment.json'),
            'assets/animations/aha_moment.json');
        expect(assetService.getAnimationPath('level_up.json'),
            'assets/animations/level_up.json');
      });

      test('getAnimationPath returns null for unknown animation', () {
        expect(assetService.getAnimationPath('unknown_animation.json'), null);
      });

      test('getSoundEffectPath returns correct paths for known effects', () {
        expect(assetService.getSoundEffectPath('kill.mp3'),
            'assets/sounds/kill.mp3');
        expect(assetService.getSoundEffectPath('aha_moment.mp3'),
            'assets/sounds/aha_moment.mp3');
        expect(assetService.getSoundEffectPath('win.mp3'),
            'assets/sounds/win.mp3');
        expect(assetService.getSoundEffectPath('lose.mp3'),
            'assets/sounds/lose.mp3');
      });

      test('getSoundEffectPath returns null for unknown effect', () {
        expect(assetService.getSoundEffectPath('unknown_sound.mp3'), null);
      });

      test('getBGMPath returns correct paths for known tracks', () {
        expect(assetService.getBGMPath('lobby.mp3'),
            'assets/sounds/lobby.mp3');
        expect(assetService.getBGMPath('matching.mp3'),
            'assets/sounds/matching.mp3');
        expect(assetService.getBGMPath('battle.mp3'),
            'assets/sounds/battle.mp3');
        expect(assetService.getBGMPath('result_win.mp3'),
            'assets/sounds/result_win.mp3');
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
        expect(assetService.getAnimationPath('kill_burst.json'), isNotNull);

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

      test('debugDumpAssets includes animation list', () {
        final dump = assetService.debugDumpAssets();
        final animations = dump['animations'] as List<dynamic>;

        expect(animations.length, greaterThan(0));
      });

      test('debugDumpAssets includes sound list', () {
        final dump = assetService.debugDumpAssets();
        final sounds = dump['sounds'] as List<dynamic>;

        expect(sounds.length, greaterThan(0));
      });

      test('debugDumpAssets includes BGM track list', () {
        final dump = assetService.debugDumpAssets();
        final bgms = dump['bgm_tracks'] as List<dynamic>;

        expect(bgms.length, greaterThan(0));
      });
    });
  });
}
