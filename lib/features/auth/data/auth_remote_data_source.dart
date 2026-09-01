import 'package:dio/dio.dart';

import 'auth_dto.dart';

final class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AuthResponseDto> login(LoginRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: request.toJson(),
    );
    return AuthResponseDto.fromJson(response.data!);
  }

  Future<AuthResponseDto> register(RegisterRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/register',
      data: request.toJson(),
    );
    return AuthResponseDto.fromJson(response.data!);
  }

  Future<UserDto> getMe() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/auth/me');
    return UserDto.fromJson(response.data!);
  }

  Future<void> logout() => _dio.post<void>('/api/auth/logout');
}
