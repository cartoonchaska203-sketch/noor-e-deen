import 'package:flutter_test/flutter_test.dart';
import 'package:noor_e_deen/core/security/input_validation.dart';

void main() {
  group('InputValidation', () {
    test('validateName rejects empty and overlong input', () {
      expect(InputValidation.validateName(null), 'required');
      expect(InputValidation.validateName('   '), 'required');
      expect(InputValidation.validateName('a' * 81), 'too_long');
      expect(InputValidation.validateName('Usama'), isNull);
      expect(InputValidation.validateName('محمد اسامہ'), isNull);
    });

    test('validateName rejects control characters', () {
      expect(
          InputValidation.validateName('test\x00name'), 'invalid_chars');
      // Bidi overrides (spoofing risk) are rejected.
      expect(
          InputValidation.validateName('test\u202Ename'), 'invalid_chars');
    });

    test('validateAmount accepts valid numbers', () {
      expect(InputValidation.validateAmount('100'), isNull);
      expect(InputValidation.validateAmount('10.5'), isNull);
      expect(InputValidation.validateAmount('abc'), 'not_a_number');
      expect(InputValidation.validateAmount('-5'), 'negative');
      expect(InputValidation.validateAmount(''), 'required');
    });

    test('validatePin enforces 4-8 digits', () {
      expect(InputValidation.validatePin('1234'), isNull);
      expect(InputValidation.validatePin('12345678'), isNull);
      expect(InputValidation.validatePin('123'), 'pin_format');
      expect(InputValidation.validatePin('123456789'), 'pin_format');
      expect(InputValidation.validatePin('12ab'), 'pin_format');
      expect(InputValidation.validatePin(''), 'required');
    });

    test('sanitize strips forbidden characters', () {
      expect(InputValidation.sanitize('  hello\x00  '), 'hello');
    });

    test('message returns human-readable text', () {
      expect(InputValidation.message('required'),
          'This field is required.');
      expect(InputValidation.message('pin_format'),
          'PIN must be 4–8 digits.');
    });
  });
}
