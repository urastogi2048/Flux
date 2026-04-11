import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/authservice.dart';
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// A FutureProvider to easily fetch the user's role from Firestore
final userRoleProvider = FutureProvider.family<bool?, String>((ref, uid) async {
  final authService = ref.read(authServiceProvider);
  return authService.isUserAdmin(uid);
});
