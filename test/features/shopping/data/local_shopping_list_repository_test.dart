import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:veya/core/database/app_database.dart';
import 'package:veya/features/activity/data/local_activity_repository.dart';
import 'package:veya/features/shopping/data/local_shopping_list_repository.dart';
import 'package:veya/features/shopping/domain/shopping_models.dart';

void main() {
  late AppDatabase database;
  late LocalShoppingListRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = LocalShoppingListRepository(
      database,
      const Uuid(),
      LocalActivityRepository(database, const Uuid()),
    );
  });

  tearDown(() => database.close());

  test('supports multiple named lists and reactive checklist items', () async {
    final groceries = await repository.createList(
      familyId: 'family-1',
      createdById: 'user-1',
      name: 'Продукты',
    );
    await repository.createList(
      familyId: 'family-1',
      createdById: 'user-1',
      name: 'Для ремонта',
    );
    await repository.addItem(
      listId: groceries,
      createdById: 'user-1',
      draft: const ShoppingItemDraft(name: 'Молоко', quantity: 2, unit: 'л'),
    );

    expect(await repository.watchLists('family-1').first, hasLength(2));
    final item = (await repository.watchItems(groceries).first).single;
    expect(item.name, 'Молоко');
    expect(item.quantity, 2);

    await repository.setItemChecked(
      id: item.id,
      checked: true,
      currentUserId: 'user-2',
    );
    final checked = (await repository.watchItems(groceries).first).single;
    expect(checked.checked, isTrue);
    expect(checked.checkedById, 'user-2');
    expect(checked.checkedAt, isNotNull);
  });
}
