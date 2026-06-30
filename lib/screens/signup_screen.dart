import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String _errorMessage = '';

// Show Success Dialog for Email Verification
  void _showVerificationDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.mark_email_unread_rounded, color: Color(0xFF334195), size: 28),
              SizedBox(width: 12),
              Text('Verify Your Email', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'A verification link has been sent to $email.\n\nPlease check your inbox and confirm your email address before attempting to log in.',
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Clear inputs after successful registration
                _emailController.clear();
                _passwordController.clear();
                _confirmPasswordController.clear();
              },
              child: const Text(
                'Understood',
                style: TextStyle(color: Color(0xFF334195), fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

// Email Sign Up with Complete Compliance Validation
  void _handleSignUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // 1. Basic Empty Field Validation
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields.';
        _isLoading = false;
      });
      return;
    }

    // 2. Passwords Match Validation
    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
        _isLoading = false;
      });
      return;
    }

    // 3. NIST/Industry Standard Password Compliance Auditing
    if (password.length < 8) {
      setState(() {
        _errorMessage = 'Password must be at least 8 characters long.';
        _isLoading = false;
      });
      return;
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      setState(() {
        _errorMessage = 'Password must contain at least one uppercase letter.';
        _isLoading = false;
      });
      return;
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      setState(() {
        _errorMessage = 'Password must contain at least one lowercase letter.';
        _isLoading = false;
      });
      return;
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      setState(() {
        _errorMessage = 'Password must contain at least one number.';
        _isLoading = false;
      });
      return;
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      setState(() {
        _errorMessage = 'Password must contain at least one special character.';
        _isLoading = false;
      });
      return;
    }

    // 4. Connect to Firebase Backend
    try {
      await _authService.signUpWithEmailPassword(email, password);
      if (mounted) {
        _showVerificationDialog(email);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

// Google Sign In Logic
  void _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = '';
    });

    try {
      final user = await _authService.signInWithGoogle();

      // Google accounts are pre-verified by Google
      if (user != null && mounted) {
        // Navigate to your main screen layout (e.g., your Bottom Nav wrapper)
        // Navigator.of(context).pushReplacement(
        //   MaterialPageRoute(builder: (context) => const YourMainWrapperScreen()),
        // );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isAnyLoading = _isLoading || _isGoogleLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111318) : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset('lib/assets/StudyWellLogo.png', height: 80, width: 80),
                const SizedBox(height: 16),
                Text(
                  'Study Well',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF2D3142)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create an account to save your progress.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: isDark ? Colors.grey.shade400 : Colors.grey),
                ),
                const SizedBox(height: 48),

                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),

                _buildTextField(
                  controller: _emailController,
                  hintText: 'Email Address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: true,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm Password',
                  icon: Icons.lock_reset_rounded,
                  obscureText: true,
                  isDark: isDark,
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: isAnyLoading ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF334195),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Sign Up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(child: Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(child: Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed: isAnyLoading ? null : _handleGoogleSignIn,
                  icon: _isGoogleLoading
                      ? const SizedBox.shrink()
                      : Icon(Icons.g_mobiledata_rounded, size: 32, color: isDark ? Colors.white : const Color(0xFF2D3142)),
                  label: _isGoogleLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('Continue with Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF2D3142))),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF1C1F2A) : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: isDark ? const Color(0xFF3A3F5C) : Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? ", style: TextStyle(color: Colors.grey)),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      child: Text("Log in", style: TextStyle(color: isDark ? const Color(0xFF8FA8F8) : const Color(0xFF334195), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF2D3142)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
        prefixIcon: Icon(icon, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
        filled: true,
        fillColor: isDark ? const Color(0xFF1C1F2A) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? const Color(0xFF3A3F5C) : Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? const Color(0xFF8FA8F8) : const Color(0xFF334195), width: 2)),
      ),
    );
  }
}
