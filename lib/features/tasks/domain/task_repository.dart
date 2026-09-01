import 'task_models.dart';

abstract interface class TaskRepository {
  Stream<List<TaskModel>> watchTasks({
    required String familyId,
    required String currentUserId,
    required TaskListFilter filter,
  });

  Future<TaskModel?> getTask(String id);

  Future<TaskModel> createTask({
    required String familyId,
    required String createdById,
    required TaskDraft draft,
  });

  Future<TaskModel> updateTask(String id, TaskDraft draft);
  Future<void> updateStatus(String id, TaskStatus status);
  Future<void> assignTask(String id, String? userId);
  Future<void> assignToSelf(String id, String currentUserId);
  Future<void> deleteTask(String id);
}
