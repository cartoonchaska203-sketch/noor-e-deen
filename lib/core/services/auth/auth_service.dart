/// Authentication service — Phase 4 integration point.
///
/// WHAT IT WILL DO (Phase 4):
///   * Optional sign-in with Google / Apple / Email.
///   * Required for cloud sync of bookmarks, Hifz progress, goals, settings.
///
/// REQUIRED TO ACTIVATE (choose ONE provider):
///   Option A — Supabase:
///     1. Add `supabase_flutter` dependency.
///     2. Set env: SUPABASE_URL, SUPABASE_ANON_KEY (see .env.example).
///     3. Enable Google/Apple/email providers in the Supabase dashboard.
///   Option B — Firebase:
///     1. Add `firebase_core` + `firebase_auth` + `google_sign_in`.
///     2. Add google-services.json / GoogleService-Info.plist.
///     3. Enable the wanted sign-in methods in the Firebase console.
///
/// The app is fully usable WITHOUT an account in every phase; auth only
/// unlocks sync. [StubAuthService] reports "not configured" honestly.
abstract class AuthUser {
  String get id;
  String? get email;
  String? get displayName;
}

abstract class AuthService {
  Future<AuthUser?> get currentUser;
  Stream<AuthUser?> get authStateChanges;
  Future<AuthUser> signInWithGoogle();
  Future<AuthUser> signInWithApple();
  Future<AuthUser> signInWithEmail(String email, String password);
  Future<void> signOut();
  Future<void> deleteAccount();
}

/// Phase 1 implementation: auth is not configured.
class StubAuthService implements AuthService {
  @override
  Future<AuthUser?> get currentUser async => null;

  @override
  Stream<AuthUser?> get authStateChanges => const Stream.empty();

  @override
  Future<AuthUser> signInWithGoogle() {
    throw UnsupportedError(
      'Sign-in is not configured yet (Phase 4). See auth_service.dart docs.',
    );
  }

  @override
  Future<AuthUser> signInWithApple() {
    throw UnsupportedError(
      'Sign-in is not configured yet (Phase 4). See auth_service.dart docs.',
    );
  }

  @override
  Future<AuthUser> signInWithEmail(String email, String password) {
    throw UnsupportedError(
      'Sign-in is not configured yet (Phase 4). See auth_service.dart docs.',
    );
  }

  @override
  Future<void> signOut() async {
    // Nothing to sign out from.
  }

  @override
  Future<void> deleteAccount() async {
    // Nothing to delete.
  }
}
