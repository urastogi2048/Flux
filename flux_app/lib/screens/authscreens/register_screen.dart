import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import 'auth_wrapper.dart';
import 'login_screen.dart';
import 'signupass.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _emailFocused = false;
  bool _passFocused = false;
  bool _confirmPassFocused = false;

  Future<void> _handleEmailSignUp() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty || _confirmPassCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (_passCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (_passCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authService = ref.read(authServiceProvider);
    
    final cred = await authService.signUpWithEmail(_emailCtrl.text.trim(), _passCtrl.text.trim());
    if (cred == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign Up Failed. Try another email.')),
        );
      }
    } else {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() => _isLoading = true);
    final authService = ref.read(authServiceProvider);
    final cred = await authService.signInWithGoogle();
    
    if (cred != null) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-up failed')),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF002B9A);
    const skyBlue = Color(0xFFCDE8FF);
    const darkSkyBlue = Color(0xFF1E40AF);

    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: Stack(
          children: [
            // Gradient Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    navy,
                    darkSkyBlue,
                    navy.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),

            // Animated Background Elements
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: skyBlue.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: skyBlue.withValues(alpha: 0.08),
                ),
              ),
            ),

            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back Button
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const AuthWrapper()),
                            );
                          }
                        },
                        icon: const Icon(Icons.arrow_back, color: skyBlue),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'Create Account',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: skyBlue,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join Flux and make an impact',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: skyBlue.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Email Input
                    Focus(
                      onFocusChange: (focused) {
                        setState(() => _emailFocused = focused);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _emailFocused ? skyBlue : skyBlue.withValues(alpha: 0.3),
                            width: _emailFocused ? 2 : 1.5,
                          ),
                          color: skyBlue.withValues(alpha: 0.05),
                        ),
                        child: TextField(
                          controller: _emailCtrl,
                          style: const TextStyle(color: skyBlue),
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Enter your email',
                            hintStyle: TextStyle(color: skyBlue.withValues(alpha: 0.5)),
                            prefixIcon: Icon(Icons.email_outlined, color: skyBlue.withValues(alpha: 0.7)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password Input
                    Focus(
                      onFocusChange: (focused) {
                        setState(() => _passFocused = focused);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _passFocused ? skyBlue : skyBlue.withValues(alpha: 0.3),
                            width: _passFocused ? 2 : 1.5,
                          ),
                          color: skyBlue.withValues(alpha: 0.05),
                        ),
                        child: TextField(
                          controller: _passCtrl,
                          style: const TextStyle(color: skyBlue),
                          obscureText: !_showPassword,
                          decoration: InputDecoration(
                            hintText: 'Create a password',
                            hintStyle: TextStyle(color: skyBlue.withValues(alpha: 0.5)),
                            prefixIcon: Icon(Icons.lock_outline, color: skyBlue.withValues(alpha: 0.7)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword ? Icons.visibility : Icons.visibility_off,
                                color: skyBlue.withValues(alpha: 0.7),
                              ),
                              onPressed: () => setState(() => _showPassword = !_showPassword),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password Input
                    Focus(
                      onFocusChange: (focused) {
                        setState(() => _confirmPassFocused = focused);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _confirmPassFocused ? skyBlue : skyBlue.withValues(alpha: 0.3),
                            width: _confirmPassFocused ? 2 : 1.5,
                          ),
                          color: skyBlue.withValues(alpha: 0.05),
                        ),
                        child: TextField(
                          controller: _confirmPassCtrl,
                          style: const TextStyle(color: skyBlue),
                          obscureText: !_showConfirmPassword,
                          decoration: InputDecoration(
                            hintText: 'Confirm password',
                            hintStyle: TextStyle(color: skyBlue.withValues(alpha: 0.5)),
                            prefixIcon: Icon(Icons.lock_outline, color: skyBlue.withValues(alpha: 0.7)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                color: skyBlue.withValues(alpha: 0.7),
                              ),
                              onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Sign Up Button
                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(skyBlue),
                        ),
                      )
                    else ...[
                      FilledButton(
                        onPressed: _handleEmailSignUp,
                        style: FilledButton.styleFrom(
                          backgroundColor: skyBlue,
                          foregroundColor: navy,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'Create Account',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: skyBlue.withValues(alpha: 0.2),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'or',
                              style: TextStyle(
                                color: skyBlue.withValues(alpha: 0.6),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: skyBlue.withValues(alpha: 0.2),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Google Sign Up
                      OutlinedButton.icon(
                        onPressed: _handleGoogleSignUp,
                        icon: const Icon(Icons.login),
                        label: const Text('Sign Up with Google'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: skyBlue,
                          side: BorderSide(color: skyBlue, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(color: skyBlue.withValues(alpha: 0.8)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            },
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                color: skyBlue,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }
}