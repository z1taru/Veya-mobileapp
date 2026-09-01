import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:veya/core/database/app_database.dart';
import 'package:veya/features/tasks/data/local_task_repository.dart';
import 'package:veya/features/tasks/domain/task_models.dart';

void main() {
  late AppDatabase database;
  late LocalTaskRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = LocalTaskRepository(database, const Uuid());
  });

  tearDown(() => database.close());

  test('persists all task scalar fields and recurrence JSON', () async {
    final deadline = DateTime.now().add(const Duration(days: 2));
    final task = await repository.createTask(
      familyId: 'family-1',
      createdById: 'user-1',
      draft: TaskDraft(
        title: '  Купить продукты  ',
        description: 'Молоко и хлеб',
        assigneeId: 'user-2',
        deadline: deadline,
        priority: TaskPriority.high,
        category: 'Покупки',
        recurrenceRule: RecurrenceRule(
          type: RecurrenceType.intervalDays,
          interval: 3,
          startsOn: DateTime(2026, 9, 1),
          endsOn: DateTime(2026, 10, 1),
          timeZone: 'Asia/Almaty',
        ),
      ),
    );

    final restored = await repository.getTask(task.id);

    expect(restored?.title, 'Купить продукты');
    expect(restored?.description, 'Молоко и хлеб');
    expect(restored?.assigneeId, 'user-2');
    expect(
      restored?.deadline?.toUtc(),
      DateTime.fromMillisecondsSinceEpoch(
        deadline.toUtc().millisecondsSinceEpoch ~/ 1000 * 1000,
        isUtc: true,
      ),
    );
    expect(restored?.priority, TaskPriority.high);
    expect(restored?.category, 'Покупки');
    expect(restored?.recurrenceRule?.type, RecurrenceType.intervalDays);
    expect(restored?.recurrenceRule?.interval, 3);
    expect(restored?.recurrenceRule?.timeZone, 'Asia/Almaty');
    expect(restored?.status, TaskStatus.open);
    expect(restored?.version, 0);
  });

  test('soft-deleted task disappears from reactive lists', () async {
    final task = await repository.createTask(
      familyId: 'family-1',
      createdById: 'user-1',
      draft: const TaskDraft(title: 'Удалить меня'),
    );
    await repository.deleteTask(task.id);

    final tasks = await repository
        .watchTasks(
          familyId: 'family-1',
          currentUserId: 'user-1',
          filter: const TaskListFilter(section: TaskSection.all),
        )
        .first;

    expect(tasks, isEmpty);
    expect((await database.getTaskRow(task.id))?.deletedAt, isNotNull);
  });
}
