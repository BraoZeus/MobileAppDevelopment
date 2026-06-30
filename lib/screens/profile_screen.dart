import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/profile_provider.dart';
import '../models/buddy_level_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _universityController;
  late TextEditingController _majorController;
  late TextEditingController _goalsController;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late String _studyLevel;
  late String _yearOfStudy;
  bool _isSavingProfile = false;
  bool _isChangingPassword = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  final List<String> _studyLevels = [
    'High School', 'Undergraduate', 'Postgraduate', 'PhD', 'Professional', 'Self-learner',
  ];
  final List<String> _yearsOfStudy = [
    'Year 1', 'Year 2', 'Year 3', 'Year 4', 'Year 5', 'Final Year', 'N/A',
  ];
  final List<String> _avatars = [
    '🎓', '🦊', '🦉', '🐱', '🐻', '🐼', '🐧', '🐸', '🐯', '🐙', '🚀', '🧠',
  ];

  bool get _isGoogleUser =>
      _user?.providerData.any((p) => p.providerId == 'google.com') ?? false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>().profile;
    _nameController = TextEditingController(text: profile.displayName);
    _ageController = TextEditingController(text: profile.age.toString());
    _universityController = TextEditingController(text: profile.university);
    _majorController = TextEditingController(text: profile.major);
    _goalsController = TextEditingController(text: profile.goals);
    _studyLevel = profile.studyLevel;
    _yearOfStudy = profile.yearOfStudy;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _universityController.dispose();
    _majorController.dispose();
    _goalsController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final age = int.tryParse(_ageController.text.trim());
    if (_nameController.text.trim().isEmpty) {
      _showSnack('Name cannot be empty.', isError: true);
      return;
    }
    if (age == null || age < 10 || age > 100) {
      _showSnack('Please enter a valid age.', isError: true);
      return;
    }
    setState(() => _isSavingProfile = true);
    await context.read<ProfileProvider>().updateProfile(
      displayName: _nameController.text.trim(),
      age: age,
      level: _studyLevel,
      yearOfStudy: _yearOfStudy,
      university: _universityController.text.trim(),
      major: _majorController.text.trim(),
      goals: _goalsController.text.trim(),
    );
    if (mounted) {
      setState(() => _isSavingProfile = false);
      _showSnack('Profile saved successfully!');
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _changePassword() async {
    final current = _currentPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _showSnack('Please fill in all password fields.', isError: true);
      return;
    }
    if (newPass != confirm) {
      _showSnack('New passwords do not match.', isError: true);
      return;
    }
    if (newPass.length < 8) {
      _showSnack('Password must be at least 8 characters.', isError: true);
      return;
    }
    if (!RegExp(r'[A-Z]').hasMatch(newPass)) {
      _showSnack('Password must contain an uppercase letter.', isError: true);
      return;
    }
    if (!RegExp(r'[0-9]').hasMatch(newPass)) {
      _showSnack('Password must contain a number.', isError: true);
      return;
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(newPass)) {
      _showSnack('Password must contain a special character.', isError: true);
      return;
    }

    setState(() => _isChangingPassword = true);
    try {
      final credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: current,
      );
      await _user.reauthenticateWithCredential(credential);
      await _user.updatePassword(newPass);
      if (mounted) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _showSnack('Password updated successfully!');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _showSnack('Current password is incorrect.', isError: true);
      } else {
        _showSnack(e.message ?? 'An error occurred.', isError: true);
      }
    } catch (e) {
      _showSnack('Failed to update password.', isError: true);
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showAvatarSelector(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1F2A) : const Color(0xFFF8F9FA),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Text('Choose your Study Buddy',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF2D3142))),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6, crossAxisSpacing: 12, mainAxisSpacing: 12),
              itemCount: _avatars.length,
              itemBuilder: (_, index) => InkWell(
                onTap: () {
                  context.read<ProfileProvider>().updateProfile(avatar: _avatars[index]);
                  Navigator.pop(ctx);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF252840) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(_avatars[index],
                      style: const TextStyle(fontSize: 28)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final buddy = profileProvider.profile.buddyLevel;
    final xp = profileProvider.profile.xp;

    final textPrimary = isDark ? Colors.white : const Color(0xFF2D3142);
    final textSecondary = isDark ? Colors.white54 : Colors.black45;

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
        title: Text('My Profile',
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
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
            child: Column(
              children: [// AVATAR
                GestureDetector(
                  onTap: () => _showAvatarSelector(isDark),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        height: 110,
                        width: 110,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF252840) : Colors.white,
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
                        child: Text(profileProvider.profile.avatarEmoji,
                            style: const TextStyle(fontSize: 56)),
                      ),
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: const BoxDecoration(
                            color: Color(0xFF334195), shape: BoxShape.circle),
                        child: const Icon(Icons.edit_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  profileProvider.profile.displayName.isNotEmpty
                      ? profileProvider.profile.displayName
                      : (_user?.displayName ?? 'Scholar'),
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: textPrimary),
                ),
                Text(_user?.email ?? '',
                    style: TextStyle(fontSize: 13, color: textSecondary)),
                const SizedBox(height: 12),// XP / LEVEL BADGE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(buddy.badge,
                          style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(buddy.title,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: textPrimary)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF334195)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('Lv ${buddy.level}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF334195))),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: buddy.progressAt(xp),
                                minHeight: 6,
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.06),
                                valueColor: const AlwaysStoppedAnimation(
                                    Color(0xFF334195)),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              buddy.xpToNext(xp) != null
                                  ? '$xp XP · ${buddy.xpToNext(xp)} to ${kBuddyLevels[buddy.level].title}'
                                  : '$xp XP · 🔥 Max Level!',
                              style: TextStyle(
                                  fontSize: 11, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),// PERSONAL INFO
                _buildCard(
                  title: 'Personal Info',
                  icon: Icons.person_rounded,
                  isDark: isDark,
                  children: [
                    _buildField(label: 'Full Name', controller: _nameController,
                        icon: Icons.person_outline_rounded, hint: 'Your name', isDark: isDark),
                    _buildField(label: 'Age', controller: _ageController,
                        icon: Icons.cake_outlined, hint: 'Your age',
                        keyboard: TextInputType.number, isDark: isDark),
                    _buildDropdownField(label: 'Study Level', value: _studyLevel,
                        items: _studyLevels, icon: Icons.school_outlined, isDark: isDark,
                        onChanged: (val) => setState(() => _studyLevel = val!)),
                  ],
                ),
                const SizedBox(height: 14),// ACADEMIC DETAILS
                _buildCard(
                  title: 'Academic Details',
                  icon: Icons.account_balance_outlined,
                  isDark: isDark,
                  children: [
                    _buildField(label: 'University / Institution',
                        controller: _universityController,
                        icon: Icons.account_balance_outlined, hint: 'Optional', isDark: isDark),
                    _buildField(label: 'Course / Major', controller: _majorController,
                        icon: Icons.menu_book_outlined, hint: 'Optional', isDark: isDark),
                    _buildDropdownField(label: 'Year of Study', value: _yearOfStudy,
                        items: _yearsOfStudy, icon: Icons.timeline_rounded, isDark: isDark,
                        onChanged: (val) => setState(() => _yearOfStudy = val!)),
                  ],
                ),
                const SizedBox(height: 14),// GOALS
                _buildCard(
                  title: 'My Goals',
                  icon: Icons.emoji_flags_rounded,
                  isDark: isDark,
                  children: [
                    const SizedBox(height: 4),
                    TextField(
                      controller: _goalsController,
                      maxLines: 3,
                      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF2D3142)),
                      decoration: InputDecoration(
                        hintText: 'What do you want to achieve?',
                        hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey.shade400,
                            fontSize: 14),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.white.withValues(alpha: 0.7),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.grey.shade200)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: Color(0xFF334195), width: 2)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),// SAVE BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSavingProfile ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF4D5FD4)
                          : const Color(0xFF334195),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isSavingProfile
                        ? const SizedBox(
                            height: 22, width: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Save Changes',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 24),// CHANGE PASSWORD
                if (!_isGoogleUser) ...[
                  _buildCard(
                    title: 'Change Password',
                    icon: Icons.lock_outline_rounded,
                    isDark: isDark,
                    children: [
                      _buildPasswordField(
                        label: 'Current Password',
                        controller: _currentPasswordController,
                        obscure: !_showCurrentPassword,
                        isDark: isDark,
                        onToggle: () => setState(
                            () => _showCurrentPassword = !_showCurrentPassword),
                      ),
                      _buildPasswordField(
                        label: 'New Password',
                        controller: _newPasswordController,
                        obscure: !_showNewPassword,
                        isDark: isDark,
                        onToggle: () =>
                            setState(() => _showNewPassword = !_showNewPassword),
                      ),
                      _buildPasswordField(
                        label: 'Confirm New Password',
                        controller: _confirmPasswordController,
                        obscure: !_showConfirmPassword,
                        isDark: isDark,
                        onToggle: () => setState(
                            () => _showConfirmPassword = !_showConfirmPassword),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isChangingPassword ? null : _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? const Color(0xFF252840)
                                : const Color(0xFF2D3142),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: _isChangingPassword
                              ? const SizedBox(
                                  height: 20, width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('Update Password',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }// BUILDERS
  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required bool isDark,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: 17,
                    color: isDark ? const Color(0xFF8FA8F8) : const Color(0xFF334195)),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF2D3142))),
              ]),
              const SizedBox(height: 14),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required bool isDark,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.black54)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboard,
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF2D3142)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  color: isDark ? Colors.white30 : Colors.grey.shade400,
                  fontSize: 14),
              prefixIcon: Icon(icon, size: 17,
                  color: isDark ? Colors.white30 : Colors.grey.shade400),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.7),
              isDense: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF8FA8F8)
                          : const Color(0xFF334195),
                      width: 2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.black54)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.shade200),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                isDense: true,
                dropdownColor: isDark ? const Color(0xFF252840) : Colors.white,
                style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF2D3142),
                    fontSize: 14),
                icon: Icon(Icons.expand_more_rounded,
                    color: isDark ? Colors.white38 : Colors.grey, size: 18),
                items: items
                    .map((item) => DropdownMenuItem(
                          value: item,
                          child: Row(children: [
                            Icon(icon, size: 15,
                                color: isDark ? Colors.white30 : Colors.grey.shade400),
                            const SizedBox(width: 10),
                            Text(item),
                          ]),
                        ))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.black54)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: obscure,
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF2D3142)),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.lock_outline_rounded, size: 17,
                  color: isDark ? Colors.white30 : Colors.grey.shade400),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 17,
                  color: isDark ? Colors.white30 : Colors.grey.shade400,
                ),
                onPressed: onToggle,
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.7),
              isDense: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF8FA8F8)
                          : const Color(0xFF334195),
                      width: 2)),
            ),
          ),
        ],
      ),
    );
  }
}
