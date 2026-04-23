import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flux_app/providers/auth_provider.dart';
import 'admin_setup_screen.dart';
import 'volunteer_setup_screen.dart';
import 'login_screen.dart';

class SignUpAs extends ConsumerWidget {
  const SignUpAs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const navy = Color(0xFF002B9A);
    const skyBlue = Color(0xFFCDE8FF);
    const green = Color(0xFF1B8A4A);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Subtle gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Colors.white,
                    skyBlue.withValues(alpha: 0.08),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: skyBlue.withValues(alpha: 0.2),
                            border: Border.all(color: navy, width: 2),
                          ),
                          child: const Icon(
                            Icons.person_add_outlined,
                            size: 40,
                            color: navy,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Choose Your Role',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: navy,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select how you want to help make an impact',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),

                  // NGO Admin Card
                  _buildRoleCard(
                    context,
                    icon: Icons.business_rounded,
                    title: 'NGO Admin',
                    description: 'Manage tasks and coordinate volunteers',
                    color: navy,
                    accentColor: skyBlue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminSetupScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Volunteer Card
                  _buildRoleCard(
                    context,
                    icon: Icons.volunteer_activism_rounded,
                    title: 'Volunteer',
                    description: 'Accept tasks and contribute to causes',
                    color: green,
                    accentColor: green.withValues(alpha: 0.2),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const VolunteerSetupScreen()),
                      );
                    },
                  ),
                  const Spacer(),

                  // Back to Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      TextButton(
                        onPressed: () {
                          // Sign out so AuthWrapper redirects back to LoginOptions
                          ref.read(authServiceProvider).signOut();
                        },
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: navy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor,
              ),
              child: Icon(
                icon,
                size: 30,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: color,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}