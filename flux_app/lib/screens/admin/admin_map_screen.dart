import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/task_map_widget.dart';

class AdminMapScreen extends ConsumerStatefulWidget {
  final String? selectedNGOId;

  const AdminMapScreen({super.key, this.selectedNGOId});

  @override
  ConsumerState<AdminMapScreen> createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends ConsumerState<AdminMapScreen> {
  static const Color _navy = Color(0xFF002B9A);
  static const Color _sky = Color(0xFFCDE8FF);
  static const Color _pageBg = Color(0xFFF4F6F9);
  static const Color _labelGrey = Color(0xFF6B7280);
  static const Color _completeGreen = Color(0xFF1B8A4A);
  static const Color _alertRed = Color(0xFFE53935);

  late String _selectedNGOId;

  @override
  void initState() {
    super.initState();
    _selectedNGOId = widget.selectedNGOId ?? '';
  }

  Future<List<Map<String, dynamic>>> _loadAdminTasks() async {
    try {
      final uid = ref.read(currentUserUidProvider);
      if (uid == null) {
        print('[AdminMapScreen] No user UID found');
        return [];
      }

      print('[AdminMapScreen] Loading tasks for admin UID: $uid');

      // If selectedNGOId is not provided, try to get it from the admin's user profile
      String ngoidToUse = _selectedNGOId;
      if (ngoidToUse.isEmpty) {
        print('[AdminMapScreen] No selectedNGOId, fetching from user profile');
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        final ngoidData = userDoc.data()?['ngoid'];
        
        // ngoid is stored as a List, get the first element
        if (ngoidData is List && (ngoidData as List).isNotEmpty) {
          ngoidToUse = (ngoidData as List).first.toString();
          print('[AdminMapScreen] Got ngoid from profile (list): $ngoidToUse');
        } else if (ngoidData is String) {
          ngoidToUse = ngoidData;
          print('[AdminMapScreen] Got ngoid from profile (string): $ngoidToUse');
        }
      } else {
        print('[AdminMapScreen] Using selectedNGOId: $ngoidToUse');
      }

      // If still empty, return all tasks created by this admin (no ngoid filter)
      if (ngoidToUse.isEmpty) {
        print('[AdminMapScreen] ngoid is empty, querying all tasks by createdBy');
        
        // First, let's see ALL tasks in the collection
        final allTasks = await FirebaseFirestore.instance
            .collection('tasks')
            .get();
        print('[AdminMapScreen] Total tasks in database: ${allTasks.docs.length}');
        for (var doc in allTasks.docs) {
          final data = doc.data();
          print('[AdminMapScreen] ALL TASK: ${data['title']} | createdBy: ${data['createdBy']} | location: ${data['location']}');
        }
        
        final snapshot = await FirebaseFirestore.instance
            .collection('tasks')
            .where('createdBy', isEqualTo: uid)
            .get();

        print('[AdminMapScreen] Found ${snapshot.docs.length} tasks created by admin $uid');

        return snapshot.docs
            .map((doc) {
              final data = doc.data();
              data['taskid'] = doc.id;
              data['status'] = (data['status']?.toString() ?? 'ASSIGNED').toUpperCase();
              print('[AdminMapScreen] Task: ${data['title']} | Location: ${data['location']}');
              return data;
            })
            .toList();
      }

      // If ngoid is available, filter by it
      print('[AdminMapScreen] Querying tasks by createdBy: $uid and ngoid: $ngoidToUse');
      
      // First, let's see ALL tasks with this ngoid
      final allNgoTasks = await FirebaseFirestore.instance
          .collection('tasks')
          .where('ngoid', isEqualTo: ngoidToUse)
          .get();
      print('[AdminMapScreen] Total tasks with ngoid $ngoidToUse: ${allNgoTasks.docs.length}');
      for (var doc in allNgoTasks.docs) {
        final data = doc.data();
        print('[AdminMapScreen] NGO TASK: ${data['title']} | createdBy: ${data['createdBy']} | location: ${data['location']}');
      }
      
      final snapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('createdBy', isEqualTo: uid)
          .where('ngoid', isEqualTo: ngoidToUse)
          .get();

      print('[AdminMapScreen] Found ${snapshot.docs.length} tasks with ngoid filter');

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['taskid'] = doc.id;
            data['status'] = (data['status']?.toString() ?? 'ASSIGNED').toUpperCase();
            print('[AdminMapScreen] Task: ${data['title']} | Location: ${data['location']}');
            return data;
          })
          .toList();
    } catch (e) {
      print('[AdminMapScreen] Error loading tasks: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _navy,
        elevation: 0,
        title: const Text(
          'Tasks Map',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadAdminTasks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: _alertRed, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading tasks',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _alertRed,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(fontSize: 12, color: _labelGrey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final tasks = snapshot.data ?? [];

          return Stack(
            children: [
              TaskMapWidget(
                tasks: tasks,
                onMarkerTap: (task) {
                  _showTaskDetails(task);
                },
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton(
                  backgroundColor: _navy,
                  onPressed: () {
                    setState(() {});
                  },
                  tooltip: 'Refresh Map',
                  child: const Icon(Icons.refresh, color: Colors.white),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                child: _buildLegend(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF002B9A),
            ),
          ),
          const SizedBox(height: 8),
          _buildLegendItem('Assigned', const Color(0xFFCDE8FF)),
          _buildLegendItem('In Progress', const Color(0xFFFFD700)),
          _buildLegendItem('Completed', const Color(0xFF1B8A4A)),
          _buildLegendItem('Rejected', const Color(0xFFE53935)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: _navy,
                width: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  void _showTaskDetails(Map<String, dynamic> task) {
    final status = (task['status'] ?? 'ASSIGNED').toString().toUpperCase();
    final statusColor = _getStatusColor(status);

    showBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task['title'] ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF002B9A),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Location', task['location'] ?? 'Not specified'),
            _buildDetailRow('Deadline', task['deadline'] ?? 'Not set'),
            _buildDetailRow(
              'Volunteers Needed',
              '${task['maxvolunteers'] ?? 0}',
            ),
            const SizedBox(height: 12),
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              task['description'] ?? 'No description',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ASSIGNED':
        return const Color(0xFFCDE8FF);
      case 'IN PROGRESS':
        return const Color(0xFFFFD700);
      case 'COMPLETED':
        return _completeGreen;
      case 'REJECTED':
        return _alertRed;
      default:
        return const Color(0xFFCDE8FF);
    }
  }
}
