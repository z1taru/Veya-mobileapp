import 'package:dio/dio.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/family_model.dart';
import '../domain/family_repository.dart';
import 'family_dto.dart';
import 'family_remote_data_source.dart';

final class FamilyRepositoryImpl implements FamilyRepository {
  const FamilyRepositoryImpl(this._remote, this._database);

  final FamilyRemoteDataSource _remote;
  final AppDatabase _database;

  @override
  Stream<FamilyModel?> watchCurrentFamily() =>
      _database.watchCurrentFamily().map((row) => row?.toModel());

  @override
  Stream<List<FamilyMemberModel>> watchMembers(String familyId) => _database
      .watchFamilyMembers(familyId)
      .map((rows) => rows.map((row) => row.toModel()).toList(growable: false));

  @override
  Future<FamilyModel> refreshCurrentFamily() async {
    try {
      final family = await _remote.getCurrentFamily();
      final members = await _remote.getMembers(family.id);
      await _database.transaction(() async {
        await _database.upsertFamily(family.toCompanion());
        await _database.replaceFamilyMembers(
          family.id,
          members.map((member) => member.toCompanion()).toList(),
        );
      });
      return family.toModel();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<void> inviteByEmail({
    required String familyId,
    required String email,
  }) async {
    try {
      await _remote.inviteByEmail(familyId: familyId, email: email);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
