import 'package:dio/dio.dart';

import '../config/app_environment.dart';
import '../storage/secure_storage.dart';
import 'auth_interceptor.dart';

final class ApiClient {
  ApiClient({
    required AppConfig config,
    required TokenStorage tokenStorage,
    void Function()? onSessionExpired,
  }) {
    final options = BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: const {'Accept': 'application/json'},
    );
    _dio = Dio(options);
    _refreshDio = Dio(options);
    _dio.interceptors.add(
      AuthInterceptor(
        _dio,
        _refreshDio,
        tokenStorage,
        onSessionExpired: onSessionExpired,
      ),
    );
  }

  late final Dio _dio;
  late final Dio _refreshDio;

  Dio get dio => _dio;
}
