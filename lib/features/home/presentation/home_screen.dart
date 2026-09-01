import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/models/family_model.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../household/presentation/family_providers.dart';
import '../../tasks/domain/task_models.dart';
import '../../tasks/presentation/task_providers.dart';

final class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _sections = <(TaskSection, String)>[
    (TaskSection.today, 'Сегодня'),
    (TaskSection.upcoming, 'Предстоящие'),
    (TaskSection.overdue, 'Просрочено'),
    (TaskSection.all, 'Все'),
    (TaskSection.completed, 'Выполнено'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(taskListFilterProvider);
    final family = ref.watch(currentFamilyProvider).valueOrNull;
    final members = family == null
        ? const AsyncValue<List<FamilyMemberModel>>.data([])
        : ref.watch(familyMembersProvider(family.id));
    final tasks = ref.watch(visibleTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _sections.firstWhere((item) => item.$1 == filter.section).$2,
        ),
        actions: [
          IconButton(
            tooltip: 'Покупки',
            onPressed: () => context.push(AppRoutes.shopping),
            icon: const Icon(Icons.shopping_basket_outlined),
          ),
          IconButton(
            tooltip: 'Активность',
            onPressed: () => context.push(AppRoutes.activity),
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: 'Семья',
            onPressed: () => context.push(AppRoutes.family),
            icon: const Icon(Icons.group_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: 'Меню',
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authSessionControllerProvider.notifier).logout();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'logout', child: Text('Выйти')),
            ],
          ),
        ],
      ),
      floatingActionButton: family == null
          ? null
          : FloatingActionButton(
              tooltip: 'Создать задачу',
              onPressed: () => context.push(AppRoutes.taskNew),
              child: const Icon(Icons.add),
            ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              scrollDirection: Axis.horizontal,
              itemCount: _sections.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final item = _sections[index];
                return ChoiceChip(
                  label: Text(item.$2),
                  selected: filter.section == item.$1,
                  onSelected: (_) =>
                      ref.read(taskListFilterProvider.notifier).state = filter
                          .copyWith(section: item.$1),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: members.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const SizedBox.shrink(),
              data: (items) => _AssigneeFilterField(
                value: filter.assignee,
                members: items,
                onChanged: (assignee) =>
                    ref.read(taskListFilterProvider.notifier).state = filter
                        .copyWith(assignee: assignee),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: ref.read(householdControllerProvider.notifier).refresh,
              child: tasks.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _TaskListMessage(
                  icon: Icons.cloud_off_outlined,
                  text: 'Не удалось открыть задачи\n$error',
                ),
                data: (items) => items.isEmpty
                    ? _TaskListMessage(
                        icon: family == null
                            ? Icons.group_add_outlined
                            : Icons.task_alt,
                        text: family == null
                            ? 'Обновите данные семьи, чтобы создавать задачи'
                            : 'В этом разделе пока нет задач',
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, index) => _TaskCard(
                          task: items[index],
                          members: members.valueOrNull ?? const [],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _AssigneeFilterField extends StatelessWidget {
  const _AssigneeFilterField({
    required this.value,
    required this.members,
    required this.onChanged,
  });

  final AssigneeFilter value;
  final List<FamilyMemberModel> members;
  final ValueChanged<AssigneeFilter> onChanged;

  String get _wireValue => switch (value.type) {
    AssigneeFilterType.all => 'all',
    AssigneeFilterType.me => 'me',
    AssigneeFilterType.unassigned => 'unassigned',
    AssigneeFilterType.member => 'member:${value.memberId}',
  };

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: _wireValue,
    isDense: true,
    decoration: const InputDecoration(
      labelText: 'Исполнитель',
      prefixIcon: Icon(Icons.person_outline),
    ),
    items: [
      const DropdownMenuItem(value: 'all', child: Text('Все')),
      const DropdownMenuItem(value: 'me', child: Text('Мои')),
      const DropdownMenuItem(
        value: 'unassigned',
        child: Text('Без исполнителя'),
      ),
      for (final member in members)
        DropdownMenuItem(
          value: 'member:${member.userId}',
          child: Text(member.fullName),
        ),
    ],
    onChanged: (wire) {
      if (wire == null) return;
      onChanged(switch (wire) {
        'me' => const AssigneeFilter.me(),
        'unassigned' => const AssigneeFilter.unassigned(),
        final member when member.startsWith('member:') => AssigneeFilter.member(
          member.substring(7),
        ),
        _ => const AssigneeFilter.all(),
      });
    },
  );
}

final class _TaskCard extends ConsumerWidget {
  const _TaskCard({required this.task, required this.members});

  final TaskModel task;
  final List<FamilyMemberModel> members;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignee = members
        .where((member) => member.userId == task.assigneeId)
        .firstOrNull;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.task(task.id)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Checkbox(
              value: task.status == TaskStatus.done,
              onChanged: (_) => ref
                  .read(taskActionsProvider.notifier)
                  .updateStatus(
                    task.id,
                    task.status == TaskStatus.done
                        ? TaskStatus.open
                        : TaskStatus.done,
                  ),
            ),
            title: Text(
              task.title,
              style: task.status == TaskStatus.done
                  ? const TextStyle(decoration: TextDecoration.lineThrough)
                  : null,
            ),
            subtitle: Wrap(
              spacing: 10,
              runSpacing: 2,
              children: [
                if (task.deadline != null)
                  Text(
                    DateFormat('dd.MM, HH:mm').format(task.deadline!.toLocal()),
                  ),
                Text(assignee?.fullName ?? 'Без исполнителя'),
                if (task.category != null) Text(task.category!),
              ],
            ),
            trailing: Icon(
              switch (task.priority) {
                TaskPriority.high => Icons.priority_high,
                TaskPriority.medium => Icons.drag_handle,
                TaskPriority.low => Icons.arrow_downward,
              },
              color: switch (task.priority) {
                TaskPriority.high => Theme.of(context).colorScheme.error,
                TaskPriority.medium => Theme.of(context).colorScheme.primary,
                TaskPriority.low => Theme.of(context).colorScheme.outline,
              },
            ),
          ),
        ),
      ),
    );
  }
}

final class _TaskListMessage extends StatelessWidget {
  const _TaskListMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      SizedBox(
        height: MediaQuery.sizeOf(context).height * .55,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(text, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    ],
  );
}
