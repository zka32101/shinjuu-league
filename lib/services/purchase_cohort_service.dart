/// Computes a user's next purchase cohort after a successful purchase.
///
/// See [CohortProperties] for the cohort semantics this mirrors: 'F2P' never
/// purchased, 'D1Payer'/'D7Payer'/'D30Payer' record how long after install
/// the user's *first* purchase happened, and 'Whale' marks anyone who has
/// purchased more than once (a stronger LTV signal than purchase timing).
///
/// This is pure logic (no Firestore/Firebase access) so it can be unit
/// tested directly; callers persist the result via
/// `FirestoreService.updateUserPurchaseCohort`.
class PurchaseCohortService {
  static const String f2p = 'F2P';
  static const String d1Payer = 'D1Payer';
  static const String d7Payer = 'D7Payer';
  static const String d30Payer = 'D30Payer';
  static const String whale = 'Whale';

  /// [currentCohort] is the user's `cohortProperties.purchaseCohort` value
  /// from *before* this purchase (pass 'F2P' or null-coalesce to it for a
  /// user with no `cohortProperties` yet). [installDate] should be
  /// `User.createdAt`.
  static String nextCohortAfterPurchase({
    required String currentCohort,
    required DateTime installDate,
    DateTime? now,
  }) {
    // Any purchase after the first is the "multiple purchases" Whale signal,
    // regardless of timing.
    if (currentCohort != f2p) return whale;

    final daysSinceInstall = (now ?? DateTime.now())
        .difference(installDate)
        .inDays;
    if (daysSinceInstall <= 1) return d1Payer;
    if (daysSinceInstall <= 7) return d7Payer;
    return d30Payer;
  }
}
