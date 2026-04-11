import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flux_app/providers/auth_provider.dart';
//import '../providers/auth_provider.dart';

class LoginOptionsScreen extends ConsumerWidget {
  const LoginOptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
   
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch, 
            children: [
              const Spacer(),
              Icon(
                Icons.volunteer_activism, 
                size: 80, 
                color: colorScheme.primary, 
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to Flux',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Connect, coordinate, and make an impact.',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _handleGoogleSignIn(context, ref),
                icon: const Icon(Icons.login), 
                label: const Text('Continue with Google'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                },
                icon: const Icon(Icons.email_outlined),
                label: const Text('Continue with Email'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
  Future<void> _handleGoogleSignIn(BuildContext context, WidgetRef ref) async {
 
    final authService = ref.read(authServiceProvider);
    
    final userCred = await authService.signInWithGoogle();
    
    if (userCred != null && context.mounted) {
      final uid = userCred.user!.uid;
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      
      if (!doc.exists) {
        print("Navigate to Role Selection");
      } else {
        
        final isFounder = doc.data()?['isFounder'] ?? false;
        if (isFounder) {
         
          print("Navigate to Admin");
        } else {
        
          print("Navigate to Volunteer");
        }
      }
    }
  }
}