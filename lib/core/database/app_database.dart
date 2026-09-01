import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

@DataClassName('UserRow')
class UserRecords extends Table {
  TextColumn get id => text()();
  TextColumn get fullName => text()();
  TextColumn get email => text()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('FamilyRow')
class FamilyRecords extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get ownerId => text()();
  TextColumn get timeZone => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('FamilyMemberRow')
class FamilyMemberRecords extends Table {
  TextColumn get id => text()();
  TextColumn get familyId => text()();
  TextColumn get userId => text()();
  TextColumn get fullName => text()();
  TextColumn get email => text()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get role => text()();
  DateTimeColumn get joinedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TaskRow')
class TaskRecords extends Table {
  TextColumn get id => text()();
  TextColumn get familyId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get createdById => text()();
  TextColumn get assigneeId => text().nullable()();
  TextColumn get status => text()();
  DateTimeColumn get deadline => dateTime().nullable()();
  TextColumn get priority => text()();
  TextColumn get category => text().nullable()();
  TextColumn get recurrenceRuleJson => text().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(0))();
  TextColumn get syncStatus => text().withDefault(const Constant('LOCAL'))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TaskCommentRow')
class TaskCommentRecords extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text()();
  TextColumn get authorId => text()();
  TextColumn get textContent => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(0))();
  TextColumn get syncStatus => text().withDefault(const Constant('LOCAL'))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TaskReminderRow')
class TaskReminderRecords extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text()();
  TextColumn get type => text()();
  DateTimeColumn get remindAt => dateTime().nullable()();
  IntColumn get offsetMinutes => integer().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(0))();
  TextColumn get syncStatus => text().withDefault(const Constant('LOCAL'))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('AttachmentRow')
class AttachmentRecords extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text()();
  TextColumn get uploadedById => text()();
  TextColumn get fileName => text()();
  TextColumn get mimeType => text()();
  IntColumn get sizeBytes => integer()();
  TextColumn get localPath => text()();
  TextColumn get remoteUrl => text().nullable()();
  TextColumn get thumbnailUrl => text().nullable()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  TextColumn get uploadStatus => text()();
  TextColumn get uploadError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(0))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ShoppingListRow')
class ShoppingListRecords extends Table {
  TextColumn get id => text()();
  TextColumn get familyId => text()();
  TextColumn get name => text()();
  TextColumn get createdById => text()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(0))();
  TextColumn get syncStatus => text().withDefault(const Constant('LOCAL'))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ShoppingItemRow')
class ShoppingItemRecords extends Table {
  TextColumn get id => text()();
  TextColumn get listId => text()();
  TextColumn get name => text()();
  RealColumn get quantity => real().nullable()();
  TextColumn get unit => text().nullable()();
  TextColumn get category => text().nullable()();
  BoolColumn get checked => boolean().withDefault(const Constant(false))();
  TextColumn get checkedById => text().nullable()();
  DateTimeColumn get checkedAt => dateTime().nullable()();
  IntColumn get position => integer()();
  TextColumn get createdById => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(0))();
  TextColumn get syncStatus => text().withDefault(const Constant('LOCAL'))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ActivityEventRow')
class ActivityEventRecords extends Table {
  TextColumn get id => text()();
  TextColumn get familyId => text()();
  TextColumn get actorId => text().nullable()();
  TextColumn get type => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    UserRecords,
    FamilyRecords,
    FamilyMemberRecords,
    TaskRecords,
    TaskCommentRecords,
    TaskReminderRecords,
    AttachmentRecords,
    ShoppingListRecords,
    ShoppingItemRecords,
    ActivityEventRecords,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'veya'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) await migrator.createTable(taskRecords);
      if (from < 3) {
        await migrator.createTable(taskCommentRecords);
        await migrator.createTable(taskReminderRecords);
        await migrator.createTable(attachmentRecords);
        await migrator.createTable(shoppingListRecords);
        await migrator.createTable(shoppingItemRecords);
        await migrator.createTable(activityEventRecords);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> upsertUser(UserRecordsCompanion user) =>
      into(userRecords).insertOnConflictUpdate(user);

  Future<void> upsertFamily(FamilyRecordsCompanion family) =>
      into(familyRecords).insertOnConflictUpdate(family);

  Future<void> upsertFamilyMember(FamilyMemberRecordsCompanion member) =>
      into(familyMemberRecords).insertOnConflictUpdate(member);

  Future<FamilyRow?> getCurrentFamily() =>
      (select(familyRecords)
            ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])
            ..limit(1))
          .getSingleOrNull();

  Stream<FamilyRow?> watchCurrentFamily() =>
      (select(familyRecords)
            ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])
            ..limit(1))
          .watchSingleOrNull();

  Stream<List<FamilyMemberRow>> watchFamilyMembers(String familyId) =>
      (select(familyMemberRecords)
            ..where((row) => row.familyId.equals(familyId))
            ..orderBy([(row) => OrderingTerm.asc(row.fullName)]))
          .watch();

  Future<void> replaceFamilyMembers(
    String familyId,
    List<FamilyMemberRecordsCompanion> members,
  ) => transaction(() async {
    await (delete(
      familyMemberRecords,
    )..where((row) => row.familyId.equals(familyId))).go();
    await batch((batch) => batch.insertAll(familyMemberRecords, members));
  });

  Stream<List<TaskRow>> watchTaskRows(String familyId) =>
      (select(taskRecords)
            ..where(
              (row) => row.familyId.equals(familyId) & row.deletedAt.isNull(),
            )
            ..orderBy([
              (row) => OrderingTerm.asc(row.deadline),
              (row) => OrderingTerm.desc(row.createdAt),
            ]))
          .watch();

  Future<TaskRow?> getTaskRow(String id) => (select(
    taskRecords,
  )..where((row) => row.id.equals(id))).getSingleOrNull();

  Future<void> upsertTask(TaskRecordsCompanion task) =>
      into(taskRecords).insertOnConflictUpdate(task);

  Future<void> markTaskDeleted(String id) =>
      (update(taskRecords)..where((row) => row.id.equals(id))).write(
        TaskRecordsCompanion(
          deletedAt: Value(DateTime.now().toUtc()),
          updatedAt: Value(DateTime.now().toUtc()),
          syncStatus: const Value('LOCAL'),
        ),
      );

  Future<UserRow?> getLastUser() =>
      (select(userRecords)
            ..orderBy([(row) => OrderingTerm.desc(row.createdAt)])
            ..limit(1))
          .getSingleOrNull();

  Stream<UserRow?> watchUser(String id) => (select(
    userRecords,
  )..where((row) => row.id.equals(id))).watchSingleOrNull();

  Stream<List<TaskCommentRow>> watchTaskComments(String taskId) =>
      (select(taskCommentRecords)
            ..where((row) => row.taskId.equals(taskId) & row.deletedAt.isNull())
            ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
          .watch();

  Stream<List<TaskReminderRow>> watchTaskReminders(String taskId) =>
      (select(taskReminderRecords)
            ..where((row) => row.taskId.equals(taskId) & row.deletedAt.isNull())
            ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
          .watch();

  Stream<List<AttachmentRow>> watchTaskAttachments(String taskId) =>
      (select(attachmentRecords)
            ..where((row) => row.taskId.equals(taskId) & row.deletedAt.isNull())
            ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
          .watch();

  Stream<List<ShoppingListRow>> watchShoppingLists(String familyId) =>
      (select(shoppingListRecords)
            ..where(
              (row) => row.familyId.equals(familyId) & row.deletedAt.isNull(),
            )
            ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]))
          .watch();

  Future<ShoppingListRow?> getShoppingList(String id) => (select(
    shoppingListRecords,
  )..where((row) => row.id.equals(id))).getSingleOrNull();

  Stream<List<ShoppingItemRow>> watchShoppingItems(String listId) =>
      (select(shoppingItemRecords)
            ..where((row) => row.listId.equals(listId) & row.deletedAt.isNull())
            ..orderBy([
              (row) => OrderingTerm.asc(row.checked),
              (row) => OrderingTerm.asc(row.position),
            ]))
          .watch();

  Stream<List<ActivityEventRow>> watchActivityEvents(String familyId) =>
      (select(activityEventRecords)
            ..where((row) => row.familyId.equals(familyId))
            ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
          .watch();
}
