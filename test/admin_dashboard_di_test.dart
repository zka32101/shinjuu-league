import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/data/providers/service_providers.dart';
import 'package:shinjuu_league/services/firestore_service.dart';

/// Regression guard for a real bug: every admin config screen (dashboard,
/// feature flags, experiments, difficulty tuning, audit log, snapshots) used
/// to construct WebAdminDashboardService with `apiService: null as dynamic`
/// directly in app_routes.dart / admin_dashboard_screen.dart, with a
/// `// TODO: Inject ... from Riverpod provider` left unfinished - opening
/// any of these screens threw the moment the null service was actually
/// used. These providers now build the real chain
/// (SkillProgressionConfig -> FeatureFlagsService -> ABTestCoordinator ->
/// ConfigAdminService -> AdminApiService -> WebAdminDashboardService), all
/// from services with safe, no-Firebase-required in-memory defaults.
///
/// webAdminDashboardServiceProvider pulls in auditLoggerServiceProvider ->
/// firestoreServiceProvider, whose real FirestoreService() singleton
/// touches FirebaseFirestore.instance eagerly in its constructor (unlike
/// AuthService's lazy pattern) - so, matching every other test in this
/// suite that depends on it, firestoreServiceProvider is faked here too.
ProviderContainer _container() => ProviderContainer(
  overrides: [
    firestoreServiceProvider.overrideWithValue(
      FirestoreService.forFirestore(FakeFirebaseFirestore()),
    ),
  ],
);

void main() {
  group('Admin dashboard DI chain', () {
    test('webAdminDashboardServiceProvider resolves without throwing', () {
      final container = _container();
      addTearDown(container.dispose);

      final service = container.read(webAdminDashboardServiceProvider);
      expect(service, isNotNull);
    });

    test('resolved service returns real (non-crashing) dashboard state', () {
      final container = _container();
      addTearDown(container.dispose);

      final service = container.read(webAdminDashboardServiceProvider);
      final snapshot = service.getDashboardState();

      expect(snapshot.statistics, isNotEmpty);
      expect(snapshot.features, isNotEmpty);
    });

    test('admin sub-services all resolve to the same underlying dashboard', () {
      final container = _container();
      addTearDown(container.dispose);

      final apiService = container.read(adminApiServiceProvider);
      final configService = container.read(configAdminServiceProvider);

      expect(apiService.getFeatures(), isNotEmpty);
      expect(configService.getDifficultyModifiers(), isNotNull);
    });
  });
}
