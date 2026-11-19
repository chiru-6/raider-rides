import 'package:flutter_test/flutter_test.dart';
import 'package:raider_rides/core/validators.dart';
import 'package:raider_rides/models/app_user.dart';

void main() {
  group('validateTtuEmail', () {
    test('accepts TTU addresses in any case', () {
      expect(validateTtuEmail('raider@ttu.edu'), isNull);
      expect(validateTtuEmail('  Jane.Doe@TTU.EDU '), isNull);
    });

    test('rejects empty and non-TTU addresses', () {
      expect(validateTtuEmail(''), isNotNull);
      expect(validateTtuEmail(null), isNotNull);
      expect(validateTtuEmail('raider@gmail.com'), isNotNull);
      expect(validateTtuEmail('raider@ttu.edu.evil.com'), isNotNull);
      expect(validateTtuEmail('@ttu.edu'), isNotNull);
    });
  });

  group('validateCost', () {
    test('accepts numbers from 0 to 1000', () {
      expect(validateCost('0'), isNull);
      expect(validateCost('42.50'), isNull);
      expect(validateCost('1000'), isNull);
    });

    test('rejects blanks, text, negatives and huge values', () {
      expect(validateCost(''), isNotNull);
      expect(validateCost('abc'), isNotNull);
      expect(validateCost('-5'), isNotNull);
      expect(validateCost('5000'), isNotNull);
    });
  });

  test('AppUser.fromEmail derives a stable id and initials', () {
    final user = AppUser.fromEmail(name: ' Jane Q Doe ', email: 'Jane.Doe@ttu.edu');
    expect(user.id, 'u_jane_doe');
    expect(user.email, 'jane.doe@ttu.edu');
    expect(user.name, 'Jane Q Doe');
    expect(user.initials, 'JD');
  });
}
