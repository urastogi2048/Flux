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
        'ngoid':user.ngoid,
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
        'ngoid':user.ngoid,
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
  Future<UserModel?> fetchUserDetails(String uid) async {
    try{
      final doc = await _firestore.collection('users').doc(uid).get();
      if(doc.exists){
        final data=doc.data();
        return UserModel(
        uid: data?['uid'] ?? '',
        ngoid: List<String>.from(data?['ngoid'] ?? []),
        name: data?['name'] ?? '',
        email: data?['email'] ?? '',
        role: data?['role'] ?? 'volunteer',
        phone: data?['phone'],
        profileImage: data?['profileImage'],
        createdAt: (data?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isActive: data?['isActive'] ?? true,
        );
      }
      return null;
    }
    catch(e){
      print("Error fetching user details: $e");
      return null;
    }
  }
  Future<VolunteerModel?> fetchVolunteerDetails(String uid) async {
    try{
      final doc = await _firestore.collection('users').doc(uid).get();
      if(doc.exists) {
        final data = doc.data();
        return VolunteerModel(
          uid: uid,
          skills: List<String>.from(data?['skills'] ?? []),
          availability: List<String>.from(data?['availability'] ?? []),
          location: data?['location'] ?? const GeoPoint(0, 0),
          tasksCompleted: data?['tasksCompleted'] ?? 0,
          tasksAccepted: data?['tasksAccepted'] ?? 0,
          tasksRejected: data?['tasksRejected'] ?? 0,
          rating: data?['rating'] ?? 0.0,
          assignedTaskIds: List<String>.from(data?['assignedTaskIds'] ?? []),
        );
      }
      return null;
    }
    catch(e) {
      print("Error fetching volunteer details: $e");
      return null;
    }
  } 
  Future<String?> createNGO({
    required String adminuid,
    required String ngoname,
    required String ngotype,
    required String description,
    required List<GeoPoint> servicelocations,
    String? contactInfo,
  }) async {
    try {
      final ngoRef = _firestore.collection('ngos').doc();
      final ngoid = ngoRef.id;
      await ngoRef.set({
        'ngoid': ngoid,
        'name': ngoname,
        'ngotype': ngotype,
        'description': description,
        'servicelocations': servicelocations,
        'adminid': adminuid,
        'totalTasksCreated': 0,
        'activeTasks': 0,
        'managedTaskIds': [],
        'volunteersAssigned': [],
        'contactInfo': contactInfo ?? '',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _firestore.collection('users').doc(adminuid).update({
        'ngoid': FieldValue.arrayUnion([ngoid])
      });
      return ngoid;
    } catch (e) {
      print("Error creating NGO: $e");
      return null;
    }
  }

  Future<bool> assignVolunteerToNGO({
    required String volunteerUid,
    required String ngoid,
  }) async {
    try {
      // Add volunteer to NGO's volunteersAssigned list
      await _firestore.collection('ngos').doc(ngoid).update({
        'volunteersAssigned': FieldValue.arrayUnion([volunteerUid])
      });

      // Add NGO to volunteer's ngoid list
      await _firestore.collection('users').doc(volunteerUid).update({
        'ngoid': FieldValue.arrayUnion([ngoid])
      });

      return true;
    } catch (e) {
      print("Error assigning volunteer to NGO: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchNGODetails(String ngoid) async {
    try {
      final doc = await _firestore.collection('ngos').doc(ngoid).get();
      return doc.data();
    } catch (e) {
      print("Error fetching NGO details: $e");
      return null;
    }
  }

  Future<String?> createTask({
  required String ngoid,
  required String adminUid,
  required String title,
  required String description,
  required String location,
  required String deadline,
  required int maxvolunteers,
}) async {
  try {
    print("ENTERING createTask");

    final taskRef = _firestore.collection('tasks').doc();
    final taskId = taskRef.id;

    await taskRef.set({
      'taskid': taskId,
      'ngoid': ngoid,
      'createdBy': adminUid,
      'title': title,
      'description': description,
      'location': location,
      'deadline': deadline,
      'maxvolunteers': maxvolunteers,
      'requiredvolunteeruid': [],
      'status': 'ASSIGNED',
      'createdAt': FieldValue.serverTimestamp(),
    });

    print("TASK CREATED");

    return taskId;
  } catch (e) {
    print("ERROR: $e");
    return null;
  }
}

}