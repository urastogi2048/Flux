import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/task_normalizer.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> task;
  final String selectedNGOId;

  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.selectedNGOId,
  });

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  late FirebaseFirestore _firestore;
  late Map<String, dynamic> _normalizedTask;
  bool _isLoading = false;

  static const Color _navy = Color(0xFF002B9A);
  static const Color _sky = Color(0xFFCDE8FF);
  static const Color _pageBg = Color(0xFFF4F6F9);
  static const Color _labelGrey = Color(0xFF6B7280);
  static const Color _completeGreen = Color(0xFF1B8A4A);
  static const Color _alertRed = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    // Normalize task data on initialization
    _normalizedTask = TaskNormalizer.normalizeTask(
      Map<String, dynamic>.from(widget.task),
      taskId: widget.task['taskid'] ?? widget.task['id'] ?? 'unknown',
      ngoidFallback: widget.selectedNGOId,
    );
  }

  Future<void> _updateTaskStatus(String newStatus) async {
    setState(() => _isLoading = true);

    try {
      // Use normalized task ID
      var taskId = _normalizedTask['taskid'];
      
      if (taskId == null || taskId.isEmpty) {
        _showError('Error: Task ID not found. Cannot update task.');
        setState(() => _isLoading = false);
        return;
      }

      await _firestore
          .collection('tasks')
          .doc(taskId)
          .update({
            'status': newStatus,
            'updatedAt': DateTime.now(),
          });

      _showSuccess('Task updated to $newStatus');

      // Pop back after short delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate refresh needed
      }
    } catch (e) {
      print('Error updating task: $e');
      _showError('Error updating task: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _alertRed,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _completeGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = (_normalizedTask['status'] ?? 'ASSIGNED').toString().toUpperCase();
    final title = _normalizedTask['title'] ?? 'Untitled Task';
    final description = _normalizedTask['description'] ?? 'No description provided';
    final location = _normalizedTask['location'] ?? 'No location specified';

    // Debug: Log task information
    print('[TaskDetailScreen] ${TaskNormalizer.getTaskDebugInfo(_normalizedTask)}');

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _navy,
        elevation: 0,
        title: const Text(
          'Task Details',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _navy,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildStatusBadge(status),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Description Section
                Text(
                  'Description',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _sky),
                  ),
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: _labelGrey,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Details Grid
                Text(
                  'Task Details',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDetailGrid(),
                const SizedBox(height: 24),

                // Location
                Text(
                  'Location',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _sky),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: _navy),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(
                            fontSize: 14,
                            color: _labelGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100), // Space for action buttons
              ],
            ),
          ),
          // Action Buttons at Bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: _sky)),
              ),
              padding: const EdgeInsets.all(16),
              child: _buildActionButtons(status),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color fgColor;

    switch (status) {
      case 'COMPLETED':
        bgColor = Color(0xFFD4EDDA);
        fgColor = _completeGreen;
        break;
      case 'IN PROGRESS':
        bgColor = Color(0xFFFFF3CD);
        fgColor = Color(0xFF856404);
        break;
      case 'REJECTED':
        bgColor = _alertRed.withOpacity(0.2);
        fgColor = _alertRed;
        break;
      default:
        bgColor = _sky;
        fgColor = _navy;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: fgColor,
        ),
      ),
    );
  }

  Widget _buildDetailGrid() {
    final deadline = _normalizedTask['deadline'] ?? 'No deadline set';
    final maxVolunteers = _normalizedTask['maxvolunteers'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _sky),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, color: _navy, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Deadline',
                      style: TextStyle(
                        fontSize: 11,
                        color: _labelGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  deadline,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _navy,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _sky),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.people_outline, color: _navy, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Volunteers',
                      style: TextStyle(
                        fontSize: 11,
                        color: _labelGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$maxVolunteers needed',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _navy,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(String status) {
    if (_isLoading) {
      return SizedBox(
        height: 50,
        child: Center(
          child: CircularProgressIndicator(color: _navy),
        ),
      );
    }

    switch (status) {
      case 'ASSIGNED':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _updateTaskStatus('REJECTED'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _alertRed),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Reject',
                  style: TextStyle(color: _alertRed, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => _updateTaskStatus('IN PROGRESS'),
                style: FilledButton.styleFrom(
                  backgroundColor: _completeGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Accept',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );

      case 'IN PROGRESS':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _updateTaskStatus('REJECTED'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _alertRed),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Reject',
                  style: TextStyle(color: _alertRed, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => _updateTaskStatus('COMPLETED'),
                style: FilledButton.styleFrom(
                  backgroundColor: _completeGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Mark as Done',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );

      case 'COMPLETED':
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Color(0xFFD4EDDA),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: _completeGreen, size: 24),
              const SizedBox(width: 8),
              Text(
                'Task Completed!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _completeGreen,
                ),
              ),
            ],
          ),
        );

      case 'REJECTED':
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _alertRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cancel, color: _alertRed, size: 24),
              const SizedBox(width: 8),
              Text(
                'Task Rejected',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _alertRed,
                ),
              ),
            ],
          ),
        );

      default:
        return SizedBox.shrink();
    }
  }
}
