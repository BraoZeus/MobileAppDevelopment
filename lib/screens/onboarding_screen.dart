import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSubmitting = false;

// Controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _universityController = TextEditingController();
  final _majorController = TextEditingController();
  final _goalsController = TextEditingController();

// State
  String _studyLevel = 'Undergraduate';
  String _yearOfStudy = 'Year 1';
  String _selectedEmoji = '🎓';

  final List<String> _studyLevels = [
    'High School',
    'Undergraduate',
    'Postgraduate',
    'PhD',
    'Professional',
    'Self-learner',
  ];

  final List<String> _yearsOfStudy = [
    'Year 1', 'Year 2', 'Year 3', 'Year 4', 'Year 5', 'Final Year', 'N/A',
  ];

  final List<String> _avatars = [
    '🎓', '🦊', '🦉', '🐱', '🐻', '🐼', '🐧', '🐸', '🐯', '🐙', '🚀', '🧠',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _universityController.dispose();
    _majorController.dispose();
    _goalsController.dispose();
    super.dispose();
  }

// Validation for each step
  String? _validateStep() {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty) return 'Please enter your name.';
      final age = int.tryParse(_ageController.text.trim());
      if (age == null || age < 10 || age > 100) return 'Please enter a valid age.';
    }
    return null; // step 1 and 2 are optional
  }

  void _nextStep() {
    final error = _validateStep();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _finish() async {
    setState(() => _isSubmitting = true);
    try {
      await context.read<ProfileProvider>().completeOnboarding(
        displayName: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        studyLevel: _studyLevel,
        yearOfStudy: _yearOfStudy,
        university: _universityController.text.trim(),
        major: _majorController.text.trim(),
        goals: _goalsController.text.trim(),
        avatarEmoji: _selectedEmoji,
      );
      // StreamBuilder + Consumer in main.dart will now route to MainLayout
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF111318) : Colors.white,
        body: SafeArea(
          child: Column(
            children: [
// Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AnimatedOpacity(
                          opacity: _currentStep > 0 ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: TextButton.icon(
                            onPressed: _currentStep > 0 ? _prevStep : null,
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                            label: const Text('Back'),
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFF334195)),
                          ),
                        ),
                        Text(
                          'Step ${_currentStep + 1} of 3',
                          style: const TextStyle(
                            color: Colors.black45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 80), // Balance the row
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Progress Bar
                    Row(
                      children: List.generate(3, (index) {
                        return Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 5,
                            decoration: BoxDecoration(
                              color: index <= _currentStep
                                  ? const Color(0xFF334195)
                                  : Colors.black12,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

// Page Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                  ],
                ),
              ),

// Bottom Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: _isSubmitting ? null : _prevStep,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF334195),
                            side: const BorderSide(color: Color(0xFF334195), width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Previous',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : (_currentStep < 2 ? _nextStep : _finish),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF334195),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text(
                                _currentStep < 2 ? 'Continue' : 'Get Started →',
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // STEP 1 — Who are you?
  Widget _buildStep1() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('👋', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Let\'s get to\nknow you!',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF2D3142),
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us personalise your experience.',
            style: TextStyle(fontSize: 15, color: isDark ? Colors.grey.shade400 : Colors.black54),
          ),
          const SizedBox(height: 36),
          _buildLabel('Your Name *'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _nameController,
            hint: 'e.g., Alex Johnson',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 20),
          _buildLabel('Your Age *'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _ageController,
            hint: 'e.g., 20',
            icon: Icons.cake_outlined,
            keyboard: TextInputType.number,
          ),
          const SizedBox(height: 20),
          _buildLabel('Study Level'),
          const SizedBox(height: 8),
          _buildDropdown(
            value: _studyLevel,
            items: _studyLevels,
            icon: Icons.school_outlined,
            onChanged: (val) => setState(() => _studyLevel = val!),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // STEP 2 — Your Academia
  Widget _buildStep2() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🏛️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Your Academic\nBackground',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF2D3142),
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All fields on this step are optional.',
            style: TextStyle(
                fontSize: 15,
                color: isDark ? const Color(0xFF8FA8F8) : Colors.purple.shade400,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 36),
          _buildLabel('University / Institution'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _universityController,
            hint: 'e.g., University of Melbourne',
            icon: Icons.account_balance_outlined,
          ),
          const SizedBox(height: 20),
          _buildLabel('Course / Major'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _majorController,
            hint: 'e.g., Computer Science',
            icon: Icons.menu_book_outlined,
          ),
          const SizedBox(height: 20),
          _buildLabel('Year of Study'),
          const SizedBox(height: 8),
          _buildDropdown(
            value: _yearOfStudy,
            items: _yearsOfStudy,
            icon: Icons.timeline_rounded,
            onChanged: (val) => setState(() => _yearOfStudy = val!),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // STEP 3 — Goals & Avatar
  Widget _buildStep3() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🎯', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Goals &\nYour Buddy',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF2D3142),
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'What do you want to achieve? Pick a study buddy!',
            style: TextStyle(fontSize: 15, color: isDark ? Colors.grey.shade400 : Colors.black54),
          ),
          const SizedBox(height: 36),
          _buildLabel('Your Goals (optional)'),
          const SizedBox(height: 8),
          TextField(
            controller: _goalsController,
            maxLines: 3,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'e.g., Ace my finals, build better study habits...',
              hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade600, fontSize: 14),
              filled: true,
              fillColor: isDark ? const Color(0xFF1C1F2A) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: isDark ? const Color(0xFF3A3F5C) : Colors.grey.shade400),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: isDark ? const Color(0xFF3A3F5C) : Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: isDark ? const Color(0xFF8FA8F8) : const Color(0xFF334195), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 28),
          _buildLabel('Pick your Study Buddy'),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _avatars.length,
            itemBuilder: (context, index) {
              final emoji = _avatars[index];
              final isSelected = emoji == _selectedEmoji;
              return GestureDetector(
                onTap: () => setState(() => _selectedEmoji = emoji),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? const Color(0xFF334195).withValues(alpha: 0.35) : const Color(0xFF334195).withValues(alpha: 0.15))
                        : (isDark ? const Color(0xFF1C1F2A) : Colors.white),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF334195)
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji,
                      style: TextStyle(
                          fontSize: isSelected ? 30 : 26)),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // SHARED WIDGETS
  Widget _buildLabel(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : const Color(0xFF2D3142),
        fontSize: 14,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87), 
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
        prefixIcon: Icon(icon, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
        filled: true,
        fillColor: isDark ? const Color(0xFF1C1F2A) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? const Color(0xFF3A3F5C) : Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? const Color(0xFF3A3F5C) : Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? const Color(0xFF8FA8F8) : const Color(0xFF334195), width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1F2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF3A3F5C) : Colors.grey.shade400),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.expand_more_rounded, color: isDark ? Colors.grey.shade500 : Colors.grey),
          dropdownColor: isDark ? const Color(0xFF1C1F2A) : Colors.white, 
          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16), 
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Row(
                      children: [
                        Icon(icon, size: 18, color: Colors.grey.shade400),
                        const SizedBox(width: 12),
                        Text(item, style: const TextStyle(color: Colors.black87)), // Fix item text color
                      ],
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
