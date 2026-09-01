import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/id_provider.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../household/presentation/family_providers.dart';
import '../data/local_activity_repository.dart';
import '../domain/activity_models.dart';
import '../domain/activity_repository.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return LocalActivityRepository(
    ref.watch(databaseProvider),
    ref.watch(uuidProvider),
  );
});

final activityEventsProvider =
    StreamProvider.autoDispose<List<ActivityEventModel>>((ref) {
      final family = ref.watch(currentFamilyProvider).valueOrNull;
      if (family == null) return Stream.value(const []);
      return ref.watch(activityRepositoryProvider).watchEvents(family.id);
    });
