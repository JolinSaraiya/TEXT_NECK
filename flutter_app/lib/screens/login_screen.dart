import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isSignUpMode = false;

  String _getErrorMessage(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'weak-password':
          return 'The password is too weak. Must be at least 6 characters.';
        case 'invalid-email':
          return 'The email address is invalid.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled.';
        default:
          return e.message ?? 'An authentication error occurred.';
      }
    }

    return e.toString();
  }

  void _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your email first to reset password.',
          ),
        ),
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Password reset email sent! Check your inbox.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    User? user;
    String? errorMsg;

    try {
      user = await _auth.signInWithGoogle();
    } catch (e) {
      errorMsg = _getErrorMessage(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    if (user == null && errorMsg != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _submitEmail() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (_isSignUpMode && name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name.'),
        ),
      );
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    User? user;
    String? errorMsg;

    try {
      if (_isSignUpMode) {
        user = await _auth.signUpWithEmailAndPassword(
          email,
          password,
          name: name,
        );
      } else {
        user = await _auth.signInWithEmailAndPassword(
          email,
          password,
        );
      }
    } catch (e) {
      errorMsg = _getErrorMessage(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    if (user == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMsg ?? 'Authentication failed. Please try again.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24.0,
            vertical: 48.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // =========================
              // TEXTNECK LOGO
              // =========================
              Center(
                child: Image.asset(
                  'assets/images/app_icon.png',
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 32),

              // =========================
              // WELCOME TEXT
              // =========================
              Text(
                _isSignUpMode ? 'Create account' : 'Welcome back',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _isSignUpMode
                    ? 'Register to start your posture journey'
                    : 'Sign in to continue your posture journey',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 32),

              // =========================
              // NAME FIELD
              // =========================
              if (_isSignUpMode) ...[
                _buildTextField(
                  controller: _nameController,
                  label: 'NAME',
                  hint: 'John Doe',
                  obscureText: false,
                ),
                const SizedBox(height: 16),
              ],

              // =========================
              // EMAIL FIELD
              // =========================
              _buildTextField(
                controller: _emailController,
                label: 'EMAIL',
                hint: 'you@example.com',
                obscureText: false,
              ),

              const SizedBox(height: 16),

              // =========================
              // PASSWORD FIELD
              // =========================
              _buildTextField(
                controller: _passwordController,
                label: 'PASSWORD',
                hint: '••••••••',
                obscureText: true,
              ),

              // =========================
              // FORGOT PASSWORD
              // =========================
              if (!_isSignUpMode) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _handleForgotPassword,
                    child: Text(
                      'Forgot password?',
                      style: GoogleFonts.inter(
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ] else
                const SizedBox(height: 24),

              const SizedBox(height: 24),

              // =========================
              // SIGN IN / SIGN UP BUTTON
              // =========================
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryAccent,
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryAccent.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _submitEmail,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          backgroundColor: AppColors.primaryAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _isSignUpMode ? 'Sign Up' : 'Sign In',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

              const SizedBox(height: 32),

              // =========================
              // SIGN UP / SIGN IN TOGGLE
              // =========================
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isSignUpMode
                        ? 'Already have an account? '
                        : "Don't have an account? ",
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSignUpMode = !_isSignUpMode;
                      });
                    },
                    child: Text(
                      _isSignUpMode ? 'Sign In' : 'Sign Up',
                      style: GoogleFonts.inter(
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // =========================
              // OR DIVIDER
              // =========================
              const Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: AppColors.surfaceLight,
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: AppColors.surfaceLight,
                      thickness: 1,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // =========================
              // GOOGLE SIGN IN
              // =========================
              OutlinedButton.icon(
                onPressed: _handleGoogleSignIn,
                icon: const Icon(
                  Icons.g_mobiledata,
                  size: 28,
                  color: Colors.white,
                ),
                label: Text(
                  'Continue with Google',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  side: const BorderSide(
                    color: AppColors.surfaceLight,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // TEXT FIELD BUILDER
  // =========================
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 4,
            bottom: 8,
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryAccent,
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}