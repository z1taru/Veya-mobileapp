import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../activity/domain/activity_models.dart';
import '../../activity/domain/activity_repository.dart';
import '../domain/task_comment_repository.dart';
import '../domain/task_detail_models.dart';

final class LocalTaskCommentRepository implements TaskCommentRepository {
  const LocalTaskCommentRepository(this._database, this._uuid, this._activity);

  final AppDatabase _database;
  final Uuid _uuid;
  final ActivityRepository _activity;

  @override
  Stream<List<TaskCommentModel>> watchComments(String taskId) => _database
      .watchTaskComments(taskId)
      .map(
        (rows) => rows
            .map(
              (row) => TaskCommentModel(
                id: row.id,
                taskId: row.taskId,
                authorId: row.authorId,
                text: row.textContent,
                createdAt: row.createdAt,
                updatedAt: row.updatedAt,
                version: row.version,
              ),
            )
            .toList(growable: false),
      );

  @override
  Future<void> addComment({
    required String taskId,
    required String authorId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Комментарий не может быть пустым');
    }
    final task = await _database.getTaskRow(taskId);
    if (task == null) throw StateError('Задача не найдена');
    final id = _uuid.v4();
    final now = DateTime.now().toUtc();
    await _database
        .into(_database.taskCommentRecords)
        .insert(
          TaskCommentRecordsCompanion.insert(
            id: id,
            taskId: taskId,
            authorId: authorId,
            textContent: trimmed,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await _activity.record(
      familyId: task.familyId,
      actorId: authorId,
      type: ActivityEventType.taskCommentAdded,
      entityType: ActivityEntityType.taskComment,
      entityId: id,
      payload: {'taskId': taskId, 'title': task.title},
    );
  }

  @override
  Future<void> updateComment(String id, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Комментарий не может быть пустым');
    }
    return (_database.update(
      _database.taskCommentRecords,
    )..where((row) => row.id.equals(id))).write(
      TaskCommentRecordsCompanion(
        textContent: Value(trimmed),
        updatedAt: Value(DateTime.now().toUtc()),
        syncStatus: const Value('LOCAL'),
      ),
    );
  }

  @override
  Future<void> deleteComment(String id) =>
      (_database.update(
        _database.taskCommentRecords,
      )..where((row) => row.id.equals(id))).write(
        TaskCommentRecordsCompanion(
          deletedAt: Value(DateTime.now().toUtc()),
          updatedAt: Value(DateTime.now().toUtc()),
          syncStatus: const Value('LOCAL'),
        ),
      );
}
