import 'package:dio/dio.dart';

import 'family_dto.dart';

final class FamilyRemoteDataSource {
  const FamilyRemoteDataSource(this._dio);

  final Dio _dio;

  Future<FamilyDto> getCurrentFamily() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/families/current',
    );
    return FamilyDto.fromJson(response.data!);
  }

  Future<List<FamilyMemberDto>> getMembers(String familyId) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/families/$familyId/members',
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map((json) => FamilyMemberDto.fromJson(json, familyId: familyId))
        .toList(growable: false);
  }

  Future<void> inviteByEmail({
    required String familyId,
    required String email,
  }) => _dio.post<void>(
    '/api/families/$familyId/members/invite',
    data: {'email': email, 'role': 'MEMBER'},
  );
}
