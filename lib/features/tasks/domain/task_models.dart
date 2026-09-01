enum TaskStatus {
  open,
  inProgress,
  done,
  cancelled,
  unknown;

  String get wireName => switch (this) {
    TaskStatus.open => 'OPEN',
    TaskStatus.inProgress => 'IN_PROGRESS',
    TaskStatus.done => 'DONE',
    TaskStatus.cancelled => 'CANCELLED',
    TaskStatus.unknown => 'UNKNOWN',
  };

  String get label => switch (this) {
    TaskStatus.open => 'Открыта',
    TaskStatus.inProgress => 'В работе',
    TaskStatus.done => 'Выполнена',
    TaskStatus.cancelled => 'Отменена',
    TaskStatus.unknown => 'Неизвестно',
  };

  factory TaskStatus.fromWire(String value) => switch (value) {
    'OPEN' => TaskStatus.open,
    'IN_PROGRESS' => TaskStatus.inProgress,
    'DONE' => TaskStatus.done,
    'CANCELLED' => TaskStatus.cancelled,
    _ => TaskStatus.unknown,
  };
}

enum TaskPriority {
  low,
  medium,
  high;

  String get wireName => name.toUpperCase();

  String get label => switch (this) {
    TaskPriority.low => 'Низкий',
    TaskPriority.medium => 'Средний',
    TaskPriority.high => 'Высокий',
  };

  factory TaskPriority.fromWire(String value) => switch (value) {
    'LOW' => TaskPriority.low,
    'HIGH' => TaskPriority.high,
    _ => TaskPriority.medium,
  };
}

enum RecurrenceType {
  daily,
  weekly,
  monthly,
  dayOfMonth,
  intervalDays;

  String get wireName => switch (this) {
    RecurrenceType.daily => 'DAILY',
    RecurrenceType.weekly => 'WEEKLY',
    RecurrenceType.monthly => 'MONTHLY',
    RecurrenceType.dayOfMonth => 'DAY_OF_MONTH',
    RecurrenceType.intervalDays => 'INTERVAL_DAYS',
  };

  String get label => switch (this) {
    RecurrenceType.daily => 'Ежедневно',
    RecurrenceType.weekly => 'Еженедельно',
    RecurrenceType.monthly => 'Ежемесячно',
    RecurrenceType.dayOfMonth => 'По дню месяца',
    RecurrenceType.intervalDays => 'Каждые N дней',
  };

  factory RecurrenceType.fromWire(String value) => switch (value) {
    'DAILY' => RecurrenceType.daily,
    'WEEKLY' => RecurrenceType.weekly,
    'MONTHLY' => RecurrenceType.monthly,
    'DAY_OF_MONTH' => RecurrenceType.dayOfMonth,
    'INTERVAL_DAYS' => RecurrenceType.intervalDays,
    _ => RecurrenceType.daily,
  };
}

final class RecurrenceRule {
  const RecurrenceRule({
    required this.type,
    required this.startsOn,
    required this.timeZone,
    this.interval,
    this.weekdays = const [],
    this.dayOfMonth,
    this.endsOn,
  });

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) => RecurrenceRule(
    type: RecurrenceType.fromWire(json['type'] as String),
    interval: json['interval'] as int?,
    weekdays: (json['weekdays'] as List<dynamic>? ?? const []).cast<int>(),
    dayOfMonth: json['dayOfMonth'] as int?,
    startsOn: DateTime.parse(json['startsOn'] as String),
    endsOn: json['endsOn'] == null
        ? null
        : DateTime.parse(json['endsOn'] as String),
    timeZone: json['timeZone'] as String,
  );

  final RecurrenceType type;
  final int? interval;
  final List<int> weekdays;
  final int? dayOfMonth;
  final DateTime startsOn;
  final DateTime? endsOn;
  final String timeZone;

  List<String> validate() {
    final errors = <String>[];
    if (endsOn != null && _dateOnly(endsOn!).isBefore(_dateOnly(startsOn))) {
      errors.add('Дата окончания не может быть раньше даты начала');
    }
    if (type == RecurrenceType.weekly && weekdays.isEmpty) {
      errors.add('Выберите хотя бы один день недели');
    }
    if (weekdays.any((day) => day < 1 || day > 7)) {
      errors.add('День недели должен быть от 1 до 7');
    }
    if (type == RecurrenceType.dayOfMonth &&
        (dayOfMonth == null || dayOfMonth! < 1 || dayOfMonth! > 31)) {
      errors.add('День месяца должен быть от 1 до 31');
    }
    if (type == RecurrenceType.intervalDays &&
        (interval == null || interval! < 2)) {
      errors.add('Интервал должен быть не меньше двух дней');
    }
    return errors;
  }

  Map<String, dynamic> toJson() => {
    'type': type.wireName,
    if (interval != null) 'interval': interval,
    'weekdays': weekdays,
    if (dayOfMonth != null) 'dayOfMonth': dayOfMonth,
    'startsOn': _formatDate(startsOn),
    if (endsOn != null) 'endsOn': _formatDate(endsOn!),
    'timeZone': timeZone,
  };

  RecurrenceRule copyWith({
    RecurrenceType? type,
    Object? interval = _unset,
    List<int>? weekdays,
    Object? dayOfMonth = _unset,
    DateTime? startsOn,
    Object? endsOn = _unset,
    String? timeZone,
  }) => RecurrenceRule(
    type: type ?? this.type,
    interval: identical(interval, _unset) ? this.interval : interval as int?,
    weekdays: weekdays ?? this.weekdays,
    dayOfMonth: identical(dayOfMonth, _unset)
        ? this.dayOfMonth
        : dayOfMonth as int?,
    startsOn: startsOn ?? this.startsOn,
    endsOn: identical(endsOn, _unset) ? this.endsOn : endsOn as DateTime?,
    timeZone: timeZone ?? this.timeZone,
  );
}

final class TaskModel {
  const TaskModel({
    required this.id,
    required this.familyId,
    required this.title,
    required this.createdById,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    this.description,
    this.assigneeId,
    this.deadline,
    this.category,
    this.recurrenceRule,
    this.completedAt,
  });

  final String id;
  final String familyId;
  final String title;
  final String? description;
  final String createdById;
  final String? assigneeId;
  final TaskStatus status;
  final DateTime? deadline;
  final TaskPriority priority;
  final String? category;
  final RecurrenceRule? recurrenceRule;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
}

final class TaskDraft {
  const TaskDraft({
    this.title = '',
    this.description,
    this.assigneeId,
    this.deadline,
    this.priority = TaskPriority.medium,
    this.category,
    this.recurrenceRule,
  });

  factory TaskDraft.fromTask(TaskModel task) => TaskDraft(
    title: task.title,
    description: task.description,
    assigneeId: task.assigneeId,
    deadline: task.deadline,
    priority: task.priority,
    category: task.category,
    recurrenceRule: task.recurrenceRule,
  );

  final String title;
  final String? description;
  final String? assigneeId;
  final DateTime? deadline;
  final TaskPriority priority;
  final String? category;
  final RecurrenceRule? recurrenceRule;

  List<String> validate() {
    final errors = <String>[];
    if (title.trim().isEmpty) errors.add('Введите название задачи');
    if (title.trim().length > 255) {
      errors.add('Название не должно превышать 255 символов');
    }
    if (recurrenceRule case final rule?) errors.addAll(rule.validate());
    return errors;
  }

  TaskDraft copyWith({
    String? title,
    Object? description = _unset,
    Object? assigneeId = _unset,
    Object? deadline = _unset,
    TaskPriority? priority,
    Object? category = _unset,
    Object? recurrenceRule = _unset,
  }) => TaskDraft(
    title: title ?? this.title,
    description: identical(description, _unset)
        ? this.description
        : description as String?,
    assigneeId: identical(assigneeId, _unset)
        ? this.assigneeId
        : assigneeId as String?,
    deadline: identical(deadline, _unset)
        ? this.deadline
        : deadline as DateTime?,
    priority: priority ?? this.priority,
    category: identical(category, _unset) ? this.category : category as String?,
    recurrenceRule: identical(recurrenceRule, _unset)
        ? this.recurrenceRule
        : recurrenceRule as RecurrenceRule?,
  );
}

enum TaskSection { today, upcoming, overdue, all, completed }

enum AssigneeFilterType { all, me, member, unassigned }

final class AssigneeFilter {
  const AssigneeFilter(this.type, [this.memberId]);

  const AssigneeFilter.all() : this(AssigneeFilterType.all);
  const AssigneeFilter.me() : this(AssigneeFilterType.me);
  const AssigneeFilter.unassigned() : this(AssigneeFilterType.unassigned);
  const AssigneeFilter.member(String memberId)
    : this(AssigneeFilterType.member, memberId);

  final AssigneeFilterType type;
  final String? memberId;
}

final class TaskListFilter {
  const TaskListFilter({
    this.section = TaskSection.today,
    this.assignee = const AssigneeFilter.all(),
  });

  final TaskSection section;
  final AssigneeFilter assignee;

  TaskListFilter copyWith({TaskSection? section, AssigneeFilter? assignee}) =>
      TaskListFilter(
        section: section ?? this.section,
        assignee: assignee ?? this.assignee,
      );
}

const _unset = Object();

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _formatDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
