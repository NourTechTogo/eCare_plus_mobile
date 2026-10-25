import 'dart:convert';

const newPasswordHint =
    '12 caractères minimum, une lettre A–Z et un chiffre ; 72 octets UTF-8 maximum.';

/// Shared policy for password writes. Login must accept existing passwords.
String? validateNewPassword(String? password) {
  if (password == null || password.isEmpty) return 'Ce champ est obligatoire';
  if (password.length < 12 ||
      !RegExp(r'[A-Za-z]').hasMatch(password) ||
      !RegExp(r'[0-9]').hasMatch(password) ||
      utf8.encode(password).length > 72) {
    return newPasswordHint;
  }
  return null;
}
