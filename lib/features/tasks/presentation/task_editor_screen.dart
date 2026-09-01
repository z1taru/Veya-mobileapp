import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/family_model.dart';
import '../../household/presentation/family_providers.dart';
import '../domain/task_models.dart';
import 'task_providers.dart';

final class TaskEditorScreen extends ConsumerWidget {
  const TaskEditorScreen({super.key, this.taskId});

  final String? taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(taskEditorProvider(taskId));
    final controller = ref.read(taskEditorProvider(taskId).notifier);
    final family = ref.watch(currentFamilyProvider).valueOrNull;
    final members = family == null
        ? const AsyncValue<List<FamilyMemberModel>>.data([])
        : ref.watch(familyMembersProvider(family.id));

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Задача')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final draft = state.draft;
    return Scaffold(
      appBar: AppBar(
        title: Text(taskId == null ? 'Новая задача' : 'Редактировать задачу'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          TextFormField(
            initialValue: draft.title,
            autofocus: taskId == null,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Название *'),
            onChanged: (value) =>
                controller.change((draft) => draft.copyWith(title: value)),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: draft.description,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Описание'),
            onChanged: (value) => controller.change(
              (draft) => draft.copyWith(description: value),
            ),
          ),
          const SizedBox(height: 12),
          members.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const Text('Исполнители временно недоступны'),
            data: (items) => DropdownButtonFormField<String?>(
              initialValue: draft.assigneeId,
              decoration: const InputDecoration(labelText: 'Ответственный'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Не назначен')),
                for (final member in items)
                  DropdownMenuItem(
                    value: member.userId,
                    child: Text(member.fullName),
                  ),
              ],
              onChanged: (value) => controller.change(
                (draft) => draft.copyWith(assigneeId: value),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _DeadlineField(
            value: draft.deadline,
            onChanged: (value) =>
                controller.change((draft) => draft.copyWith(deadline: value)),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TaskPriority>(
            initialValue: draft.priority,
            decoration: const InputDecoration(labelText: 'Приоритет'),
            items: [
              for (final priority in TaskPriority.values)
                DropdownMenuItem(value: priority, child: Text(priority.label)),
            ],
            onChanged: (value) {
              if (value != null) {
                controller.change((draft) => draft.copyWith(priority: value));
              }
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: draft.category,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Категория'),
            onChanged: (value) =>
                controller.change((draft) => draft.copyWith(category: value)),
          ),
          const SizedBox(height: 20),
          _RecurrenceEditor(
            rule: draft.recurrenceRule,
            timeZone: family?.timeZone ?? 'UTC',
            onChanged: (value) => controller.change(
              (draft) => draft.copyWith(recurrenceRule: value),
            ),
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              state.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: state.isSaving
                ? null
                : () async {
                    final saved = await controller.save();
                    if (saved && context.mounted) Navigator.of(context).pop();
                  },
            child: state.isSaving
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}

final class _DeadlineField extends StatelessWidget {
  const _DeadlineField({required this.value, required this.onChanged});

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  Future<void> _pick(BuildContext context) async {
    final initial =
        value?.toLocal() ?? DateTime.now().add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    onChanged(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: const InputDecoration(labelText: 'Дедлайн'),
    child: Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _pick(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                value == null
                    ? 'Без дедлайна'
                    : DateFormat('dd.MM.yyyy, HH:mm').format(value!.toLocal()),
              ),
            ),
          ),
        ),
        if (value != null)
          IconButton(
            tooltip: 'Убрать дедлайн',
            onPressed: () => onChanged(null),
            icon: const Icon(Icons.close),
          ),
      ],
    ),
  );
}

final class _RecurrenceEditor extends StatelessWidget {
  const _RecurrenceEditor({
    required this.rule,
    required this.timeZone,
    required this.onChanged,
  });

  final RecurrenceRule? rule;
  final String timeZone;
  final ValueChanged<RecurrenceRule?> onChanged;

  RecurrenceRule _newRule(RecurrenceType type) {
    final today = DateTime.now();
    return RecurrenceRule(
      type: type,
      startsOn: DateTime(today.year, today.month, today.day),
      timeZone: timeZone,
      weekdays: type == RecurrenceType.weekly ? [today.weekday] : const [],
      dayOfMonth: type == RecurrenceType.dayOfMonth ? today.day : null,
      interval: type == RecurrenceType.intervalDays ? 2 : null,
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Повторение', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      DropdownButtonFormField<RecurrenceType?>(
        initialValue: rule?.type,
        decoration: const InputDecoration(labelText: 'Периодичность'),
        items: [
          const DropdownMenuItem(value: null, child: Text('Не повторять')),
          for (final type in RecurrenceType.values)
            DropdownMenuItem(value: type, child: Text(type.label)),
        ],
        onChanged: (type) => onChanged(type == null ? null : _newRule(type)),
      ),
      if (rule case final current?) ...[
        const SizedBox(height: 12),
        if (current.type == RecurrenceType.weekly)
          _WeekdaysField(
            selected: current.weekdays,
            onChanged: (days) => onChanged(current.copyWith(weekdays: days)),
          ),
        if (current.type == RecurrenceType.dayOfMonth)
          _NumberField(
            label: 'День месяца (1–31)',
            value: current.dayOfMonth ?? 1,
            onChanged: (value) =>
                onChanged(current.copyWith(dayOfMonth: value)),
          ),
        if (current.type == RecurrenceType.intervalDays)
          _NumberField(
            label: 'Интервал в днях (от 2)',
            value: current.interval ?? 2,
            onChanged: (value) => onChanged(current.copyWith(interval: value)),
          ),
        _DateField(
          label: 'Дата начала',
          value: current.startsOn,
          onChanged: (value) => onChanged(current.copyWith(startsOn: value)),
        ),
        _OptionalEndDateField(
          value: current.endsOn,
          firstDate: current.startsOn,
          onChanged: (value) => onChanged(current.copyWith(endsOn: value)),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('Часовой пояс: ${current.timeZone}'),
        ),
      ],
    ],
  );
}

final class _WeekdaysField extends StatelessWidget {
  const _WeekdaysField({required this.selected, required this.onChanged});

  static const labels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  final List<int> selected;
  final ValueChanged<List<int>> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Wrap(
      spacing: 6,
      children: [
        for (var day = 1; day <= 7; day++)
          FilterChip(
            label: Text(labels[day - 1]),
            selected: selected.contains(day),
            onSelected: (enabled) {
              final next = [...selected];
              enabled ? next.add(day) : next.remove(day);
              next.sort();
              onChanged(next);
            },
          ),
      ],
    ),
  );
}

final class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      key: ValueKey('$label:$value'),
      initialValue: '$value',
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      onChanged: (text) {
        final parsed = int.tryParse(text);
        if (parsed != null) onChanged(parsed);
      },
    ),
  );
}

final class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(DateFormat('dd.MM.yyyy').format(value)),
    trailing: const Icon(Icons.calendar_today_outlined),
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: value,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 3650)),
      );
      if (picked != null) onChanged(picked);
    },
  );
}

final class _OptionalEndDateField extends StatelessWidget {
  const _OptionalEndDateField({
    required this.value,
    required this.firstDate,
    required this.onChanged,
  });

  final DateTime? value;
  final DateTime firstDate;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: const Text('Дата окончания'),
    subtitle: Text(
      value == null
          ? 'Без ограничения'
          : DateFormat('dd.MM.yyyy').format(value!),
    ),
    trailing: value == null
        ? const Icon(Icons.calendar_today_outlined)
        : IconButton(
            tooltip: 'Убрать дату',
            onPressed: () => onChanged(null),
            icon: const Icon(Icons.close),
          ),
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: value ?? firstDate,
        firstDate: firstDate,
        lastDate: DateTime.now().add(const Duration(days: 3650)),
      );
      if (picked != null) onChanged(picked);
    },
  );
}
