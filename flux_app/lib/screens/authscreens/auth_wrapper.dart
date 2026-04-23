import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux_app/screens/admin/admin_landing/admin_landing.dart';
import 'package:flux_app/screens/volunteer/volunteerlanding.dart';
import 'package:flux_app/screens/volunteer/ngo_search_join_screen.dart';
import '../../providers/auth_provider.dart';
import 'loginoptions.dart';
import 'signupass.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginOptionsScreen();
        }
        final userRoleAsync = ref.watch(userRoleProvider(user.uid));

        return userRoleAsync.when(
          data: (isAdmin) {
            if (isAdmin == true) {
              return const AdminLandingScreen();
            } else if (isAdmin == false) {
              final userDetailsAsync = ref.watch(userDetailsProvider(user.uid));

              return userDetailsAsync.when(
                data: (userModel) {
                  if (userModel == null) {
                    return Scaffold(
                      body: SafeArea(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Color(0xFFE53935)),
                              const SizedBox(height: 16),
                              const Text('User profile not found'),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () => ref.read(authServiceProvider).signOut(),
                                child: const Text('Return to Login'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  if (userModel.ngoid.isEmpty) {
                    return NGOSearchJoinScreen(volunteerUid: user.uid);
                  }

                  return const VolunteerLanding();
                },
                loading: () => const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF002B9A))),
                  ),
                ),
                error: (err, stack) => Scaffold(
                  body: SafeArea(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Color(0xFFE53935)),
                          const SizedBox(height: 16),
                          const Text('Error loading profile'),
                          const SizedBox(height: 8),
                          Text('$err', textAlign: TextAlign.center),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => ref.read(authServiceProvider).signOut(),
                            child: const Text('Return to Login'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            } else {
              return const SignUpAs();
            }
          },
          loading: () => const Scaffold(
            body: Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF002B9A))),
            ),
          ),
          error: (err, stack) => Scaffold(
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Color(0xFFE53935)),
                    const SizedBox(height: 16),
                    const Text('Error loading role'),
                    const SizedBox(height: 8),
                    Text('$err', textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => ref.read(authServiceProvider).signOut(),
                      child: const Text('Return to Login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF002B9A))),
        ),
      ),
      error: (err, stack) => Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Color(0xFFE53935)),
                const SizedBox(height: 16),
                const Text('Authentication error'),
                const SizedBox(height: 8),
                Text('$err', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Invalidate auth state to retry
                    ref.invalidate(authStateProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
