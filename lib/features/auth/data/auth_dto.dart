import '../../../core/models/user_model.dart';

final class UserDto {
  const UserDto({
    required this.id,
    required this.fullName,
    required this.email,
    required this.status,
    required this.createdAt,
    this.avatarUrl,
    this.updatedAt,
    this.version = 0,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
    id: json['id'] as String,
    fullName: json['fullName'] as String,
    email: json['email'] as String,
    avatarUrl: json['avatarUrl'] as String?,
    status: json['status'] as String? ?? 'UNKNOWN',
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: json['updatedAt'] == null
        ? null
        : DateTime.parse(json['updatedAt'] as String),
    version: json['version'] as int? ?? 0,
  );

  final String id;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int version;

  UserModel toModel() => UserModel(
    id: id,
    fullName: fullName,
    email: email,
    avatarUrl: avatarUrl,
    status: UserStatus.fromJson(status),
    createdAt: createdAt,
    updatedAt: updatedAt,
    version: version,
  );
}

final class AuthResponseDto {
  const AuthResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) =>
      AuthResponseDto(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
      );

  final String accessToken;
  final String refreshToken;
  final UserDto user;
}

final class LoginRequest {
  const LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

final class RegisterRequest {
  const RegisterRequest({
    required this.fullName,
    required this.email,
    required this.password,
    required this.familyName,
  });

  final String fullName;
  final String email;
  final String password;
  final String familyName;

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'email': email,
    'password': password,
    'familyName': familyName,
  };
}
