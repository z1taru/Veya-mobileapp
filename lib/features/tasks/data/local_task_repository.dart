import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/task_models.dart';
import '../domain/task_repository.dart';
import 'task_mapper.dart';

final class LocalTaskRepository implements TaskRepository {
  const LocalTaskRepository(this._database, this._uuid);

  final AppDatabase _database;
  final Uuid _uuid;

  @override
  Stream<List<TaskModel>> watchTasks({
    required String familyId,
    required String currentUserId,
    required TaskListFilter filter,
  }) => _database.watchTaskRows(familyId).map((rows) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return rows
        .map((row) => row.toModel())
        .where((task) => _matchesSection(task, filter.section, today, tomorrow))
        .where((task) => _matchesAssignee(task, filter.assignee, currentUserId))
        .toList(growable: false);
  });

  bool _matchesSection(
    TaskModel task,
    TaskSection section,
    DateTime today,
    DateTime tomorrow,
  ) {
    final deadline = task.deadline?.toLocal();
    return switch (section) {
      TaskSection.today =>
        deadline != null &&
            !deadline.isBefore(today) &&
            deadline.isBefore(tomorrow) &&
            task.status != TaskStatus.done &&
            task.status != TaskStatus.cancelled,
      TaskSection.upcoming =>
        deadline != null &&
            !deadline.isBefore(tomorrow) &&
            task.status != TaskStatus.done &&
            task.status != TaskStatus.cancelled,
      TaskSection.overdue =>
        deadline != null &&
            deadline.isBefore(today) &&
            task.status != TaskStatus.done &&
            task.status != TaskStatus.cancelled,
      TaskSection.completed => task.status == TaskStatus.done,
      TaskSection.all => true,
    };
  }

  bool _matchesAssignee(
    TaskModel task,
    AssigneeFilter filter,
    String currentUserId,
  ) => switch (filter.type) {
    AssigneeFilterType.all => true,
    AssigneeFilterType.me => task.assigneeId == currentUserId,
    AssigneeFilterType.member => task.assigneeId == filter.memberId,
    AssigneeFilterType.unassigned => task.assigneeId == null,
  };

  @override
  Future<TaskModel?> getTask(String id) async =>
      (await _database.getTaskRow(id))?.toModel();

  @override
  Future<TaskModel> createTask({
    required String familyId,
    required String createdById,
    required TaskDraft draft,
  }) async {
    _validate(draft);
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    await _database.upsertTask(
      taskCompanion(
        id: id,
        familyId: familyId,
        createdById: createdById,
        draft: draft,
        status: TaskStatus.open,
        createdAt: now,
        updatedAt: now,
      ),
    );
    return (await _database.getTaskRow(id))!.toModel();
  }

  @override
  Future<TaskModel> updateTask(String id, TaskDraft draft) async {
    _validate(draft);
    final existing = await _requiredTask(id);
    await _database.upsertTask(
      taskCompanion(
        id: id,
        familyId: existing.familyId,
        createdById: existing.createdById,
        draft: draft,
        status: existing.status,
        completedAt: existing.completedAt,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now().toUtc(),
        version: existing.version,
      ),
    );
    return (await _database.getTaskRow(id))!.toModel();
  }

  @override
  Future<void> updateStatus(String id, TaskStatus status) async {
    final completedAt = status == TaskStatus.done
        ? DateTime.now().toUtc()
        : null;
    await (_database.update(
      _database.taskRecords,
    )..where((row) => row.id.equals(id))).write(
      TaskRecordsCompanion(
        status: Value(status.wireName),
        completedAt: Value(completedAt),
        updatedAt: Value(DateTime.now().toUtc()),
        syncStatus: const Value('LOCAL'),
      ),
    );
  }

  @override
  Future<void> assignTask(String id, String? userId) =>
      (_database.update(
        _database.taskRecords,
      )..where((row) => row.id.equals(id))).write(
        TaskRecordsCompanion(
          assigneeId: Value(userId),
          updatedAt: Value(DateTime.now().toUtc()),
          syncStatus: const Value('LOCAL'),
        ),
      );

  @override
  Future<void> assignToSelf(String id, String currentUserId) =>
      assignTask(id, currentUserId);

  @override
  Future<void> deleteTask(String id) => _database.markTaskDeleted(id);

  Future<TaskModel> _requiredTask(String id) async {
    final task = await getTask(id);
    if (task == null) throw StateError('Задача не найдена');
    return task;
  }

  void _validate(TaskDraft draft) {
    final errors = draft.validate();
    if (errors.isNotEmpty) throw ArgumentError(errors.first);
  }
}
