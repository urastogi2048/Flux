import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../models/usermodel.dart';
import '../../models/volunteermodel.dart';
import '../dashboards/volunteer_dashboard.dart';

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
      role: 'volunteer',
      profileImage: '',
      isActive: true,
      createdAt: DateTime.now(),
    );

    final volunteerModel = VolunteerModel(
      uid: user.uid,
      skills: _skillsCtrl.text.trim().split(',').map((e) => e.trim()).toList(),
      availability: _availabilityCtrl.text.trim().split(',').map((e) => e.trim()).toList(),
      location: const GeoPoint(0, 0), 
      tasksCompleted: 0,
      tasksAccepted: 0,
      tasksRejected: 0,
      rating: 5.0,
      assignedTaskIds: [],
    );

    await authService.createVolunteerProfile(user: userModel, volunteer: volunteerModel);

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const VolunteerDashboard()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Volunteer Setup')),
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
                controller: _skillsCtrl,
                decoration: const InputDecoration(labelText: 'Skills (comma separated)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _availabilityCtrl,
                decoration: const InputDecoration(labelText: 'Availability', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
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