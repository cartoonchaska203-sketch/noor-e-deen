import 'package:local_auth/local_auth.dart';

import 'secure_prefs.dart';

/// App lock (Phase 6): optional PIN + biometric gate at startup.
///
/// - PIN is stored in the platform keychain via [SecurePrefs]
///   (never in shared_preferences, never in plain text).
/// - Biometric (fingerprint/face) is offered only when the device
///   supports it AND a PIN exists as fallback.
/// - When the app lock is enabled, [AppLockGate] (in widgets) blocks
///   the UI until unlocked. This service is the logic behind it.
class AppLockService {
  AppLockService._();
  static final AppLockService instance = AppLockService._();

  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> get isEnabled => SecurePrefs.instance.isAppLockEnabled();

  Future<bool> get canUseBiometrics async {
    try {
      return await _auth.canCheckBiometrics ||
          await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Attempt biometric unlock. Returns true on success.
  Future<bool> authenticateBiometric() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock Noor-e-Deen',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> enable(String pin) async {
    await SecurePrefs.instance.setAppLockPin(pin);
    await SecurePrefs.instance.setAppLockEnabled(true);
  }

  Future<void> disable() async {
    await SecurePrefs.instance.setAppLockEnabled(false);
    await SecurePrefs.instance.setBiometricEnabled(false);
  }

  Future<bool> verifyPin(String pin) =>
      SecurePrefs.instance.verifyAppLockPin(pin);
}
