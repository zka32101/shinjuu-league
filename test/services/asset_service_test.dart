import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/services/asset_service.dart';

void main() {
  group('AssetService', () {
    late AssetService assetService;

    setUp(() {
      // Create fresh instance for each test
      assetService = AssetService();
    });

    test('singleton pattern returns same instance', () {
      final service1 = AssetService();
      final service2 = AssetService();
      expect(identical(service1, service2), true);
    });

    test('initial state is idle', () {
      expect(assetService.state, AssetLoadState.idle);
      expect(assetService.isLoaded, false);
    });

    test('init() transitions to loading then complete', () async {
      expect(assetService.state, AssetLoadState.idle);

      final initFuture = assetService.init();
      // State should be loading immediately
      expect(assetService.state, AssetLoadState.loading);

      await initFuture;
      expect(assetService.state, AssetLoadState.complete);
      expect(assetService.isLoaded, true);
    });

    test('init() is idempotent - multiple calls are safe', () async {
      await assetService.init();
      expect(assetService.state, AssetLoadState.complete);

      // Second call should return immediately without re-initialization
      await assetService.init();
      expect(assetService.state, AssetLoadState.complete);
    });

    group('Asset path retrieval', () {
      setUp(() async {
        await assetService.init();
      });

      test('getAnimationPath returns correct paths for known animations', () {
        expect(assetService.getAnimationPath('kill_burst'),
            'assets/animations/kill_burst.json');
        expect(assetService.getAnimationPath('win_celebration'),
            'assets/animations/win_celebration.json');
        expect(assetService.getAnimationPath('lose_fade'),
            'assets/animations/lose_fade.json');
        expect(assetService.getAnimationPath('aha_moment'),
            'assets/animations/aha_moment.json');
        expect(assetService.getAnimationPath('level_up'),
            'assets/animations/level_up.json');
      });

      test('getAnimationPath returns null for unknown animation', () {
        expect(assetService.getAnimationPath('unknown_animation'), null);
      });

      test('getSoundEffectPath returns correct paths for known effects', () {
        expect(assetService.getSoundEffectPath('kill'),
            'assets/sounds/kill.mp3');
        expect(assetService.getSoundEffectPath('aha_moment'),
            'assets/sounds/aha_moment.mp3');
        expect(assetService.getSoundEffectPath('win'), 'assets/sounds/win.mp3');
        expect(assetService.getSoundEffectPath('lose'),
            'assets/sounds/lose.mp3');
      });

      test('getSoundEffectPath returns null for unknown effect', () {
        expect(assetService.getSoundEffectPath('unknown_sound'), null);
      });

      test('getBGMPath returns correct paths for known tracks', () {
        expect(assetService.getBGMPath('lobby'), 'assets/music/lobby.mp3');
        expect(assetService.getBGMPath('matching'),
            'assets/music/matching.mp3');
        expect(assetService.getBGMPath('battle'), 'assets/music/battle.mp3');
        expect(assetService.getBGMPath('result_win'),
            'assets/music/result_win.mp3');
      });

      test('getBGMPath returns null for unknown track', () {
        expect(assetService.getBGMPath('unknown_bgm'), null);
      });
    });

    group('Cache management', () {
      test('clearCache resets state to idle', () async {
        await assetService.init();
        expect(assetService.isLoaded, true);

        assetService.clearCache();
        expect(assetService.state, AssetLoadState.idle);
        expect(assetService.isLoaded, false);
      });

      test('clearCache prevents access to asset paths', () async {
        await assetService.init();
        expect(assetService.getAnimationPath('kill_burst'), isNotNull);

        assetService.clearCache();
        expect(assetService.getAnimationPath('kill_burst'), null);
      });
    });

    group('Debug dump', () {
      setUp(() async {
        await assetService.init();
      });

      test('debugDumpAssets returns complete state information', () {
        final dump = assetService.debugDumpAssets();

        expect(dump, isA<Map<String, dynamic>>());
        expect(dump['state'], 'AssetLoadState.complete');
        expect(dump['animations_count'], 5);
        expect(dump['sounds_count'], 12);
        expect(dump['bgms_count'], 4);
      });

      test('debugDumpAssets lists all animation names', () {
        final dump = assetService.debugDumpAssets();
        final animations = dump['animations'] as List<dynamic>;

        expect(animations, containsAll([
          'kill_burst',
          'win_celebration',
          'lose_fade',
          'aha_moment',
          'level_up',
        ]));
      });

      test('debugDumpAssets lists all sound names', () {
        final dump = assetService.debugDumpAssets();
        final sounds = dump['sounds'] as List<dynamic>;

        expect(sounds.length, 12);
        expect(sounds, containsAll(['kill', 'aha_moment', 'win', 'lose']));
      });

      test('debugDumpAssets lists all BGM names', () {
        final dump = assetService.debugDumpAssets();
        final bgms = dump['bgms'] as List<dynamic>;

        expect(bgms, containsAll(['lobby', 'matching', 'battle', 'result_win']));
      });
    });
  });
}
