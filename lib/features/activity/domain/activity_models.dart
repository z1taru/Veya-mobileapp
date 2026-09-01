enum ActivityEventType {
  taskCreated,
  taskUpdated,
  taskAssigned,
  taskStatusChanged,
  taskCommentAdded,
  taskAttachmentAdded,
  shoppingListCreated,
  shoppingItemAdded,
  shoppingItemChecked,
  memberJoined,
  memberRemoved,
  familyUpdated;

  String get wireName => switch (this) {
    taskCreated => 'TASK_CREATED',
    taskUpdated => 'TASK_UPDATED',
    taskAssigned => 'TASK_ASSIGNED',
    taskStatusChanged => 'TASK_STATUS_CHANGED',
    taskCommentAdded => 'TASK_COMMENT_ADDED',
    taskAttachmentAdded => 'TASK_ATTACHMENT_ADDED',
    shoppingListCreated => 'SHOPPING_LIST_CREATED',
    shoppingItemAdded => 'SHOPPING_ITEM_ADDED',
    shoppingItemChecked => 'SHOPPING_ITEM_CHECKED',
    memberJoined => 'MEMBER_JOINED',
    memberRemoved => 'MEMBER_REMOVED',
    familyUpdated => 'FAMILY_UPDATED',
  };

  factory ActivityEventType.fromWire(String value) => values.firstWhere(
    (item) => item.wireName == value,
    orElse: () => ActivityEventType.familyUpdated,
  );
}

enum ActivityEntityType {
  task,
  taskComment,
  shoppingList,
  shoppingItem,
  family,
  familyMember;

  String get wireName => switch (this) {
    task => 'TASK',
    taskComment => 'TASK_COMMENT',
    shoppingList => 'SHOPPING_LIST',
    shoppingItem => 'SHOPPING_ITEM',
    family => 'FAMILY',
    familyMember => 'FAMILY_MEMBER',
  };

  factory ActivityEntityType.fromWire(String value) => values.firstWhere(
    (item) => item.wireName == value,
    orElse: () => ActivityEntityType.family,
  );
}

final class ActivityEventModel {
  const ActivityEventModel({
    required this.id,
    required this.familyId,
    required this.type,
    required this.entityType,
    required this.entityId,
    required this.payload,
    required this.createdAt,
    this.actorId,
  });

  final String id;
  final String familyId;
  final String? actorId;
  final ActivityEventType type;
  final ActivityEntityType entityType;
  final String entityId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  String get title => switch (type) {
    ActivityEventType.taskCreated => 'Создана задача',
    ActivityEventType.taskUpdated => 'Задача изменена',
    ActivityEventType.taskAssigned => 'Назначен исполнитель',
    ActivityEventType.taskStatusChanged => 'Статус задачи изменён',
    ActivityEventType.taskCommentAdded => 'Добавлен комментарий',
    ActivityEventType.taskAttachmentAdded => 'Добавлено вложение',
    ActivityEventType.shoppingListCreated => 'Создан список покупок',
    ActivityEventType.shoppingItemAdded => 'Добавлена покупка',
    ActivityEventType.shoppingItemChecked => 'Покупка отмечена',
    ActivityEventType.memberJoined => 'Участник присоединился',
    ActivityEventType.memberRemoved => 'Участник удалён',
    ActivityEventType.familyUpdated => 'Семья обновлена',
  };

  String? get description =>
      payload['title'] as String? ?? payload['name'] as String?;
}
