import 'package:flutter_test/flutter_test.dart';
import 'package:veya/features/tasks/domain/task_models.dart';

void main() {
  final start = DateTime(2026, 9);

  group('RecurrenceRule validation', () {
    test('accepts every complete recurrence variant', () {
      final rules = [
        RecurrenceRule(
          type: RecurrenceType.daily,
          startsOn: start,
          timeZone: 'Asia/Almaty',
        ),
        RecurrenceRule(
          type: RecurrenceType.weekly,
          weekdays: const [1, 5],
          startsOn: start,
          timeZone: 'Asia/Almaty',
        ),
        RecurrenceRule(
          type: RecurrenceType.monthly,
          startsOn: start,
          timeZone: 'Asia/Almaty',
        ),
        RecurrenceRule(
          type: RecurrenceType.dayOfMonth,
          dayOfMonth: 15,
          startsOn: start,
          timeZone: 'Asia/Almaty',
        ),
        RecurrenceRule(
          type: RecurrenceType.intervalDays,
          interval: 3,
          startsOn: start,
          timeZone: 'Asia/Almaty',
        ),
      ];

      for (final rule in rules) {
        expect(rule.validate(), isEmpty);
      }
    });

    test('rejects missing type-specific values and invalid end date', () {
      final weekly = RecurrenceRule(
        type: RecurrenceType.weekly,
        startsOn: start,
        endsOn: start.subtract(const Duration(days: 1)),
        timeZone: 'UTC',
      );
      final dayOfMonth = RecurrenceRule(
        type: RecurrenceType.dayOfMonth,
        dayOfMonth: 32,
        startsOn: start,
        timeZone: 'UTC',
      );
      final interval = RecurrenceRule(
        type: RecurrenceType.intervalDays,
        interval: 1,
        startsOn: start,
        timeZone: 'UTC',
      );

      expect(weekly.validate(), hasLength(2));
      expect(dayOfMonth.validate(), isNotEmpty);
      expect(interval.validate(), isNotEmpty);
    });

    test('round-trips through target JSON shape', () {
      final original = RecurrenceRule(
        type: RecurrenceType.weekly,
        weekdays: const [2, 4],
        startsOn: DateTime(2026, 9, 1),
        endsOn: DateTime(2026, 12, 1),
        timeZone: 'Asia/Almaty',
      );

      final restored = RecurrenceRule.fromJson(original.toJson());

      expect(restored.type, original.type);
      expect(restored.weekdays, original.weekdays);
      expect(restored.startsOn, original.startsOn);
      expect(restored.endsOn, original.endsOn);
      expect(restored.timeZone, original.timeZone);
    });
  });
}
