import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/task_models.dart';

extension TaskRowMapper on TaskRow {
  TaskModel toModel() => TaskModel(
    id: id,
    familyId: familyId,
    title: title,
    description: description,
    createdById: createdById,
    assigneeId: assigneeId,
    status: TaskStatus.fromWire(status),
    deadline: deadline,
    priority: TaskPriority.fromWire(priority),
    category: category,
    recurrenceRule: recurrenceRuleJson == null
        ? null
        : RecurrenceRule.fromJson(
            jsonDecode(recurrenceRuleJson!) as Map<String, dynamic>,
          ),
    completedAt: completedAt,
    createdAt: createdAt,
    updatedAt: updatedAt,
    version: version,
  );
}

TaskRecordsCompanion taskCompanion({
  required String id,
  required String familyId,
  required String createdById,
  required TaskDraft draft,
  required TaskStatus status,
  required DateTime createdAt,
  required DateTime updatedAt,
  DateTime? completedAt,
  int version = 0,
}) => TaskRecordsCompanion.insert(
  id: id,
  familyId: familyId,
  title: draft.title.trim(),
  description: Value(_emptyToNull(draft.description)),
  createdById: createdById,
  assigneeId: Value(draft.assigneeId),
  status: status.wireName,
  deadline: Value(draft.deadline?.toUtc()),
  priority: draft.priority.wireName,
  category: Value(_emptyToNull(draft.category)),
  recurrenceRuleJson: Value(
    draft.recurrenceRule == null
        ? null
        : jsonEncode(draft.recurrenceRule!.toJson()),
  ),
  completedAt: Value(completedAt),
  createdAt: createdAt,
  updatedAt: updatedAt,
  version: Value(version),
  syncStatus: const Value('LOCAL'),
);

String? _emptyToNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
