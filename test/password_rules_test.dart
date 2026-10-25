import 'dart:convert';
import 'package:ecare_plus_mobile/utils/password_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Password writes require 12 characters, ASCII letter and digit', () {
    expect(validateNewPassword(null), isNotNull);
    expect(validateNewPassword(''), isNotNull);
    expect(validateNewPassword('Abcdefghi12'), isNotNull);
    expect(validateNewPassword('Abcdefghij12'), isNull);
    expect(validateNewPassword('ééééééééééé1'), isNotNull);
    expect(validateNewPassword('Abcdefghijkl'), isNotNull);
  });
  final cases = <String, (String, int, bool)>{
    'ASCII 72 bytes': ('A1${'a' * 70}', 72, true),
    'ASCII 73 bytes': ('A1${'a' * 71}', 73, false),
    'Unicode 72 bytes': ('A1${'é' * 35}', 72, true),
    'Unicode 73 bytes': ('A1${'é' * 35}a', 73, false),
    'Emoji 72 bytes': ('A1${'🙂' * 17}ab', 72, true),
    'Emoji 73 bytes': ('A1${'🙂' * 17}abc', 73, false),
  };
  for (final entry in cases.entries) {
    test(entry.key, () {
      expect(utf8.encode(entry.value.$1).length, entry.value.$2);
      expect(validateNewPassword(entry.value.$1) == null, entry.value.$3);
    });
  }
}
