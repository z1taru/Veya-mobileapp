import '../../../core/models/family_model.dart';

abstract interface class FamilyRepository {
  Stream<FamilyModel?> watchCurrentFamily();
  Stream<List<FamilyMemberModel>> watchMembers(String familyId);
  Future<FamilyModel> refreshCurrentFamily();
  Future<void> inviteByEmail({required String familyId, required String email});
}
