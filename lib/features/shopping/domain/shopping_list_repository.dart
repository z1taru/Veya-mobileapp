import 'shopping_models.dart';

abstract interface class ShoppingListRepository {
  Stream<List<ShoppingListModel>> watchLists(String familyId);
  Stream<List<ShoppingItemModel>> watchItems(String listId);
  Future<ShoppingListModel?> getList(String id);
  Future<String> createList({
    required String familyId,
    required String createdById,
    required String name,
  });
  Future<void> renameList(String id, String name);
  Future<void> archiveList(String id, bool archived);
  Future<void> deleteList(String id);
  Future<void> addItem({
    required String listId,
    required String createdById,
    required ShoppingItemDraft draft,
  });
  Future<void> setItemChecked({
    required String id,
    required bool checked,
    required String currentUserId,
  });
  Future<void> deleteItem(String id);
}
