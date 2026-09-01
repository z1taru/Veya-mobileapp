import 'package:dio/dio.dart';

final class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.fieldErrors = const {},
  });

  factory ApiException.fromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final rawErrors = data['errors'];
      final fieldErrors = <String, String>{};
      if (rawErrors is List) {
        for (final item in rawErrors.whereType<Map<String, dynamic>>()) {
          final field = item['field'];
          final message = item['message'];
          if (field is String && message is String) {
            fieldErrors[field] = message;
          }
        }
      }
      return ApiException(
        message: data['message'] as String? ?? 'Ошибка запроса',
        statusCode: error.response?.statusCode,
        fieldErrors: fieldErrors,
      );
    }

    return ApiException(
      message: error.type == DioExceptionType.connectionError
          ? 'Не удалось подключиться к серверу'
          : 'Что-то пошло не так. Попробуйте ещё раз.',
      statusCode: error.response?.statusCode,
    );
  }

  final String message;
  final int? statusCode;
  final Map<String, String> fieldErrors;

  @override
  String toString() => message;
}
