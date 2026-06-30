import 'package:flutter_test/flutter_test.dart';
import 'package:study_well/models/buddy_level_model.dart';

void main() {
  group('BuddyLevel Logic', () {
    test('progressAt returns correct value', () {
      final level = BuddyLevel(
        level: 1,
        title: 'Test',
        badge: 'T',
        minXp: 0,
        maxXp: 100,
        description: 'Test desc',
      );

      expect(level.progressAt(0), 0.0);
      expect(level.progressAt(50), 0.5);
      expect(level.progressAt(100), 1.0);
      expect(level.progressAt(150), 1.0); // should clamp
    });

    test('xpToNext returns correct amount', () {
      final level = BuddyLevel(
        level: 1,
        title: 'Test',
        badge: 'T',
        minXp: 0,
        maxXp: 100,
        description: 'Test desc',
      );

      expect(level.xpToNext(0), 100);
      expect(level.xpToNext(50), 50);
      expect(level.xpToNext(100), 0);
      expect(level.xpToNext(150), 0); // should clamp
    });

    test('buddyLevelFromXp returns correct tier', () {
      expect(buddyLevelFromXp(0).level, 1);
      expect(buddyLevelFromXp(99).level, 1);
      expect(buddyLevelFromXp(100).level, 2);
      expect(buddyLevelFromXp(1000).level, 5);
      expect(buddyLevelFromXp(2000).level, 6);
    });
    
    test('max level handles progress and xpToNext gracefully', () {
      final maxLevel = kBuddyLevels.last; // Legend, maxXp = -1
      expect(maxLevel.maxXp, -1);
      expect(maxLevel.progressAt(2000), 1.0);
      expect(maxLevel.xpToNext(2000), isNull);
    });
  });
}
