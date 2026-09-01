import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veya/core/api/auth_interceptor.dart';
import 'package:veya/core/storage/secure_storage.dart';

void main() {
  test('parallel 401 responses perform one rotating refresh', () async {
    final storage = _MemoryTokenStorage(
      const TokenPair(accessToken: 'old-access', refreshToken: 'old-refresh'),
    );
    final authenticatedDio = Dio(BaseOptions(baseUrl: 'https://veya.test'));
    final refreshDio = Dio(BaseOptions(baseUrl: 'https://veya.test'));
    var refreshCount = 0;

    authenticatedDio.httpClientAdapter = _StubAdapter((options) async {
      final token = options.headers['Authorization'];
      if (token == 'Bearer new-access') {
        return _jsonResponse({'ok': true}, 200);
      }
      return _jsonResponse({'message': 'expired'}, 401);
    });
    refreshDio.httpClientAdapter = _StubAdapter((options) async {
      refreshCount++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return _jsonResponse({
        'accessToken': 'new-access',
        'refreshToken': 'new-refresh',
      }, 200);
    });
    authenticatedDio.interceptors.add(
      AuthInterceptor(authenticatedDio, refreshDio, storage),
    );

    final responses = await Future.wait([
      authenticatedDio.get<Map<String, dynamic>>('/api/auth/me'),
      authenticatedDio.get<Map<String, dynamic>>('/api/auth/me'),
    ]);

    expect(refreshCount, 1);
    expect(responses.every((response) => response.data?['ok'] == true), isTrue);
    expect((await storage.read())?.refreshToken, 'new-refresh');
  });
}

ResponseBody _jsonResponse(Map<String, dynamic> body, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

final class _MemoryTokenStorage implements TokenStorage {
  _MemoryTokenStorage(this.tokens);

  TokenPair? tokens;

  @override
  Future<void> clear() async => tokens = null;

  @override
  Future<TokenPair?> read() async => tokens;

  @override
  Future<void> write(TokenPair tokens) async => this.tokens = tokens;
}

final class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options);

  @override
  void close({bool force = false}) {}
}
