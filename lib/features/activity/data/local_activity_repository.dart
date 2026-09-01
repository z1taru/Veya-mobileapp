import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/activity_models.dart';
import '../domain/activity_repository.dart';

final class LocalActivityRepository implements ActivityRepository {
  const LocalActivityRepository(this._database, this._uuid);

  final AppDatabase _database;
  final Uuid _uuid;

  @override
  Stream<List<ActivityEventModel>> watchEvents(String familyId) => _database
      .watchActivityEvents(familyId)
      .map(
        (rows) => rows
            .map(
              (row) => ActivityEventModel(
                id: row.id,
                familyId: row.familyId,
                actorId: row.actorId,
                type: ActivityEventType.fromWire(row.type),
                entityType: ActivityEntityType.fromWire(row.entityType),
                entityId: row.entityId,
                payload: jsonDecode(row.payloadJson) as Map<String, dynamic>,
                createdAt: row.createdAt,
              ),
            )
            .toList(growable: false),
      );

  @override
  Future<void> record({
    required String familyId,
    required String? actorId,
    required ActivityEventType type,
    required ActivityEntityType entityType,
    required String entityId,
    Map<String, dynamic> payload = const {},
  }) => _database
      .into(_database.activityEventRecords)
      .insert(
        ActivityEventRecordsCompanion.insert(
          id: _uuid.v4(),
          familyId: familyId,
          actorId: Value(actorId),
          type: type.wireName,
          entityType: entityType.wireName,
          entityId: entityId,
          payloadJson: jsonEncode(payload),
          createdAt: DateTime.now().toUtc(),
        ),
      );
}
