enum UserStatus {
  active,
  inactive,
  banned,
  unknown;

  factory UserStatus.fromJson(String? value) => switch (value) {
    'ACTIVE' => UserStatus.active,
    'INACTIVE' => UserStatus.inactive,
    'BANNED' => UserStatus.banned,
    _ => UserStatus.unknown,
  };
}

final class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.status,
    required this.createdAt,
    this.avatarUrl,
    this.updatedAt,
    this.version = 0,
  });

  final String id;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int version;
}
