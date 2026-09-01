import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/secure_storage.dart';

final class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this._authenticatedDio,
    this._refreshDio,
    this._tokenStorage, {
    this.onSessionExpired,
  });

  static const _retriedKey = 'auth.retried';
  static const _skipAuthKey = 'auth.skip';

  final Dio _authenticatedDio;
  final Dio _refreshDio;
  final TokenStorage _tokenStorage;
  final void Function()? onSessionExpired;

  Completer<bool>? _refreshCompleter;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[_skipAuthKey] != true) {
      final tokens = await _tokenStorage.read();
      if (tokens != null) {
        options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final shouldRefresh =
        err.response?.statusCode == 401 &&
        request.extra[_retriedKey] != true &&
        !_isPublicAuthPath(request.path);

    if (!shouldRefresh) {
      handler.next(err);
      return;
    }

    if (!await _refreshTokens()) {
      await _tokenStorage.clear();
      onSessionExpired?.call();
      handler.next(err);
      return;
    }

    final tokens = await _tokenStorage.read();
    if (tokens == null) {
      handler.next(err);
      return;
    }

    request.extra[_retriedKey] = true;
    request.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    try {
      handler.resolve(await _authenticatedDio.fetch<dynamic>(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  bool _isPublicAuthPath(String path) =>
      path.endsWith('/api/auth/login') ||
      path.endsWith('/api/auth/register') ||
      path.endsWith('/api/auth/refresh');

  Future<bool> _refreshTokens() {
    final activeRefresh = _refreshCompleter;
    if (activeRefresh != null) return activeRefresh.future;

    final completer = Completer<bool>();
    _refreshCompleter = completer;
    unawaited(_completeRefresh(completer));
    return completer.future;
  }

  Future<void> _completeRefresh(Completer<bool> completer) async {
    try {
      completer.complete(await _performRefresh());
    } on Object {
      completer.complete(false);
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<bool> _performRefresh() async {
    final current = await _tokenStorage.read();
    if (current == null) return false;

    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/api/auth/refresh',
        data: {'refreshToken': current.refreshToken},
      );
      final data = response.data;
      if (data == null) return false;
      final accessToken = data['accessToken'];
      final refreshToken = data['refreshToken'];
      if (accessToken is! String || refreshToken is! String) return false;

      // The pair is stored as one secure-storage value because refresh rotates
      // both credentials and the old refresh token becomes invalid immediately.
      await _tokenStorage.write(
        TokenPair(accessToken: accessToken, refreshToken: refreshToken),
      );
      return true;
    } on DioException {
      return false;
    }
  }
}
