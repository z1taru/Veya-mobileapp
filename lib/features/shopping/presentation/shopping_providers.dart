import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/id_provider.dart';
import '../../activity/presentation/activity_providers.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../household/presentation/family_providers.dart';
import '../data/local_shopping_list_repository.dart';
import '../domain/shopping_list_repository.dart';
import '../domain/shopping_models.dart';

final shoppingListRepositoryProvider = Provider<ShoppingListRepository>((ref) {
  return LocalShoppingListRepository(
    ref.watch(databaseProvider),
    ref.watch(uuidProvider),
    ref.watch(activityRepositoryProvider),
  );
});

final shoppingListsProvider =
    StreamProvider.autoDispose<List<ShoppingListModel>>((ref) {
      final family = ref.watch(currentFamilyProvider).valueOrNull;
      if (family == null) return Stream.value(const []);
      return ref.watch(shoppingListRepositoryProvider).watchLists(family.id);
    });

final shoppingListProvider = FutureProvider.autoDispose
    .family<ShoppingListModel?, String>((ref, id) {
      return ref.watch(shoppingListRepositoryProvider).getList(id);
    });

final shoppingItemsProvider = StreamProvider.autoDispose
    .family<List<ShoppingItemModel>, String>((ref, listId) {
      return ref.watch(shoppingListRepositoryProvider).watchItems(listId);
    });
