import 'package:flutter_test/flutter_test.dart';
import 'package:verdant/data/models/models.dart';
import 'package:verdant/domain/rules.dart';

Habit _habit({HabitFrequency freq = const HabitFrequency.daily(), DateTime? archived}) => Habit(
      id: 'h1',
      templateId: 't',
      name: 'Read',
      description: '',
      category: 'Growth',
      iconKey: 'read',
      speciesId: 'monstera',
      potId: 'terracotta',
      frequency: freq,
      createdAt: DateTime(2026, 1, 1),
      archivedAt: archived,
    );

Completion _c(DateTime d) => Completion(id: '${d.millisecondsSinceEpoch}', habitId: 'h1', day: d, recordedAt: d);

void main() {
  const rules = CompletionRules();
  const growth = GrowthRules();
  final now = DateTime(2026, 10, 28, 18); // a Wednesday

  group('CompletionRules (stories 10 & 12)', () {
    test('accepts the first completion of the day', () {
      expect(rules.validate(habit: _habit(), day: now, existing: const [], now: now), CompletionStatus.accepted);
    });

    test('rejects a duplicate on the same day', () {
      final existing = [_c(DateTime(2026, 10, 28))];
      expect(rules.validate(habit: _habit(), day: now, existing: existing, now: now), CompletionStatus.duplicateToday);
    });

    test('caps weekly habits at their target', () {
      final h = _habit(freq: const HabitFrequency.weekly(2));
      final existing = [_c(DateTime(2026, 10, 26)), _c(DateTime(2026, 10, 27))];
      expect(rules.validate(habit: h, day: now, existing: existing, now: now), CompletionStatus.weeklyTargetReached);
    });

    test('weekly cap resets on Monday', () {
      final h = _habit(freq: const HabitFrequency.weekly(2));
      final existing = [_c(DateTime(2026, 10, 24)), _c(DateTime(2026, 10, 25))]; // previous Sat/Sun
      expect(rules.validate(habit: h, day: now, existing: existing, now: now), CompletionStatus.accepted);
    });

    test('rejects archived habits and future days', () {
      expect(rules.validate(habit: _habit(archived: now), day: now, existing: const [], now: now), CompletionStatus.habitInactive);
      expect(rules.validate(habit: _habit(), day: DateTime(2026, 10, 29), existing: const [], now: now), CompletionStatus.futureDate);
    });
  });

  group('GrowthRules (stories 11 & 15)', () {
    test('stage thresholds', () {
      expect(growth.stageFor(0), 0);
      expect(growth.stageFor(1), 1);
      expect(growth.stageFor(3), 2);
      expect(growth.stageFor(7), 3);
      expect(growth.stageFor(14), 4);
      expect(growth.stageFor(24), 5);
      expect(growth.stageFor(500), 5);
    });

    test('next threshold and progress', () {
      expect(growth.nextThreshold(5), 7);
      expect(growth.nextThreshold(30), isNull);
      expect(growth.stageProgress(5), closeTo(0.5, 1e-9));
    });
  });

  group('GardenStats', () {
    test('computes streaks', () {
      final cs = [for (var i = 1; i <= 5; i++) _c(DateTime(2026, 10, 28 - i))];
      final st = GardenStats.compute([_habit()], cs, now: now);
      expect(st.currentStreak, 5);
      expect(st.longestStreak, 5);
      expect(st.totalCompletions, 5);
    });
  });
}
