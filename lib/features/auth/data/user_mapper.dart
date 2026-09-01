import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/models/user_model.dart';
import 'auth_dto.dart';

extension UserDtoMapper on UserDto {
  UserRecordsCompanion toCompanion() => UserRecordsCompanion.insert(
    id: id,
    fullName: fullName,
    email: email,
    avatarUrl: Value(avatarUrl),
    status: status,
    createdAt: createdAt,
    updatedAt: Value(updatedAt),
    version: Value(version),
  );
}

extension UserRowMapper on UserRow {
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
