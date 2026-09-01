import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../activity/domain/activity_models.dart';
import '../../activity/domain/activity_repository.dart';
import '../domain/attachment_repository.dart';
import '../domain/task_detail_models.dart';

final class LocalAttachmentRepository implements AttachmentRepository {
  const LocalAttachmentRepository(
    this._database,
    this._uuid,
    this._activity,
    this._uploader, [
    this._fileStore,
  ]);

  final AppDatabase _database;
  final Uuid _uuid;
  final ActivityRepository _activity;
  final AttachmentUploader _uploader;
  final AttachmentFileStore? _fileStore;

  @override
  Stream<List<AttachmentModel>> watchAttachments(String taskId) => _database
      .watchTaskAttachments(taskId)
      .map((rows) => rows.map(_toModel).toList(growable: false));

  AttachmentModel _toModel(AttachmentRow row) => AttachmentModel(
    id: row.id,
    taskId: row.taskId,
    uploadedById: row.uploadedById,
    fileName: row.fileName,
    mimeType: row.mimeType,
    sizeBytes: row.sizeBytes,
    localPath: row.localPath,
    remoteUrl: row.remoteUrl,
    thumbnailUrl: row.thumbnailUrl,
    width: row.width,
    height: row.height,
    uploadStatus: AttachmentUploadStatus.fromWire(row.uploadStatus),
    uploadError: row.uploadError,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    version: row.version,
  );

  @override
  Future<void> enqueue({
    required String taskId,
    required String uploadedById,
    required String localPath,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
  }) async {
    final task = await _database.getTaskRow(taskId);
    if (task == null) throw StateError('Задача не найдена');
    final id = _uuid.v4();
    final now = DateTime.now().toUtc();
    final storedPath =
        await _fileStore?.persist(
          sourcePath: localPath,
          attachmentId: id,
          fileName: fileName,
        ) ??
        localPath;
    await _database
        .into(_database.attachmentRecords)
        .insert(
          AttachmentRecordsCompanion.insert(
            id: id,
            taskId: taskId,
            uploadedById: uploadedById,
            fileName: fileName,
            mimeType: mimeType,
            sizeBytes: sizeBytes,
            localPath: storedPath,
            uploadStatus: AttachmentUploadStatus.queued.wireName,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await _activity.record(
      familyId: task.familyId,
      actorId: uploadedById,
      type: ActivityEventType.taskAttachmentAdded,
      entityType: ActivityEntityType.task,
      entityId: taskId,
      payload: {'title': task.title, 'fileName': fileName},
    );
  }

  @override
  Future<void> retry(String id) =>
      (_database.update(
        _database.attachmentRecords,
      )..where((row) => row.id.equals(id))).write(
        AttachmentRecordsCompanion(
          uploadStatus: Value(AttachmentUploadStatus.queued.wireName),
          uploadError: const Value(null),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );

  @override
  Future<void> processQueue() async {
    final rows =
        await (_database.select(_database.attachmentRecords)..where(
              (row) =>
                  row.uploadStatus.equals(
                    AttachmentUploadStatus.queued.wireName,
                  ) &
                  row.deletedAt.isNull(),
            ))
            .get();
    for (final row in rows) {
      await (_database.update(
        _database.attachmentRecords,
      )..where((item) => item.id.equals(row.id))).write(
        AttachmentRecordsCompanion(
          uploadStatus: Value(AttachmentUploadStatus.uploading.wireName),
          uploadError: const Value(null),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );
      try {
        final url = await _uploader.upload(_toModel(row));
        await (_database.update(
          _database.attachmentRecords,
        )..where((item) => item.id.equals(row.id))).write(
          AttachmentRecordsCompanion(
            remoteUrl: Value(url),
            uploadStatus: Value(AttachmentUploadStatus.uploaded.wireName),
            uploadError: const Value(null),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
      } on Object catch (error) {
        await (_database.update(
          _database.attachmentRecords,
        )..where((item) => item.id.equals(row.id))).write(
          AttachmentRecordsCompanion(
            uploadStatus: Value(AttachmentUploadStatus.failed.wireName),
            uploadError: Value('$error'),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
      }
    }
  }

  @override
  Future<void> deleteAttachment(String id) async {
    final row = await (_database.select(
      _database.attachmentRecords,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    await (_database.update(
      _database.attachmentRecords,
    )..where((row) => row.id.equals(id))).write(
      AttachmentRecordsCompanion(
        deletedAt: Value(DateTime.now().toUtc()),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    if (row != null && _fileStore != null) {
      await _fileStore.delete(row.localPath);
    }
  }
}
