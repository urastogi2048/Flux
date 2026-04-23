import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../models/usermodel.dart';
import '../../models/volunteermodel.dart';
import '../volunteer/volunteerlanding.dart';

class VolunteerSetupScreen extends ConsumerStatefulWidget {
  const VolunteerSetupScreen({super.key});

  @override
  ConsumerState<VolunteerSetupScreen> createState() => _VolunteerSetupScreenState();
}

class _VolunteerSetupScreenState extends ConsumerState<VolunteerSetupScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  final _availabilityCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  bool _isLoading = false;
  bool _nameFocused = false;
  bool _phoneFocused = false;
  bool _skillsFocused = false;
  bool _availabilityFocused = false;

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty || _skillsCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    final authService = ref.read(authServiceProvider);

    final userModel = UserModel(
      uid: user.uid,
      ngoid: [],
      email: user.email ?? '',
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      role: 'volunteer',
      profileImage: '',
      isActive: true,
      createdAt: DateTime.now(),
    );

    final volunteerModel = VolunteerModel(
      uid: user.uid,
      skills: _skillsCtrl.text.trim().split(',').map((e) => e.trim()).toList(),
      availability: _availabilityCtrl.text.trim().isNotEmpty
          ? _availabilityCtrl.text.trim().split(',').map((e) => e.trim()).toList()
          : ['Flexible'],
      location: const GeoPoint(0, 0),
      tasksCompleted: 0,
      tasksAccepted: 0,
      tasksRejected: 0,
      rating: 0.0,
      assignedTaskIds: [],
    );

    try {
      await authService.createVolunteerProfile(user: userModel, volunteer: volunteerModel);

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const VolunteerLanding()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isFocused,
    required Function(bool) onFocusChange,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    const green = Color(0xFF1B8A4A);

    return Focus(
      onFocusChange: onFocusChange,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFocused ? green : green.withValues(alpha: 0.2),
            width: isFocused ? 2 : 1.5,
          ),
          color: green.withValues(alpha: 0.03),
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(color: green),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: green.withValues(alpha: 0.4)),
            labelText: label,
            labelStyle: TextStyle(
              color: isFocused ? green : green.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(icon, color: green.withValues(alpha: 0.6)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF1B8A4A);
    const lightGreen = Color(0xFFE8F5E9);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Subtle background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Colors.white,
                    lightGreen.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back Button
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: green),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Text(
                      'Volunteer Profile',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: green,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tell us about your skills and availability',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Personal Info Section
                    Text(
                      'Personal Information',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: green,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: _nameCtrl,
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      icon: Icons.person_outline,
                      isFocused: _nameFocused,
                      onFocusChange: (focused) => setState(() => _nameFocused = focused),
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: _phoneCtrl,
                      label: 'Phone Number',
                      hint: '+1 (555) 000-0000',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      isFocused: _phoneFocused,
                      onFocusChange: (focused) => setState(() => _phoneFocused = focused),
                    ),
                    const SizedBox(height: 24),

                    // Skills Section
                    Text(
                      'Skills & Expertise',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: green,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: _skillsCtrl,
                      label: 'Skills',
                      hint: 'e.g., Teaching, Healthcare, Engineering (comma separated)',
                      icon: Icons.stars_outlined,
                      isFocused: _skillsFocused,
                      onFocusChange: (focused) => setState(() => _skillsFocused = focused),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: _availabilityCtrl,
                      label: 'Availability',
                      hint: 'e.g., Weekends, Evenings, Flexible',
                      icon: Icons.schedule_outlined,
                      isFocused: _availabilityFocused,
                      onFocusChange: (focused) => setState(() => _availabilityFocused = focused),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(green),
                        ),
                      )
                    else
                      FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Complete Profile',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _skillsCtrl.dispose();
    _availabilityCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }
}
