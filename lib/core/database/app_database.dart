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

@DriftDatabase(tables: [UserRecords, FamilyRecords, FamilyMemberRecords])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'veya'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      // Add explicit, sequential migrations as schemaVersion increases.
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

  Future<UserRow?> getLastUser() =>
      (select(userRecords)
            ..orderBy([(row) => OrderingTerm.desc(row.createdAt)])
            ..limit(1))
          .getSingleOrNull();

  Stream<UserRow?> watchUser(String id) => (select(
    userRecords,
  )..where((row) => row.id.equals(id))).watchSingleOrNull();
}
