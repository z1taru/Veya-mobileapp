import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final class TokenPair {
  const TokenPair({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

abstract interface class TokenStorage {
  Future<TokenPair?> read();
  Future<void> write(TokenPair tokens);
  Future<void> clear();
}

final class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenPairKey = 'auth.token_pair';

  final FlutterSecureStorage _storage;

  @override
  Future<TokenPair?> read() async {
    final encoded = await _storage.read(key: _tokenPairKey);
    if (encoded == null) return null;
    try {
      final json = jsonDecode(encoded) as Map<String, dynamic>;
      return TokenPair(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      );
    } on Object {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(TokenPair tokens) => _storage.write(
    key: _tokenPairKey,
    value: jsonEncode({
      'accessToken': tokens.accessToken,
      'refreshToken': tokens.refreshToken,
    }),
  );

  @override
  Future<void> clear() => _storage.delete(key: _tokenPairKey);
}
