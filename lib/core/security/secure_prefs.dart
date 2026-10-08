import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure key-value storage for sensitive items (Phase 6).
///
/// Uses the platform keychain/keystore:
/// - Android: EncryptedSharedPreferences (AES)
/// - iOS: Keychain
///
/// NON-sensitive preferences (theme, locale, prayer settings) stay in
/// shared_preferences via [AppState] / [UserDataRepository]. Only
/// secrets go here: admin PIN, app-lock PIN.
class SecurePrefs {
  SecurePrefs._();
  static final SecurePrefs instance = SecurePrefs._();

  static const _kAdminPin = 'admin_pin';
  static const _kAppLockPin = 'app_lock_pin';
  static const _kAppLockEnabled = 'app_lock_enabled';
  static const _kBiometricEnabled = 'biometric_enabled';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // --- Admin PIN ---
  Future<bool> hasAdminPin() async =>
      (await _storage.read(key: _kAdminPin)) != null;

  Future<void> setAdminPin(String pin) =>
      _storage.write(key: _kAdminPin, value: pin);

  Future<bool> verifyAdminPin(String pin) async =>
      (await _storage.read(key: _kAdminPin)) == pin;

  Future<void> clearAdminPin() => _storage.delete(key: _kAdminPin);

  // --- App lock ---
  Future<bool> isAppLockEnabled() async =>
      (await _storage.read(key: _kAppLockEnabled)) == '1';

  Future<void> setAppLockEnabled(bool v) =>
      _storage.write(key: _kAppLockEnabled, value: v ? '1' : '0');

  Future<bool> hasAppLockPin() async =>
      (await _storage.read(key: _kAppLockPin)) != null;

  Future<void> setAppLockPin(String pin) =>
      _storage.write(key: _kAppLockPin, value: pin);

  Future<bool> verifyAppLockPin(String pin) async =>
      (await _storage.read(key: _kAppLockPin)) == pin;

  Future<bool> isBiometricEnabled() async =>
      (await _storage.read(key: _kBiometricEnabled)) == '1';

  Future<void> setBiometricEnabled(bool v) =>
      _storage.write(key: _kBiometricEnabled, value: v ? '1' : '0');

  /// Wipes all secrets (used on "reset app data").
  Future<void> clearAll() => _storage.deleteAll();
}
