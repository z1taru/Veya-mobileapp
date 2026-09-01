import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/task_detail_models.dart';
import '../domain/task_reminder_repository.dart';

final class LocalTaskReminderRepository implements TaskReminderRepository {
  const LocalTaskReminderRepository(this._database, this._uuid);

  final AppDatabase _database;
  final Uuid _uuid;

  @override
  Stream<List<TaskReminderModel>> watchReminders(String taskId) => _database
      .watchTaskReminders(taskId)
      .map(
        (rows) => rows
            .map(
              (row) => TaskReminderModel(
                id: row.id,
                taskId: row.taskId,
                type: ReminderType.fromWire(row.type),
                remindAt: row.remindAt,
                offsetMinutes: row.offsetMinutes,
                enabled: row.enabled,
                createdAt: row.createdAt,
                updatedAt: row.updatedAt,
                version: row.version,
              ),
            )
            .toList(growable: false),
      );

  @override
  Future<void> createReminder({
    required String taskId,
    required ReminderType type,
    DateTime? remindAt,
    int? offsetMinutes,
  }) async {
    if (type == ReminderType.atTime && remindAt == null) {
      throw ArgumentError('Укажите время напоминания');
    }
    if (type == ReminderType.beforeDeadline &&
        (offsetMinutes == null || offsetMinutes <= 0)) {
      throw ArgumentError('Укажите интервал до дедлайна');
    }
    final task = await _database.getTaskRow(taskId);
    if (task == null) throw StateError('Задача не найдена');
    if (type == ReminderType.beforeDeadline && task.deadline == null) {
      throw StateError('Сначала задайте дедлайн задачи');
    }
    final now = DateTime.now().toUtc();
    await _database
        .into(_database.taskReminderRecords)
        .insert(
          TaskReminderRecordsCompanion.insert(
            id: _uuid.v4(),
            taskId: taskId,
            type: type.wireName,
            remindAt: Value(remindAt?.toUtc()),
            offsetMinutes: Value(offsetMinutes),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  @override
  Future<void> setEnabled(String id, bool enabled) =>
      (_database.update(
        _database.taskReminderRecords,
      )..where((row) => row.id.equals(id))).write(
        TaskReminderRecordsCompanion(
          enabled: Value(enabled),
          updatedAt: Value(DateTime.now().toUtc()),
          syncStatus: const Value('LOCAL'),
        ),
      );

  @override
  Future<void> deleteReminder(String id) =>
      (_database.update(
        _database.taskReminderRecords,
      )..where((row) => row.id.equals(id))).write(
        TaskReminderRecordsCompanion(
          deletedAt: Value(DateTime.now().toUtc()),
          updatedAt: Value(DateTime.now().toUtc()),
          syncStatus: const Value('LOCAL'),
        ),
      );
}
