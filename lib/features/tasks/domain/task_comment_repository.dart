import 'task_detail_models.dart';

abstract interface class TaskCommentRepository {
  Stream<List<TaskCommentModel>> watchComments(String taskId);
  Future<void> addComment({
    required String taskId,
    required String authorId,
    required String text,
  });
  Future<void> updateComment(String id, String text);
  Future<void> deleteComment(String id);
}
