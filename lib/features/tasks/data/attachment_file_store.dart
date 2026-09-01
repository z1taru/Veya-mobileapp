import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/attachment_repository.dart';

final class AppAttachmentFileStore implements AttachmentFileStore {
  const AppAttachmentFileStore();

  @override
  Future<String> persist({
    required String sourcePath,
    required String attachmentId,
    required String fileName,
  }) async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory('${support.path}/attachments');
    await directory.create(recursive: true);
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final destination = '${directory.path}/$attachmentId-$safeName';
    await File(sourcePath).copy(destination);
    return destination;
  }

  @override
  Future<void> delete(String localPath) async {
    final file = File(localPath);
    if (await file.exists()) await file.delete();
  }
}
