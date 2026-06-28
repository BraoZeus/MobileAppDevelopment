
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../models/buddy_level_model.dart';

class GamificationScreen extends StatelessWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final profile = profileProvider.profile;
    final buddy = profile.buddyLevel;
    final xp = profile.xp;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : const Color(0xFF2D3142)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Study Buddy',
            style: TextStyle(
                color: isDark ? const Color(0xFF8FA8F8) : const Color(0xFF2D3142),
                fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF111318), Color(0xFF1A1D2E), Color(0xFF111827)]
                : const [Color(0xFFE8F0FA), Color(0xFFF3E8FA), Color(0xFFE0F7FA)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF252840) : const Color(0xFFEEF2FF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF334195).withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(profile.avatarEmoji, style: const TextStyle(fontSize: 60)),
                ),
                const SizedBox(height: 20),
                
                // Title and Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(buddy.badge, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 8),
                    Text(
                      buddy.title,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF2D3142),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF334195).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Level ${buddy.level}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334195),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Progress Bar
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: buddy.progressAt(xp),
                          minHeight: 12,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF334195)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$xp XP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF2D3142),
                              )),
                          Text(
                            buddy.xpToNext(xp) != null
                                ? '${buddy.xpToNext(xp)} XP to go'
                                : '🔥 Max Level!',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Levels List
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Buddy Levels',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF2D3142))),
                ),
                const SizedBox(height: 16),
                
                ...kBuddyLevels.map((lvl) {
                  final isCurrent = lvl.level == buddy.level;
                  final isUnlocked = xp >= lvl.minXp;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0xFF334195).withValues(alpha: 0.15)
                          : (isUnlocked
                              ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.6))
                              : (isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03))),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isCurrent
                            ? const Color(0xFF334195).withValues(alpha: 0.5)
                            : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.transparent),
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isUnlocked
                                ? (isDark ? const Color(0xFF252840) : Colors.white)
                                : (isDark ? Colors.black12 : Colors.black.withValues(alpha: 0.05)),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Opacity(
                            opacity: isUnlocked ? 1.0 : 0.5,
                            child: Text(
                              isUnlocked ? lvl.badge : '🔒',
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    lvl.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isUnlocked
                                          ? (isDark ? Colors.white : const Color(0xFF2D3142))
                                          : (isDark ? Colors.white38 : Colors.black38),
                                    ),
                                  ),
                                  if (isCurrent) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF334195),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('CURRENT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                lvl.description,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isUnlocked
                                      ? (isDark ? Colors.white70 : Colors.black54)
                                      : (isDark ? Colors.white24 : Colors.black26),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${lvl.minXp} XP',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isUnlocked
                                ? (isDark ? const Color(0xFF8FA8F8) : const Color(0xFF334195))
                                : (isDark ? Colors.white24 : Colors.black26),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
