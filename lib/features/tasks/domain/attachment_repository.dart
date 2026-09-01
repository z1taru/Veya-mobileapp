import 'task_detail_models.dart';

abstract interface class AttachmentRepository {
  Stream<List<AttachmentModel>> watchAttachments(String taskId);
  Future<void> enqueue({
    required String taskId,
    required String uploadedById,
    required String localPath,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
  });
  Future<void> retry(String id);
  Future<void> processQueue();
  Future<void> deleteAttachment(String id);
}

abstract interface class AttachmentUploader {
  Future<String> upload(AttachmentModel attachment);
}

abstract interface class AttachmentFileStore {
  Future<String> persist({
    required String sourcePath,
    required String attachmentId,
    required String fileName,
  });
  Future<void> delete(String localPath);
}

final class DeferredAttachmentUploader implements AttachmentUploader {
  const DeferredAttachmentUploader();

  @override
  Future<String> upload(AttachmentModel attachment) {
    throw UnsupportedError('Backend attachment endpoint is not available yet');
  }
}
