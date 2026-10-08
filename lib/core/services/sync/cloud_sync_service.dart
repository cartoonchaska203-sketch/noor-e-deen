/// Cloud sync service — Phase 4 integration point.
///
/// WHAT IT WILL DO (Phase 4):
///   * Sync Quran bookmarks, last-read position, Hifz progress, Tasbeeh
///     totals, goals, favourites and settings across the user's devices.
///
/// REQUIRED TO ACTIVATE:
///   1. A configured [AuthService] (Supabase or Firebase — see
///      auth_service.dart).
///   2. A per-user key-value/document store on the same backend
///      (Supabase table `user_sync` or Firestore collection `users/{uid}`).
///   3. Conflict policy: last-write-wins per document, decided client-side.
///
/// All local data remains the source of truth in Phase 1; nothing leaves
/// the device. [StubCloudSyncService] is a documented no-op.
abstract class CloudSyncService {
  Future<bool> get isConfigured;
  Future<void> pushNow();
  Future<void> pullNow();
  Future<DateTime?> get lastSyncedAt;
}

/// Phase 1 implementation: sync is not configured.
class StubCloudSyncService implements CloudSyncService {
  @override
  Future<bool> get isConfigured async => false;

  @override
  Future<void> pushNow() async {
    // No-op until Phase 4.
  }

  @override
  Future<void> pullNow() async {
    // No-op until Phase 4.
  }

  @override
  Future<DateTime?> get lastSyncedAt async => null;
}
