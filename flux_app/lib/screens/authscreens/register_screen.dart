import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleEmailSignUp() async {
    setState(() => _isLoading = true);
    final authService = ref.read(authServiceProvider);
    
    final cred = await authService.signUpWithEmail(_emailCtrl.text.trim(), _passCtrl.text.trim());
    if (cred == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign Up Failed. Check credentials.')),
        );
      }
    } else {
    
      if (mounted) {
        Navigator.pop(context);
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
        Navigator.pop(context);
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Create Account', style: textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              )),
              const SizedBox(height: 32),
              
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _passCtrl,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 24),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                FilledButton(
                  onPressed: _handleEmailSignUp,
                  child: const Text('Sign Up'),
                ),
                const SizedBox(height: 16),
                
                OutlinedButton.icon(
                  onPressed: _handleGoogleSignUp,
                  icon: const Icon(Icons.login),
                  label: const Text('Sign Up with Google'),
                ),
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Login'),
                    ),
                  ],
                )
              ],
            ],
          ),
        ),
      ),
    );
  }
}