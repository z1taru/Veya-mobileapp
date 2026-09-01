enum FamilyRole {
  owner,
  parent,
  member,
  unknown;

  factory FamilyRole.fromJson(String? value) => switch (value) {
    'OWNER' => FamilyRole.owner,
    'PARENT' => FamilyRole.parent,
    'MEMBER' => FamilyRole.member,
    _ => FamilyRole.unknown,
  };
}

extension FamilyRoleLabel on FamilyRole {
  String get label => switch (this) {
    FamilyRole.owner => 'Владелец',
    FamilyRole.parent => 'Родитель',
    FamilyRole.member => 'Участник',
    FamilyRole.unknown => 'Участник',
  };
}

final class FamilyModel {
  const FamilyModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.timeZone,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  final String id;
  final String name;
  final String ownerId;
  final String timeZone;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
}

final class FamilyMemberModel {
  const FamilyMemberModel({
    required this.id,
    required this.familyId,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.joinedAt,
    required this.updatedAt,
    required this.version,
    this.avatarUrl,
  });

  final String id;
  final String familyId;
  final String userId;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final FamilyRole role;
  final DateTime joinedAt;
  final DateTime updatedAt;
  final int version;
}
