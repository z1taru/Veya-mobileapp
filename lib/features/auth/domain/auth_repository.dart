import '../../../core/models/user_model.dart';

abstract interface class AuthRepository {
  Future<UserModel?> restoreSession();

  Future<UserModel> login({required String email, required String password});

  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
    required String familyName,
  });

  Future<void> logout();
}
