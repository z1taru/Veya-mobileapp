import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/user_model.dart';
import '../../../core/storage/secure_storage.dart';
import '../domain/auth_repository.dart';
import 'auth_dto.dart';
import 'auth_remote_data_source.dart';
import 'user_mapper.dart';

final class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote, this._tokenStorage, this._database);

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokenStorage;
  final AppDatabase _database;

  @override
  Future<UserModel?> restoreSession() async {
    if (await _tokenStorage.read() == null) return null;
    try {
      final user = await _remote.getMe();
      await _database.upsertUser(user.toCompanion());
      return user.toModel();
    } on DioException catch (error) {
      // A network outage must not log out an already authenticated user. The
      // interceptor clears storage only when token refresh is rejected.
      if (await _tokenStorage.read() != null) {
        return (await _database.getLastUser())?.toModel();
      }
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _persistAuthResponse(
        await _remote.login(LoginRequest(email: email, password: password)),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
    required String familyName,
  }) async {
    try {
      return await _persistAuthResponse(
        await _remote.register(
          RegisterRequest(
            fullName: fullName,
            email: email,
            password: password,
            familyName: familyName,
          ),
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<UserModel> _persistAuthResponse(AuthResponseDto response) async {
    await _tokenStorage.write(
      TokenPair(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      ),
    );
    await _database.upsertUser(response.user.toCompanion());
    return response.user.toModel();
  }

  @override
  Future<void> logout() async {
    try {
      await _remote.logout();
    } finally {
      await _tokenStorage.clear();
    }
  }
}
