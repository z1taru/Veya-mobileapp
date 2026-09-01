import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/id_provider.dart';
import '../../activity/presentation/activity_providers.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/local_attachment_repository.dart';
import '../data/attachment_file_store.dart';
import '../data/local_task_comment_repository.dart';
import '../data/local_task_reminder_repository.dart';
import '../domain/attachment_repository.dart';
import '../domain/task_comment_repository.dart';
import '../domain/task_detail_models.dart';
import '../domain/task_reminder_repository.dart';

final taskCommentRepositoryProvider = Provider<TaskCommentRepository>((ref) {
  return LocalTaskCommentRepository(
    ref.watch(databaseProvider),
    ref.watch(uuidProvider),
    ref.watch(activityRepositoryProvider),
  );
});

final taskReminderRepositoryProvider = Provider<TaskReminderRepository>((ref) {
  return LocalTaskReminderRepository(
    ref.watch(databaseProvider),
    ref.watch(uuidProvider),
  );
});

final attachmentRepositoryProvider = Provider<AttachmentRepository>((ref) {
  return LocalAttachmentRepository(
    ref.watch(databaseProvider),
    ref.watch(uuidProvider),
    ref.watch(activityRepositoryProvider),
    const DeferredAttachmentUploader(),
    const AppAttachmentFileStore(),
  );
});

final taskCommentsProvider = StreamProvider.autoDispose
    .family<List<TaskCommentModel>, String>((ref, taskId) {
      return ref.watch(taskCommentRepositoryProvider).watchComments(taskId);
    });

final taskRemindersProvider = StreamProvider.autoDispose
    .family<List<TaskReminderModel>, String>((ref, taskId) {
      return ref.watch(taskReminderRepositoryProvider).watchReminders(taskId);
    });

final taskAttachmentsProvider = StreamProvider.autoDispose
    .family<List<AttachmentModel>, String>((ref, taskId) {
      return ref.watch(attachmentRepositoryProvider).watchAttachments(taskId);
    });
