import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/models/family_model.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../household/presentation/family_providers.dart';
import '../domain/task_detail_models.dart';
import '../domain/task_models.dart';
import 'task_detail_providers.dart';
import 'task_providers.dart';

final class TaskDetailsScreen extends ConsumerStatefulWidget {
  const TaskDetailsScreen({required this.taskId, super.key});

  final String taskId;

  @override
  ConsumerState<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

final class _TaskDetailsScreenState extends ConsumerState<TaskDetailsScreen> {
  final _commentController = TextEditingController();
  bool _commentSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final user = ref.read(authSessionControllerProvider).user;
    if (user == null || _commentController.text.trim().isEmpty) return;
    setState(() => _commentSubmitting = true);
    try {
      await ref
          .read(taskCommentRepositoryProvider)
          .addComment(
            taskId: widget.taskId,
            authorId: user.id,
            text: _commentController.text,
          );
      _commentController.clear();
    } on Object catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _commentSubmitting = false);
    }
  }

  Future<void> _pickAttachment() async {
    final user = ref.read(authSessionControllerProvider).user;
    if (user == null) return;
    final file = await FilePicker.pickFile();
    if (file == null || file.path == null) return;
    try {
      await ref
          .read(attachmentRepositoryProvider)
          .enqueue(
            taskId: widget.taskId,
            uploadedById: user.id,
            localPath: file.path!,
            fileName: file.name,
            mimeType: _mimeType(file.extension),
            sizeBytes: await file.length(),
          );
    } on Object catch (error) {
      _showError(error);
    }
  }

  Future<void> _addReminder() async {
    var type = ReminderType.beforeDeadline;
    var remindAt = DateTime.now().add(const Duration(hours: 1));
    var offset = 60;
    final result = await showDialog<(ReminderType, DateTime?, int?)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Новое напоминание'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ReminderType>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Тип'),
                items: [
                  for (final value in ReminderType.values)
                    DropdownMenuItem(value: value, child: Text(value.label)),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => type = value);
                },
              ),
              const SizedBox(height: 12),
              if (type == ReminderType.beforeDeadline)
                DropdownButtonFormField<int>(
                  initialValue: offset,
                  decoration: const InputDecoration(labelText: 'За сколько'),
                  items: const [
                    DropdownMenuItem(value: 15, child: Text('15 минут')),
                    DropdownMenuItem(value: 60, child: Text('1 час')),
                    DropdownMenuItem(value: 1440, child: Text('1 день')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => offset = value);
                  },
                )
              else
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Дата и время'),
                  subtitle: Text(
                    DateFormat('dd.MM.yyyy, HH:mm').format(remindAt),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: remindAt,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (date == null || !context.mounted) return;
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(remindAt),
                    );
                    if (time != null) {
                      setDialogState(
                        () => remindAt = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        ),
                      );
                    }
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, (
                type,
                type == ReminderType.atTime ? remindAt : null,
                type == ReminderType.beforeDeadline ? offset : null,
              )),
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    try {
      await ref
          .read(taskReminderRepositoryProvider)
          .createReminder(
            taskId: widget.taskId,
            type: result.$1,
            remindAt: result.$2,
            offsetMinutes: result.$3,
          );
    } on Object catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$error')));
  }

  @override
  Widget build(BuildContext context) {
    final task = ref.watch(taskByIdProvider(widget.taskId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Задача'),
        actions: [
          IconButton(
            tooltip: 'Редактировать',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await context.push(AppRoutes.taskEdit(widget.taskId));
              ref.invalidate(taskByIdProvider(widget.taskId));
            },
          ),
        ],
      ),
      body: task.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Ошибка: $error')),
        data: (value) => value == null
            ? const Center(child: Text('Задача не найдена'))
            : _TaskDetailsBody(
                task: value,
                commentController: _commentController,
                commentSubmitting: _commentSubmitting,
                onAddComment: _addComment,
                onAddReminder: _addReminder,
                onPickAttachment: _pickAttachment,
              ),
      ),
    );
  }
}

final class _TaskDetailsBody extends ConsumerWidget {
  const _TaskDetailsBody({
    required this.task,
    required this.commentController,
    required this.commentSubmitting,
    required this.onAddComment,
    required this.onAddReminder,
    required this.onPickAttachment,
  });

  final TaskModel task;
  final TextEditingController commentController;
  final bool commentSubmitting;
  final VoidCallback onAddComment;
  final VoidCallback onAddReminder;
  final VoidCallback onPickAttachment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authSessionControllerProvider).user;
    final family = ref.watch(currentFamilyProvider).valueOrNull;
    final members = family == null
        ? const <FamilyMemberModel>[]
        : ref.watch(familyMembersProvider(family.id)).valueOrNull ?? const [];
    final assignee = members
        .where((member) => member.userId == task.assigneeId)
        .firstOrNull;
    final comments = ref.watch(taskCommentsProvider(task.id));
    final reminders = ref.watch(taskRemindersProvider(task.id));
    final attachments = ref.watch(taskAttachmentsProvider(task.id));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(task.title, style: Theme.of(context).textTheme.headlineSmall),
        if (task.description != null) ...[
          const SizedBox(height: 8),
          Text(task.description!),
        ],
        const SizedBox(height: 16),
        DropdownButtonFormField<TaskStatus>(
          initialValue: task.status,
          decoration: const InputDecoration(labelText: 'Статус'),
          items: [
            for (final status in TaskStatus.values.where(
              (status) => status != TaskStatus.unknown,
            ))
              DropdownMenuItem(value: status, child: Text(status.label)),
          ],
          onChanged: (status) async {
            if (status == null) return;
            await ref
                .read(taskActionsProvider.notifier)
                .updateStatus(task.id, status);
            ref.invalidate(taskByIdProvider(task.id));
          },
        ),
        const SizedBox(height: 10),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.person_outline),
          title: Text(assignee?.fullName ?? 'Без исполнителя'),
          subtitle: const Text('Ответственный'),
          trailing: task.assigneeId == null && user != null
              ? TextButton(
                  onPressed: () async {
                    await ref
                        .read(taskRepositoryProvider)
                        .assignToSelf(task.id, user.id);
                    ref.invalidate(taskByIdProvider(task.id));
                  },
                  child: const Text('Возьму'),
                )
              : null,
        ),
        if (task.deadline != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: Text(
              DateFormat('dd.MM.yyyy, HH:mm').format(task.deadline!.toLocal()),
            ),
            subtitle: const Text('Дедлайн'),
          ),
        if (task.category != null)
          Chip(
            avatar: const Icon(Icons.label_outline, size: 18),
            label: Text(task.category!),
          ),
        const Divider(height: 32),
        _SectionHeader(title: 'Напоминания', onAdd: onAddReminder),
        reminders.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text('Ошибка: $error'),
          data: (items) => Column(
            children: [
              for (final reminder in items)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: reminder.enabled,
                  title: Text(_reminderText(reminder)),
                  onChanged: (enabled) => ref
                      .read(taskReminderRepositoryProvider)
                      .setEnabled(reminder.id, enabled),
                ),
              if (items.isEmpty) const Text('Нет напоминаний'),
            ],
          ),
        ),
        const Divider(height: 32),
        _SectionHeader(title: 'Вложения', onAdd: onPickAttachment),
        attachments.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text('Ошибка: $error'),
          data: (items) => Column(
            children: [
              for (final attachment in items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.attach_file),
                  title: Text(attachment.fileName),
                  subtitle: Text(
                    '${attachment.uploadStatus.label} · ${_fileSize(attachment.sizeBytes)}',
                  ),
                  trailing:
                      attachment.uploadStatus == AttachmentUploadStatus.failed
                      ? IconButton(
                          tooltip: 'Повторить',
                          onPressed: () => ref
                              .read(attachmentRepositoryProvider)
                              .retry(attachment.id),
                          icon: const Icon(Icons.refresh),
                        )
                      : null,
                ),
              if (items.isEmpty) const Text('Нет вложений'),
            ],
          ),
        ),
        const Divider(height: 32),
        const _SectionHeader(title: 'Комментарии'),
        comments.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text('Ошибка: $error'),
          data: (items) => Column(
            children: [
              for (final comment in items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(
                    members
                            .where(
                              (member) => member.userId == comment.authorId,
                            )
                            .firstOrNull
                            ?.fullName ??
                        'Участник',
                  ),
                  subtitle: Text(comment.text),
                  trailing: Text(
                    DateFormat('dd.MM, HH:mm')
                        .format(comment.createdAt.toLocal()),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              if (items.isEmpty) const Text('Комментариев пока нет'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: commentController,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Комментарий'),
                onSubmitted: (_) => onAddComment(),
              ),
            ),
            IconButton.filled(
              tooltip: 'Отправить',
              onPressed: commentSubmitting ? null : onAddComment,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ],
    );
  }
}

final class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onAdd});

  final String title;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
      if (onAdd != null)
        IconButton(
          tooltip: 'Добавить',
          onPressed: onAdd,
          icon: const Icon(Icons.add),
        ),
    ],
  );
}

String _reminderText(TaskReminderModel reminder) {
  if (reminder.type == ReminderType.beforeDeadline) {
    final minutes = reminder.offsetMinutes ?? 0;
    if (minutes == 1440) return 'За 1 день до дедлайна';
    if (minutes == 60) return 'За 1 час до дедлайна';
    return 'За $minutes минут до дедлайна';
  }
  return reminder.remindAt == null
      ? 'В указанное время'
      : DateFormat('dd.MM.yyyy, HH:mm').format(reminder.remindAt!.toLocal());
}

String _mimeType(String? extension) => switch (extension?.toLowerCase()) {
  'jpg' || 'jpeg' => 'image/jpeg',
  'png' => 'image/png',
  'heic' => 'image/heic',
  'pdf' => 'application/pdf',
  _ => 'application/octet-stream',
};

String _fileSize(int bytes) {
  if (bytes < 1024) return '$bytes Б';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
  return '${(bytes / 1024 / 1024).toStringAsFixed(1)} МБ';
}
