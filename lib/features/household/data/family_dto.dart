import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/models/family_model.dart';

final class FamilyDto {
  const FamilyDto({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.timeZone,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  factory FamilyDto.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['createdAt'] as String);
    return FamilyDto(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['ownerId'] as String,
      timeZone: json['timeZone'] as String? ?? 'UTC',
      createdAt: createdAt,
      updatedAt: json['updatedAt'] == null
          ? createdAt
          : DateTime.parse(json['updatedAt'] as String),
      version: json['version'] as int? ?? 0,
    );
  }

  final String id;
  final String name;
  final String ownerId;
  final String timeZone;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  FamilyModel toModel() => FamilyModel(
    id: id,
    name: name,
    ownerId: ownerId,
    timeZone: timeZone,
    createdAt: createdAt,
    updatedAt: updatedAt,
    version: version,
  );

  FamilyRecordsCompanion toCompanion() => FamilyRecordsCompanion.insert(
    id: id,
    name: name,
    ownerId: ownerId,
    timeZone: timeZone,
    createdAt: createdAt,
    updatedAt: updatedAt,
    version: Value(version),
  );
}

final class FamilyMemberDto {
  const FamilyMemberDto({
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

  factory FamilyMemberDto.fromJson(
    Map<String, dynamic> json, {
    required String familyId,
  }) {
    final joinedAt = json['joinedAt'] == null
        ? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
        : DateTime.parse(json['joinedAt'] as String);
    return FamilyMemberDto(
      id: json['id'] as String,
      familyId: json['familyId'] as String? ?? familyId,
      userId: json['userId'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String? ?? 'MEMBER',
      joinedAt: joinedAt,
      updatedAt: json['updatedAt'] == null
          ? joinedAt
          : DateTime.parse(json['updatedAt'] as String),
      version: json['version'] as int? ?? 0,
    );
  }

  final String id;
  final String familyId;
  final String userId;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String role;
  final DateTime joinedAt;
  final DateTime updatedAt;
  final int version;

  FamilyMemberRecordsCompanion toCompanion() =>
      FamilyMemberRecordsCompanion.insert(
        id: id,
        familyId: familyId,
        userId: userId,
        fullName: fullName,
        email: email,
        avatarUrl: Value(avatarUrl),
        role: role,
        joinedAt: joinedAt,
        updatedAt: updatedAt,
        version: Value(version),
      );
}

extension FamilyRowMapper on FamilyRow {
  FamilyModel toModel() => FamilyModel(
    id: id,
    name: name,
    ownerId: ownerId,
    timeZone: timeZone,
    createdAt: createdAt,
    updatedAt: updatedAt,
    version: version,
  );
}

extension FamilyMemberRowMapper on FamilyMemberRow {
  FamilyMemberModel toModel() => FamilyMemberModel(
    id: id,
    familyId: familyId,
    userId: userId,
    fullName: fullName,
    email: email,
    avatarUrl: avatarUrl,
    role: FamilyRole.fromJson(role),
    joinedAt: joinedAt,
    updatedAt: updatedAt,
    version: version,
  );
}
