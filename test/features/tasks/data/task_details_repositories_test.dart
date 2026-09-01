import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:veya/core/database/app_database.dart';
import 'package:veya/features/activity/data/local_activity_repository.dart';
import 'package:veya/features/activity/domain/activity_models.dart';
import 'package:veya/features/tasks/data/local_attachment_repository.dart';
import 'package:veya/features/tasks/data/local_task_comment_repository.dart';
import 'package:veya/features/tasks/data/local_task_reminder_repository.dart';
import 'package:veya/features/tasks/data/local_task_repository.dart';
import 'package:veya/features/tasks/domain/attachment_repository.dart';
import 'package:veya/features/tasks/domain/task_detail_models.dart';
import 'package:veya/features/tasks/domain/task_models.dart';

void main() {
  late AppDatabase database;
  late LocalActivityRepository activity;
  late LocalTaskRepository tasks;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    activity = LocalActivityRepository(database, const Uuid());
    tasks = LocalTaskRepository(database, const Uuid(), activity);
  });

  tearDown(() => database.close());

  test('task child repositories persist data and activity locally', () async {
    final task = await tasks.createTask(
      familyId: 'family-1',
      createdById: 'user-1',
      draft: TaskDraft(
        title: 'Семейная задача',
        deadline: DateTime.now().add(const Duration(days: 1)),
      ),
    );
    final comments = LocalTaskCommentRepository(
      database,
      const Uuid(),
      activity,
    );
    final reminders = LocalTaskReminderRepository(database, const Uuid());
    final attachments = LocalAttachmentRepository(
      database,
      const Uuid(),
      activity,
      const DeferredAttachmentUploader(),
    );

    await comments.addComment(
      taskId: task.id,
      authorId: 'user-1',
      text: '  Уже делаю  ',
    );
    await reminders.createReminder(
      taskId: task.id,
      type: ReminderType.beforeDeadline,
      offsetMinutes: 60,
    );
    await attachments.enqueue(
      taskId: task.id,
      uploadedById: 'user-1',
      localPath: '/tmp/photo.jpg',
      fileName: 'photo.jpg',
      mimeType: 'image/jpeg',
      sizeBytes: 2048,
    );

    expect(
      (await comments.watchComments(task.id).first).single.text,
      'Уже делаю',
    );
    expect(
      (await reminders.watchReminders(task.id).first).single.offsetMinutes,
      60,
    );
    final attachment =
        (await attachments.watchAttachments(task.id).first).single;
    expect(attachment.uploadStatus, AttachmentUploadStatus.queued);
    expect(attachment.localPath, '/tmp/photo.jpg');
    await attachments.processQueue();
    final failed = (await attachments.watchAttachments(task.id).first).single;
    expect(failed.uploadStatus, AttachmentUploadStatus.failed);
    expect(failed.uploadError, contains('not available'));

    final events = await activity.watchEvents('family-1').first;
    expect(
      events.map((event) => event.type),
      containsAll([
        ActivityEventType.taskCreated,
        ActivityEventType.taskCommentAdded,
        ActivityEventType.taskAttachmentAdded,
      ]),
    );
  });
}
