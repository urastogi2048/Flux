import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../models/usermodel.dart';
import '../../models/adminmodel.dart';
import '../dashboards/admin_dashboard.dart';

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

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    final authService = ref.read(authServiceProvider);

    final userModel = UserModel(
      uid: user.uid,
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

    await authService.createAdminProfile(user: userModel, admin: adminModel);

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AdminDashboard()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Setup')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ngoNameCtrl,
                decoration: const InputDecoration(labelText: 'NGO Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ngoTypeCtrl,
                decoration: const InputDecoration(labelText: 'NGO Type', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _serviceLocationsCtrl,
                decoration: const InputDecoration(labelText: 'Service Locations (comma separated)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                FilledButton(
                  onPressed: _submit,
                  child: const Text('Complete Setup'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}