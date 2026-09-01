import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../activity/domain/activity_models.dart';
import '../../activity/domain/activity_repository.dart';
import '../domain/shopping_list_repository.dart';
import '../domain/shopping_models.dart';

final class LocalShoppingListRepository implements ShoppingListRepository {
  const LocalShoppingListRepository(this._database, this._uuid, this._activity);

  final AppDatabase _database;
  final Uuid _uuid;
  final ActivityRepository _activity;

  @override
  Stream<List<ShoppingListModel>> watchLists(String familyId) => _database
      .watchShoppingLists(familyId)
      .map(
        (rows) => rows.map(_listModel).where((list) => !list.archived).toList(),
      );

  @override
  Stream<List<ShoppingItemModel>> watchItems(String listId) => _database
      .watchShoppingItems(listId)
      .map((rows) => rows.map(_itemModel).toList(growable: false));

  @override
  Future<ShoppingListModel?> getList(String id) async {
    final row = await _database.getShoppingList(id);
    return row == null ? null : _listModel(row);
  }

  @override
  Future<String> createList({
    required String familyId,
    required String createdById,
    required String name,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('Введите название списка');
    final id = _uuid.v4();
    final now = DateTime.now().toUtc();
    await _database
        .into(_database.shoppingListRecords)
        .insert(
          ShoppingListRecordsCompanion.insert(
            id: id,
            familyId: familyId,
            name: trimmed,
            createdById: createdById,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await _activity.record(
      familyId: familyId,
      actorId: createdById,
      type: ActivityEventType.shoppingListCreated,
      entityType: ActivityEntityType.shoppingList,
      entityId: id,
      payload: {'name': trimmed},
    );
    return id;
  }

  @override
  Future<void> renameList(String id, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('Введите название списка');
    return (_database.update(
      _database.shoppingListRecords,
    )..where((row) => row.id.equals(id))).write(
      ShoppingListRecordsCompanion(
        name: Value(trimmed),
        updatedAt: Value(DateTime.now().toUtc()),
        syncStatus: const Value('LOCAL'),
      ),
    );
  }

  @override
  Future<void> archiveList(String id, bool archived) =>
      (_database.update(
        _database.shoppingListRecords,
      )..where((row) => row.id.equals(id))).write(
        ShoppingListRecordsCompanion(
          archived: Value(archived),
          updatedAt: Value(DateTime.now().toUtc()),
          syncStatus: const Value('LOCAL'),
        ),
      );

  @override
  Future<void> deleteList(String id) =>
      (_database.update(
        _database.shoppingListRecords,
      )..where((row) => row.id.equals(id))).write(
        ShoppingListRecordsCompanion(
          deletedAt: Value(DateTime.now().toUtc()),
          updatedAt: Value(DateTime.now().toUtc()),
          syncStatus: const Value('LOCAL'),
        ),
      );

  @override
  Future<void> addItem({
    required String listId,
    required String createdById,
    required ShoppingItemDraft draft,
  }) async {
    final name = draft.name.trim();
    if (name.isEmpty) throw ArgumentError('Введите название покупки');
    final list = await _database.getShoppingList(listId);
    if (list == null) throw StateError('Список не найден');
    final maxExpression = _database.shoppingItemRecords.position.max();
    final maxPosition =
        await (_database.selectOnly(_database.shoppingItemRecords)
              ..addColumns([maxExpression])
              ..where(_database.shoppingItemRecords.listId.equals(listId)))
            .getSingle();
    final position = maxPosition.read(maxExpression) ?? -1;
    final id = _uuid.v4();
    final now = DateTime.now().toUtc();
    await _database
        .into(_database.shoppingItemRecords)
        .insert(
          ShoppingItemRecordsCompanion.insert(
            id: id,
            listId: listId,
            name: name,
            quantity: Value(draft.quantity),
            unit: Value(_emptyToNull(draft.unit)),
            category: Value(_emptyToNull(draft.category)),
            position: position + 1,
            createdById: createdById,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await _activity.record(
      familyId: list.familyId,
      actorId: createdById,
      type: ActivityEventType.shoppingItemAdded,
      entityType: ActivityEntityType.shoppingItem,
      entityId: id,
      payload: {'name': name, 'listId': listId},
    );
  }

  @override
  Future<void> setItemChecked({
    required String id,
    required bool checked,
    required String currentUserId,
  }) async {
    final item = await (_database.select(
      _database.shoppingItemRecords,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (item == null) return;
    final list = await _database.getShoppingList(item.listId);
    final now = DateTime.now().toUtc();
    await (_database.update(
      _database.shoppingItemRecords,
    )..where((row) => row.id.equals(id))).write(
      ShoppingItemRecordsCompanion(
        checked: Value(checked),
        checkedById: Value(checked ? currentUserId : null),
        checkedAt: Value(checked ? now : null),
        updatedAt: Value(now),
        syncStatus: const Value('LOCAL'),
      ),
    );
    if (list != null) {
      await _activity.record(
        familyId: list.familyId,
        actorId: currentUserId,
        type: ActivityEventType.shoppingItemChecked,
        entityType: ActivityEntityType.shoppingItem,
        entityId: id,
        payload: {'name': item.name, 'checked': checked},
      );
    }
  }

  @override
  Future<void> deleteItem(String id) =>
      (_database.update(
        _database.shoppingItemRecords,
      )..where((row) => row.id.equals(id))).write(
        ShoppingItemRecordsCompanion(
          deletedAt: Value(DateTime.now().toUtc()),
          updatedAt: Value(DateTime.now().toUtc()),
          syncStatus: const Value('LOCAL'),
        ),
      );

  ShoppingListModel _listModel(ShoppingListRow row) => ShoppingListModel(
    id: row.id,
    familyId: row.familyId,
    name: row.name,
    createdById: row.createdById,
    archived: row.archived,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    version: row.version,
  );

  ShoppingItemModel _itemModel(ShoppingItemRow row) => ShoppingItemModel(
    id: row.id,
    listId: row.listId,
    name: row.name,
    quantity: row.quantity,
    unit: row.unit,
    category: row.category,
    checked: row.checked,
    checkedById: row.checkedById,
    checkedAt: row.checkedAt,
    position: row.position,
    createdById: row.createdById,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    version: row.version,
  );
}

String? _emptyToNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
