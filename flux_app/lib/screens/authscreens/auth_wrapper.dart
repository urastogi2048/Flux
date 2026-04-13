import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux_app/screens/admin_landing/admin_landing.dart';
import 'package:flux_app/screens/volunteer/volunteerlanding.dart';
import '../../providers/auth_provider.dart';
import '../dashboards/admin_dashboard.dart';
import '../dashboards/volunteer_dashboard.dart';
import 'login_screen.dart';
import 'signupass.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }
        final userRoleAsync = ref.watch(userRoleProvider(user.uid));

        return userRoleAsync.when(
          data: (isAdmin) {
            if (isAdmin == true) {
              return const AdminLandingScreen();
            } else if (isAdmin == false) {
              return const VolunteerLanding();
            } else {
              return SignUpAs();
            }
          },
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => Scaffold(
            body: Center(child: Text('Error loading role: $err')),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Auth stream error: $err')),
      ),
    );
  }
}
