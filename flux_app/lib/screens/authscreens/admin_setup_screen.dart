import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../models/usermodel.dart';
import '../../models/adminmodel.dart';
import '../admin/admin_landing/admin_landing.dart';

class AdminSetupScreen extends ConsumerStatefulWidget {
  const AdminSetupScreen({super.key});

  @override
  ConsumerState<AdminSetupScreen> createState() => _AdminSetupScreenState();
}

class _AdminSetupScreenState extends ConsumerState<AdminSetupScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _ngoNameCtrl = TextEditingController();
  final _ngoTypeCtrl = TextEditingController();
  final _serviceLocationsCtrl = TextEditingController();

  bool _isLoading = false;
  bool _nameFocused = false;
  bool _phoneFocused = false;
  bool _ngoNameFocused = false;
  bool _ngoTypeFocused = false;

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty || _ngoNameCtrl.text.isEmpty || _ngoTypeCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
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
      role: 'admin',
      profileImage: '',
      isActive: true,
      createdAt: DateTime.now(),
    );

    final adminModel = AdminModel(
      uid: user.uid,
      ngoname: _ngoNameCtrl.text.trim(),
      ngotype: _ngoTypeCtrl.text.trim(),
      servicelocations: const [],
      totalTasksCreated: 0,
      activeTasks: 0,
      managedTaskIds: [],
    );

    try {
      await authService.createAdminProfile(user: userModel, admin: adminModel);
      await authService.createNGO(
        adminuid: user.uid,
        ngoname: _ngoNameCtrl.text.trim(),
        ngotype: _ngoTypeCtrl.text.trim(),
        description: '',
        servicelocations: [],
      );
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AdminLandingScreen()),
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
    TextInputType keyboardType = TextInputType.text,
  }) {
    const navy = Color(0xFF002B9A);
    const skyBlue = Color(0xFFCDE8FF);

    return Focus(
      onFocusChange: onFocusChange,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFocused ? navy : navy.withValues(alpha: 0.2),
            width: isFocused ? 2 : 1.5,
          ),
          color: navy.withValues(alpha: 0.03),
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: navy),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: navy.withValues(alpha: 0.4)),
            labelText: label,
            labelStyle: TextStyle(
              color: isFocused ? navy : navy.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(icon, color: navy.withValues(alpha: 0.6)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF002B9A);
    const skyBlue = Color(0xFFCDE8FF);

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
                    skyBlue.withValues(alpha: 0.08),
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
                        icon: const Icon(Icons.arrow_back, color: navy),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Text(
                      'NGO Admin Setup',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: navy,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete your profile to get started',
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
                        color: navy,
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

                    // NGO Info Section
                    Text(
                      'NGO Information',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: _ngoNameCtrl,
                      label: 'NGO Name',
                      hint: 'Enter your NGO name',
                      icon: Icons.business_outlined,
                      isFocused: _ngoNameFocused,
                      onFocusChange: (focused) => setState(() => _ngoNameFocused = focused),
                    ),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: _ngoTypeCtrl,
                      label: 'NGO Type',
                      hint: 'e.g., Education, Healthcare, Environment',
                      icon: Icons.category_outlined,
                      isFocused: _ngoTypeFocused,
                      onFocusChange: (focused) => setState(() => _ngoTypeFocused = focused),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(navy),
                        ),
                      )
                    else
                      FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: navy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Complete Setup',
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
    _ngoNameCtrl.dispose();
    _ngoTypeCtrl.dispose();
    _serviceLocationsCtrl.dispose();
    super.dispose();
  }
}
