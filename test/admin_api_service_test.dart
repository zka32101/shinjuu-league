import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shinjuu_league/config/skill_progression_config.dart';
import 'package:shinjuu_league/services/ab_test_coordinator.dart';
import 'package:shinjuu_league/services/admin_api_service.dart';
import 'package:shinjuu_league/services/config_admin_service.dart';
import 'package:shinjuu_league/services/feature_flags_service.dart';
import 'package:shinjuu_league/services/skill_progression_analytics_service.dart';

class _FakeSkillProgressionAnalyticsService extends Mock
    implements SkillProgressionAnalyticsService {
  @override
  Future<void> logABTestVariantAssignment(
    String? userId,
    String? experimentId,
    String? variantName,
    bool? isControl,
  ) {
    return super.noSuchMethod(
      Invocation.method(#logABTestVariantAssignment,
          [userId, experimentId, variantName, isControl]),
      returnValue: Future<void>.value(),
      returnValueForMissingStub: Future<void>.value(),
    ) as Future<void>;
  }
}

void main() {
  group('AdminApiService', () {
    late AdminApiService apiService;

    setUp(() {
      final featureFlags = FeatureFlagsService();
      apiService = AdminApiService(
        adminService: ConfigAdminService(
          progressionConfig: SkillProgressionConfig(),
          featureFlags: featureFlags,
          coordinator: ABTestCoordinator(
            featureFlags: featureFlags,
            analytics: _FakeSkillProgressionAnalyticsService(),
          ),
        ),
      );
    });

    test(
      'rollbackToSnapshot returns false for an unknown snapshot id instead '
      'of silently reporting success',
      () async {
        final result = await apiService.rollbackToSnapshot('does_not_exist');

        expect(result, isFalse);
      },
    );

    test('rollbackToSnapshot returns true for a real snapshot', () async {
      final result = await apiService.rollbackToSnapshot('initial');

      expect(result, isTrue);
    });

    test('createSnapshot makes the snapshot retrievable via getSnapshots',
        () async {
      final created = await apiService.createSnapshot('my_snapshot');
      final snapshots = apiService.getSnapshots();

      expect(created, isTrue);
      expect(snapshots.map((s) => s['id']), contains('my_snapshot'));
    });

    test('createSnapshot makes the snapshot usable for rollback', () async {
      await apiService.createSnapshot('rollback_target');

      final result = await apiService.rollbackToSnapshot('rollback_target');

      expect(result, isTrue);
    });
  });
}
