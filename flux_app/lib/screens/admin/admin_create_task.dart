import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux_app/providers/auth_provider.dart';

class AdminCreateTask extends ConsumerStatefulWidget {
  const AdminCreateTask({super.key});

  @override
  ConsumerState<AdminCreateTask> createState() => _AdminCreateTaskState();
}

class _AdminCreateTaskState extends ConsumerState<AdminCreateTask> {
  static const Color _navy = Color(0xFF002B9A);
  static const Color _sky = Color(0xFFCDE8FF);
  static const Color _pageBg = Color(0xFFF4F6F9);
  static const Color _labelGrey = Color(0xFF6B7280);
  static const Color _completeGreen = Color(0xFF1B8A4A);
  static const Color _alertRed = Color(0xFFE53935);

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _deadlineCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();

  bool _loading = false;

  Future<void> _createTask() async {
    setState(() => _loading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final uid = ref.read(currentUserUidProvider);

      final user = await authService.fetchUserDetails(uid!);

      if (user == null || user.ngoid.isEmpty) {
        print("❌ No NGO found");
        _showError('No NGO found. Please set up your NGO first.');
        return;
      }

      final ngoid = user.ngoid.first;

      final max = int.tryParse(_maxCtrl.text);
      if (max == null) {
        _showError('Please enter a valid number for max volunteers');
        return;
      }

      if (_titleCtrl.text.isEmpty || _descCtrl.text.isEmpty || _deadlineCtrl.text.isEmpty) {
        _showError('Please fill in all fields');
        return;
      }

      await authService.createTask(
        ngoid: ngoid,
        title: _titleCtrl.text,
        description: _descCtrl.text,
        locations: [GeoPoint(0, 0)],
        deadline: _deadlineCtrl.text,
        maxvolunteers: max,
      );

      _showSuccess('Task Created Successfully ✓');

      if (Navigator.canPop(context)) Navigator.pop(context);

    } catch (e) {
      print("ERROR: $e");
      _showError('Failed to create task: $e');
    }

    setState(() => _loading = false);
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _navy,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _labelGrey),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _sky),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _sky, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _navy, width: 2),
            ),
          ),
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _navy,
        elevation: 0,
        title: const Text(
          'Create Task',
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Task Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _navy,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Fill in the task information to create a new volunteer task.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _labelGrey,
                    ),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _titleCtrl,
                label: 'Task Title',
                hint: 'Enter task title',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descCtrl,
                label: 'Description',
                hint: 'Enter detailed task description',
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _deadlineCtrl,
                label: 'Deadline',
                hint: 'e.g., 2024-12-31 or Today, 5:00 PM',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _maxCtrl,
                label: 'Max Volunteers',
                hint: 'Enter maximum number of volunteers',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _createTask,
                  style: FilledButton.styleFrom(
                    backgroundColor: _navy,
                    disabledBackgroundColor: _labelGrey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Create Task',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _navy, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _navy,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _deadlineCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }
}