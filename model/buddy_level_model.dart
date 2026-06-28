// lib/models/buddy_level_model.dart

class BuddyLevel {
  final int level;
  final String title;
  final String badge;       // emoji badge shown next to title
  final int minXp;
  final int maxXp;          // -1 means no cap (max level)
  final String description;

  const BuddyLevel({
    required this.level,
    required this.title,
    required this.badge,
    required this.minXp,
    required this.maxXp,
    required this.description,
  });

  /// Progress within this level (0.0 → 1.0)
  double progressAt(int currentXp) {
    if (maxXp == -1) return 1.0;
    final range = maxXp - minXp;
    if (range <= 0) return 1.0;
    return ((currentXp - minXp) / range).clamp(0.0, 1.0);
  }

  /// XP remaining to next level, or null at max level
  int? xpToNext(int currentXp) {
    if (maxXp == -1) return null;
    return (maxXp - currentXp).clamp(0, maxXp);
  }
}
// THE SIX LEVELS
const List<BuddyLevel> kBuddyLevels = [
  BuddyLevel(
    level: 1,
    title: 'Seedling',
    badge: '🌱',
    minXp: 0,
    maxXp: 99,
    description: 'Every great journey starts with a single step.',
  ),
  BuddyLevel(
    level: 2,
    title: 'Explorer',
    badge: '🌿',
    minXp: 100,
    maxXp: 299,
    description: 'Curiosity is the engine of achievement.',
  ),
  BuddyLevel(
    level: 3,
    title: 'Scholar',
    badge: '📚',
    minXp: 300,
    maxXp: 599,
    description: 'Knowledge is power — and you\'re gaining it.',
  ),
  BuddyLevel(
    level: 4,
    title: 'Achiever',
    badge: '⭐',
    minXp: 600,
    maxXp: 999,
    description: 'Consistency is what separates good from great.',
  ),
  BuddyLevel(
    level: 5,
    title: 'Champion',
    badge: '🏆',
    minXp: 1000,
    maxXp: 1499,
    description: 'Champions aren\'t made in comfort zones.',
  ),
  BuddyLevel(
    level: 6,
    title: 'Legend',
    badge: '🔥',
    minXp: 1500,
    maxXp: -1,
    description: 'You are an inspiration to others.',
  ),
];

/// Returns the BuddyLevel object for the given XP amount.
BuddyLevel buddyLevelFromXp(int xp) {
  for (int i = kBuddyLevels.length - 1; i >= 0; i--) {
    if (xp >= kBuddyLevels[i].minXp) return kBuddyLevels[i];
  }
  return kBuddyLevels.first;
}
