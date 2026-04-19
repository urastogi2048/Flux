import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux_app/models/usermodel.dart';
import 'package:flux_app/models/volunteermodel.dart';
import '../services/authservice.dart';
import '../services/datauploadservice.dart';

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

  return snapshot.docs.map((doc) {
    final data = doc.data();
    // Ensure the document ID is included in the task data
    data['taskid'] = doc.id;
    
    // Normalize task data to handle both old and new formats
    // Map old status value 'active' to 'ASSIGNED'
    if (data['status'] == 'active') {
      data['status'] = 'ASSIGNED';
    }
    
    // Ensure status field exists and is uppercase
    data['status'] = (data['status']?.toString() ?? 'ASSIGNED').toUpperCase();
    
    // Handle ML-generated tasks with different schema
    // Map 'required_resources.volunteers' to 'maxvolunteers'
    if (data['required_resources'] != null && data['maxvolunteers'] == null) {
      final volunteers = data['required_resources']['volunteers'];
      if (volunteers != null) {
        data['maxvolunteers'] = volunteers;
      }
    }
    
    // Map 'objective' to 'description' if description is missing
    if ((data['description'] == null || data['description'] == '') && data['objective'] != null) {
      data['description'] = data['objective'];
    }
    
    // Map 'timeline.deadline' to 'deadline' if deadline is missing or is a nested object
    if (data['timeline'] != null) {
      final timelineDeadline = data['timeline']['deadline'];
      if (timelineDeadline != null) {
        data['deadline'] = timelineDeadline;
      }
    }
    
    // If deadline is still an object/map, convert to string representation
    if (data['deadline'] is Map) {
      final deadlineMap = data['deadline'] as Map;
      data['deadline'] = deadlineMap['deadline'] ?? deadlineMap.toString();
    }
    
    // Ensure ngoid is set (critical for filtering)
    if (data['ngoid'] == null) {
      data['ngoid'] = ngoid;
    }
    
    return data;
  }).toList();
});

final adminCreatedTasksProvider = StreamProvider.family<List<Map<String, dynamic>>, ({String ngoid, String adminUid})>((ref, params) {
  return FirebaseFirestore.instance
      .collection('tasks')
      .where('ngoid', isEqualTo: params.ngoid)
      .where('createdBy', isEqualTo: params.adminUid)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        // Ensure the document ID is included in the task data
        data['taskid'] = doc.id;
        
        // Normalize task data to handle both old and new formats
        // Map old status value 'active' to 'ASSIGNED'
        if (data['status'] == 'active') {
          data['status'] = 'ASSIGNED';
        }
        
        // Ensure status field exists and is uppercase
        data['status'] = (data['status']?.toString() ?? 'ASSIGNED').toUpperCase();
        
        // Handle ML-generated tasks with different schema
        // Map 'required_resources.volunteers' to 'maxvolunteers'
        if (data['required_resources'] != null && data['maxvolunteers'] == null) {
          final volunteers = data['required_resources']['volunteers'];
          if (volunteers != null) {
            data['maxvolunteers'] = volunteers;
          }
        }
        
        // Map 'objective' to 'description' if description is missing
        if ((data['description'] == null || data['description'] == '') && data['objective'] != null) {
          data['description'] = data['objective'];
        }
        
        // Map 'timeline.deadline' to 'deadline' if deadline is missing or is a nested object
        if (data['timeline'] != null) {
          final timelineDeadline = data['timeline']['deadline'];
          if (timelineDeadline != null) {
            data['deadline'] = timelineDeadline;
          }
        }
        
        // If deadline is still an object/map, convert to string representation
        if (data['deadline'] is Map) {
          final deadlineMap = data['deadline'] as Map;
          data['deadline'] = deadlineMap['deadline'] ?? deadlineMap.toString();
        }
        
        // Ensure ngoid is set (critical for filtering)
        if (data['ngoid'] == null) {
          data['ngoid'] = params.ngoid;
        }
        
        return data;
      }).toList());
});

final ngoDocumentsProvider = FutureProvider.family<List<Map<String, dynamic>>?, String>((ref, ngoid) async {
  final authService = ref.read(authServiceProvider);
  final uploadService = ref.read(dataUploadServiceProvider);
  return uploadService.getNGODocs(ngoId: ngoid);
});

final activeTasksCountProvider = StreamProvider.family<int, String>((ref, ngoid) {
  return FirebaseFirestore.instance
      .collection('tasks')
      .where('ngoid', isEqualTo: ngoid)
      .where('status', isEqualTo: 'active')
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

final pendingDocumentsProvider = FutureProvider.family<int, String>((ref, ngoid) async {
  final uploadService = ref.read(dataUploadServiceProvider);
  final allDocs = await uploadService.getNGODocs(ngoId: ngoid);
  
  if (allDocs == null) return 0;
  
  // Count documents with status "PENDING"
  return allDocs.where((doc) {
    final status = doc['status']?.toString().toUpperCase() ?? '';
    return status == 'PENDING';
  }).length;
});

final dataUploadServiceProvider = Provider((ref) {
  return DataUploadService();
});
final ngoVolunteersProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, ngoid) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'volunteer')
      .where('ngoid', arrayContains: ngoid)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).toList());
});

final volunteerTaskStatsProvider = FutureProvider.family<Map<String, int>, String>((ref, ngoid) async {
  try {
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'volunteer')
        .where('ngoid', arrayContains: ngoid)
        .get();

    print('[VolunteerStats] Found ${usersSnapshot.docs.length} volunteers for NGO: $ngoid');

    int accepted = 0;
    int completed = 0;
    int rejected = 0;

    for (var userDoc in usersSnapshot.docs) {
      final userData = userDoc.data();
      final volAccepted = (userData['tasksAccepted'] as int?) ?? 0;
      final volCompleted = (userData['tasksCompleted'] as int?) ?? 0;
      final volRejected = (userData['tasksRejected'] as int?) ?? 0;
      
      print('  - Volunteer: ${userData['name']} | Accepted: $volAccepted, Completed: $volCompleted, Rejected: $volRejected');
      
      accepted += volAccepted;
      completed += volCompleted;
      rejected += volRejected;
    }

    print('[VolunteerStats] TOTALS - Accepted: $accepted, Completed: $completed, Rejected: $rejected');
    
    return {
      'accepted': accepted,
      'completed': completed,
      'rejected': rejected,
    };
  } catch (e) {
    print('[VolunteerStats] Error: $e');
    return {'accepted': 0, 'completed': 0, 'rejected': 0};
  }
});
