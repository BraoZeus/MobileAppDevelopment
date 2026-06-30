import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: theme.appBarTheme.iconTheme?.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('App Preferences',
            style: theme.appBarTheme.titleTextStyle),
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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
// APPEARANCE SECTION
                _SectionHeader(title: 'Appearance', icon: Icons.palette_outlined),
                const SizedBox(height: 12),
                _GlassCard(
                  isDark: isDark,
                  child: Column(
                    children: [
                      _ThemeTile(
                        label: 'Light Mode',
                        icon: Icons.light_mode_rounded,
                        iconColor: Colors.orange.shade400,
                        selected: themeProvider.isLight,
                        onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                        isDark: isDark,
                      ),
                      _Divider(isDark: isDark),
                      _ThemeTile(
                        label: 'Dark Mode',
                        icon: Icons.dark_mode_rounded,
                        iconColor: const Color(0xFF8FA8F8),
                        selected: themeProvider.isDark,
                        onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                        isDark: isDark,
                      ),
                      _Divider(isDark: isDark),
                      _ThemeTile(
                        label: 'Follow System',
                        icon: Icons.brightness_auto_rounded,
                        iconColor: Colors.teal,
                        selected: themeProvider.isSystem,
                        onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

// COMING SOON SECTION
                _SectionHeader(
                    title: 'Notifications', icon: Icons.notifications_outlined),
                const SizedBox(height: 12),
                _GlassCard(
                  isDark: isDark,
                  child: _ComingSoonTile(
                    label: 'Study Reminders',
                    icon: Icons.alarm_rounded,
                    isDark: isDark,
                  ),
                ),

                const SizedBox(height: 28),

                _SectionHeader(
                    title: 'AI Settings', icon: Icons.auto_awesome_outlined),
                const SizedBox(height: 12),
                _GlassCard(
                  isDark: isDark,
                  child: _ComingSoonTile(
                    label: 'AI Study Intensity',
                    icon: Icons.tune_rounded,
                    isDark: isDark,
                  ),
                ),

                const SizedBox(height: 40),

                // Version tag
                Center(
                  child: Text(
                    'Study Well v1.0.0',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// SHARED WIDGETS
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon,
            size: 16,
            color: isDark ? const Color(0xFF8FA8F8) : const Color(0xFF334195)),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: isDark ? const Color(0xFF8FA8F8) : const Color(0xFF334195),
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _GlassCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.8),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _ThemeTile({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isDark ? Colors.white : const Color(0xFF2D3142),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF334195)
                      : (isDark ? Colors.white30 : Colors.grey.shade300),
                  width: 2,
                ),
                color: selected ? const Color(0xFF334195) : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  const _ComingSoonTile(
      {required this.label, required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: isDark ? Colors.white38 : Colors.grey.shade400,
                size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Soon',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 20,
      endIndent: 20,
      color: isDark ? Colors.white10 : Colors.grey.shade100,
    );
  }
}
