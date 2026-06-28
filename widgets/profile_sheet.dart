import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/profile_provider.dart';
import '../screens/profile_screen.dart';
import '../screens/preferences_screen.dart';
import '../utils/app_router.dart';

void showProfileSheet(BuildContext context) {
  final profile = context.read<ProfileProvider>().profile;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1F2A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),

          // Study Buddy Avatar
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF252840)
                  : const Color(0xFFEEF2FF),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF334195).withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              profile.avatarEmoji,
              style: const TextStyle(fontSize: 46),
            ),
          ),
          const SizedBox(height: 14),

          // Name
          Text(
            profile.displayName.isNotEmpty
                ? profile.displayName
                : 'Scholar',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF2D3142),
            ),
          ),
          if (profile.university.isNotEmpty || profile.major.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              [
                if (profile.major.isNotEmpty) profile.major,
                if (profile.university.isNotEmpty) profile.university,
              ].join(' · '),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.black45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 28),

          // Menu items
          _buildSheetTile(
            context,
            icon: Icons.person_outline_rounded,
            iconBg: isDark ? const Color(0xFF1A2240) : Colors.blue.shade50,
            iconColor: Colors.blue,
            label: 'Edit Profile',
            isDark: isDark,
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                AppRouter.fade(const ProfileScreen()),
              );
            },
          ),
          _buildSheetTile(
            context,
            icon: Icons.tune_rounded,
            iconBg: isDark
                ? const Color(0xFF1F1540)
                : Colors.purple.shade50,
            iconColor: Colors.purple,
            label: 'App Preferences',
            isDark: isDark,
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                AppRouter.fade(const PreferencesScreen()),
              );
            },
          ),
          _buildSheetTile(
            context,
            icon: Icons.logout_rounded,
            iconBg: isDark ? const Color(0xFF2A1515) : Colors.red.shade50,
            iconColor: Colors.redAccent,
            label: 'Sign Out',
            labelColor: Colors.redAccent,
            isDark: isDark,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  backgroundColor: isDark ? const Color(0xFF1C1F2A) : Colors.white,
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx, true),
                      child: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                if (!context.mounted) return;
                Navigator.pop(ctx);
                await FirebaseAuth.instance.signOut();
              }
            },
          ),
        ],
      ),
    ),
  );
}

Widget _buildSheetTile(
  BuildContext context, {
  required IconData icon,
  required Color iconBg,
  required Color iconColor,
  required String label,
  required bool isDark,
  required VoidCallback onTap,
  Color? labelColor,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: labelColor ??
                      (isDark ? Colors.white : const Color(0xFF2D3142)),
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: isDark ? Colors.white24 : Colors.grey.shade400,
                size: 20),
          ],
        ),
      ),
    ),
  );
}
