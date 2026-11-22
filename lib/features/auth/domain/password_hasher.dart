import 'dart:convert';

import 'package:crypto/crypto.dart' show sha256;

/// The one password hashing scheme of the app, carried over unchanged from
/// the pre-refactor `AuthService` (sha256 of the utf-8 password). Kept in one
/// place so a future salted scheme is a single swap.
String hashPassword(String password) =>
    sha256.convert(utf8.encode(password)).toString();
