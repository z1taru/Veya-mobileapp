enum ReminderType {
  atTime,
  beforeDeadline;

  String get wireName => switch (this) {
    atTime => 'AT_TIME',
    beforeDeadline => 'BEFORE_DEADLINE',
  };

  String get label => switch (this) {
    atTime => 'В указанное время',
    beforeDeadline => 'До дедлайна',
  };

  factory ReminderType.fromWire(String value) =>
      value == 'BEFORE_DEADLINE' ? beforeDeadline : atTime;
}

final class TaskCommentModel {
  const TaskCommentModel({
    required this.id,
    required this.taskId,
    required this.authorId,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  final String id;
  final String taskId;
  final String authorId;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
}

final class TaskReminderModel {
  const TaskReminderModel({
    required this.id,
    required this.taskId,
    required this.type,
    required this.enabled,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    this.remindAt,
    this.offsetMinutes,
  });

  final String id;
  final String taskId;
  final ReminderType type;
  final DateTime? remindAt;
  final int? offsetMinutes;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
}

enum AttachmentUploadStatus {
  queued,
  uploading,
  uploaded,
  failed;

  String get wireName => name.toUpperCase();

  String get label => switch (this) {
    queued => 'В очереди',
    uploading => 'Загружается',
    uploaded => 'Загружено',
    failed => 'Ошибка',
  };

  factory AttachmentUploadStatus.fromWire(String value) =>
      values.firstWhere((item) => item.wireName == value, orElse: () => queued);
}

final class AttachmentModel {
  const AttachmentModel({
    required this.id,
    required this.taskId,
    required this.uploadedById,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.localPath,
    required this.uploadStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    this.remoteUrl,
    this.thumbnailUrl,
    this.width,
    this.height,
    this.uploadError,
  });

  final String id;
  final String taskId;
  final String uploadedById;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final String localPath;
  final String? remoteUrl;
  final String? thumbnailUrl;
  final int? width;
  final int? height;
  final AttachmentUploadStatus uploadStatus;
  final String? uploadError;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
}
