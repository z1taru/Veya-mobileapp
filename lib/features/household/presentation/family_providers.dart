import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/family_model.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/family_remote_data_source.dart';
import '../data/family_repository_impl.dart';
import '../domain/family_repository.dart';

final familyRemoteDataSourceProvider = Provider<FamilyRemoteDataSource>((ref) {
  return FamilyRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return FamilyRepositoryImpl(
    ref.watch(familyRemoteDataSourceProvider),
    ref.watch(databaseProvider),
  );
});

final currentFamilyProvider = StreamProvider<FamilyModel?>((ref) {
  return ref.watch(familyRepositoryProvider).watchCurrentFamily();
});

final familyMembersProvider = StreamProvider.family
    .autoDispose<List<FamilyMemberModel>, String>((ref, familyId) {
      return ref.watch(familyRepositoryProvider).watchMembers(familyId);
    });

final householdControllerProvider =
    StateNotifierProvider<HouseholdController, AsyncValue<void>>((ref) {
      final controller = HouseholdController(
        ref.watch(familyRepositoryProvider),
      );
      unawaited(controller.refresh());
      return controller;
    });

final class HouseholdController extends StateNotifier<AsyncValue<void>> {
  HouseholdController(this._repository) : super(const AsyncLoading());

  final FamilyRepository _repository;

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.refreshCurrentFamily);
  }

  Future<bool> invite({required String familyId, required String email}) async {
    state = const AsyncLoading();
    try {
      await _repository.inviteByEmail(familyId: familyId, email: email);
      state = const AsyncData(null);
      return true;
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}
