import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/adminmodel.dart';
import '../models/volunteermodel.dart';
import '../models/usermodel.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch(e) {
      print("Sign Up Error: $e");
      return null; 
    }
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch(e) {
      print("Signin error: $e");
      return null;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _googleSignIn.initialize();
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate(scopeHint: ['email']);
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print("Google Auth Error: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print("Google sign out error: $e");
    }
    await _auth.signOut();
  }

  Future<void> createVolunteerProfile({
    required UserModel user,
    required VolunteerModel volunteer,
  }) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'name': user.name,
        'role': 'volunteer',
        'phone': user.phone,
        'profileImage': user.profileImage,
        'isActive': user.isActive,
        'profileCompleted': true,
        'createdAt': FieldValue.serverTimestamp(),
        'skills': volunteer.skills,
        'availability': volunteer.availability,
        'location': volunteer.location,
        'tasksCompleted': volunteer.tasksCompleted,
        'tasksAccepted': volunteer.tasksAccepted,
        'tasksRejected': volunteer.tasksRejected,
        'rating': volunteer.rating,
        'assignedTaskIds': volunteer.assignedTaskIds,
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error creating Volunteer profile: $e");
    }
  }

  Future<void> createAdminProfile({
    required UserModel user,
    required AdminModel admin,
  }) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'name': user.name,
        'role': 'admin',
        'phone': user.phone,
        'profileImage': user.profileImage,
        'isActive': user.isActive,
        'profileCompleted': true,
        'createdAt': FieldValue.serverTimestamp(),
        'ngoname': admin.ngoname,
        'ngotype': admin.ngotype,
        'servicelocations': admin.servicelocations,
        'totalTasksCreated': admin.totalTasksCreated,
        'activeTasks': admin.activeTasks,
        'managedTaskIds': admin.managedTaskIds,
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error creating Admin profile: $e");
    }
  }

  Future<bool?> isUserAdmin(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final String? role = doc.data()?['role'];
        return role == 'admin';
      }
      return null;
    } catch (e) {
      print("Error fetching user role: $e");
      return null;
    }
  }
}