import 'activity_models.dart';

abstract interface class ActivityRepository {
  Stream<List<ActivityEventModel>> watchEvents(String familyId);

  Future<void> record({
    required String familyId,
    required String? actorId,
    required ActivityEventType type,
    required ActivityEntityType entityType,
    required String entityId,
    Map<String, dynamic> payload = const {},
  });
}
