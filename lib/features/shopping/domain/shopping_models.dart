final class ShoppingListModel {
  const ShoppingListModel({
    required this.id,
    required this.familyId,
    required this.name,
    required this.createdById,
    required this.archived,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  final String id;
  final String familyId;
  final String name;
  final String createdById;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
}

final class ShoppingItemModel {
  const ShoppingItemModel({
    required this.id,
    required this.listId,
    required this.name,
    required this.checked,
    required this.position,
    required this.createdById,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    this.quantity,
    this.unit,
    this.category,
    this.checkedById,
    this.checkedAt,
  });

  final String id;
  final String listId;
  final String name;
  final double? quantity;
  final String? unit;
  final String? category;
  final bool checked;
  final String? checkedById;
  final DateTime? checkedAt;
  final int position;
  final String createdById;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
}

final class ShoppingItemDraft {
  const ShoppingItemDraft({
    required this.name,
    this.quantity,
    this.unit,
    this.category,
  });

  final String name;
  final double? quantity;
  final String? unit;
  final String? category;
}
