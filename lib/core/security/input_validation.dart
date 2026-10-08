/// Input validation helpers (Phase 6 security hardening).
///
/// Every user-editable text field in the app should route through these
/// validators before persisting or displaying input. The goal is to
/// reject control characters, absurd lengths, and empty-meaningful
/// submissions — not to censor legitimate Urdu/Arabic/English text.
class InputValidation {
  InputValidation._();

  /// Characters that must never appear in stored user text
  /// (control chars, bidi overrides that could spoof display order).
  static final RegExp _forbidden =
      RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F\u202A-\u202E\u2066-\u2069]');

  /// Returns an error string, or null when [value] is acceptable.
  static String? validateName(String? value, {int maxLength = 80}) {
    if (value == null || value.trim().isEmpty) {
      return 'required';
    }
    final v = value.trim();
    if (v.length > maxLength) return 'too_long';
    if (_forbidden.hasMatch(v)) return 'invalid_chars';
    return null;
  }

  /// Generic free-text (notes, custom dhikr, etc.).
  static String? validateText(String? value,
      {int maxLength = 500, bool allowEmpty = false}) {
    if (value == null || value.trim().isEmpty) {
      return allowEmpty ? null : 'required';
    }
    final v = value.trim();
    if (v.length > maxLength) return 'too_long';
    if (_forbidden.hasMatch(v)) return 'invalid_chars';
    return null;
  }

  /// Positive decimal number (amounts, grams).
  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) return 'required';
    final n = double.tryParse(value.trim());
    if (n == null) return 'not_a_number';
    if (n < 0) return 'negative';
    if (n > 1000000000) return 'too_large';
    return null;
  }

  /// Integer within [min]..[max].
  static String? validateInt(String? value, int min, int max) {
    if (value == null || value.trim().isEmpty) return 'required';
    final n = int.tryParse(value.trim());
    if (n == null) return 'not_a_number';
    if (n < min || n > max) return 'out_of_range';
    return null;
  }

  /// 4–8 digit PIN.
  static String? validatePin(String? value) {
    if (value == null || value.isEmpty) return 'required';
    if (!RegExp(r'^\d{4,8}$').hasMatch(value)) return 'pin_format';
    return null;
  }

  /// Sanitizes for safe display/storage: trims and strips forbidden chars.
  static String sanitize(String value) =>
      value.trim().replaceAll(_forbidden, '');

  /// Human-readable message for a validator error code.
  static String message(String code) {
    switch (code) {
      case 'required':
        return 'This field is required.';
      case 'too_long':
        return 'Text is too long.';
      case 'invalid_chars':
        return 'Text contains unsupported characters.';
      case 'not_a_number':
        return 'Enter a valid number.';
      case 'negative':
        return 'Value cannot be negative.';
      case 'too_large':
        return 'Value is too large.';
      case 'out_of_range':
        return 'Value is out of range.';
      case 'pin_format':
        return 'PIN must be 4–8 digits.';
      default:
        return 'Invalid input.';
    }
  }
}
