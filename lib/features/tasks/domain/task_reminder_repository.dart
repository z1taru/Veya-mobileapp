import 'task_detail_models.dart';

abstract interface class TaskReminderRepository {
  Stream<List<TaskReminderModel>> watchReminders(String taskId);
  Future<void> createReminder({
    required String taskId,
    required ReminderType type,
    DateTime? remindAt,
    int? offsetMinutes,
  });
  Future<void> setEnabled(String id, bool enabled);
  Future<void> deleteReminder(String id);
}
