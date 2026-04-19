import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux_app/services/taskgenerationservice.dart';
import 'package:flux_app/screens/admin/admin_create_task.dart';

class MLTaskGenerationScreen extends ConsumerStatefulWidget {
  final String ngoId;

  const MLTaskGenerationScreen({
    super.key,
    required this.ngoId,
  });

  @override
  ConsumerState<MLTaskGenerationScreen> createState() =>
      _MLTaskGenerationScreenState();
}

class _MLTaskGenerationScreenState extends ConsumerState<MLTaskGenerationScreen> {
  static const Color _navy = Color(0xFF002B9A);
  static const Color _sky = Color(0xFFCDE8FF);
  static const Color _completeGreen = Color(0xFF1B8A4A);
  static const Color _alertRed = Color(0xFFE53935);

  late Future<Map<String, dynamic>?> _taskFuture;

  @override
  void initState() {
    super.initState();
    _taskFuture = _generateTask();
  }

  Future<Map<String, dynamic>?> _generateTask() async {
    final service = TaskGenerationService();
    return await service.generateTaskFromML(ngoId: widget.ngoId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: const Text('AI Task Generation'),
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _taskFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _navy),
                  SizedBox(height: 16),
                  Text(
                    'Generating task with AI...',
                    style: TextStyle(
                      fontSize: 16,
                      color: _navy,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: _alertRed, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Error generating task',
                    style: TextStyle(
                      fontSize: 16,
                      color: _alertRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _taskFuture = _generateTask();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navy,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: _navy, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'No task generated',
                    style: TextStyle(
                      fontSize: 16,
                      color: _navy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _taskFuture = _generateTask();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navy,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          final task = snapshot.data!;
          return _buildTaskDisplay(task, context);
        },
      ),
    );
  }

  Widget _buildTaskDisplay(Map<String, dynamic> task, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _navy,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: _sky, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI-Generated Task',
                            style: TextStyle(
                              color: Color(0xFFCDE8FF),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task['title'] ?? 'Untitled Task',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Task details grid
          _buildDetailCard(
            icon: Icons.category,
            label: 'Category',
            value: task['category']?.toString() ?? 'N/A',
          ),
          const SizedBox(height: 12),
          _buildDetailCard(
            icon: Icons.location_on,
            label: 'Location',
            value: task['location']?.toString() ?? 'N/A',
          ),
          const SizedBox(height: 12),
          _buildDetailCard(
            icon: Icons.flag,
            label: 'Priority',
            value: task['priority']?.toString() ?? 'N/A',
            isHighlight: task['priority']?.toString().toLowerCase() == 'high',
          ),
          const SizedBox(height: 12),
          _buildDetailCard(
            icon: Icons.schedule,
            label: 'Timeline',
            value: task['timeline']?.toString() ?? 'N/A',
          ),

          const SizedBox(height: 20),

          // Objective section
          if (task['objective'] != null) ...[
            const Text(
              'Objective',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _navy,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _sky,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                task['objective'].toString(),
                style: const TextStyle(
                  fontSize: 14,
                  color: _navy,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Resources section
          if (task['required_resources'] != null) ...[
            const Text(
              'Required Resources',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _navy,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _sky,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                task['required_resources'].toString(),
                style: const TextStyle(
                  fontSize: 14,
                  color: _navy,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Notes section
          if (task['notes'] != null) ...[
            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _navy,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _sky,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                task['notes'].toString(),
                style: const TextStyle(
                  fontSize: 14,
                  color: _navy,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _navy),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(color: _navy, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminCreateTask(
                          mlTitle: task['title']?.toString(),
                          mlDescription: task['objective']?.toString(),
                          mlDeadline: task['timeline']?.toString(),
                        ),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _completeGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Use Task',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlight ? _alertRed : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: isHighlight ? _alertRed : _navy, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: isHighlight ? _alertRed : _navy,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
