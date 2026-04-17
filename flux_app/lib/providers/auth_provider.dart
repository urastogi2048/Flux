import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux_app/models/usermodel.dart';
import 'package:flux_app/models/volunteermodel.dart';
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
final userDetailsProvider=FutureProvider.family<UserModel? , String>((ref, uid) async{
  final authService=ref.read(authServiceProvider);
  return authService.fetchUserDetails(uid);
} );
final volunteerDetailsProvider=FutureProvider.family<VolunteerModel?, String> ((ref,uid) async{
  final authService=ref.read(authServiceProvider);
  return authService.fetchVolunteerDetails(uid);
});
final currentUserUidProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenData((user) => user?.uid).value;
});

// Firestore Provider to fetch all data from firestore
final userProfileProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, uid) async {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      return doc.data();
    });

    final ngoTasksProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, ngoid) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('tasks')
      .where('ngoid', isEqualTo: ngoid)
      .get();

  return snapshot.docs.map((doc) => doc.data()).toList();
});
