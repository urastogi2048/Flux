import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flux_app/screens/volunteer/volunteer_task_screen.dart';
import 'package:flux_app/screens/volunteer/volunteer_map_screen.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../providers/auth_provider.dart';
import '../../services/datauploadservice.dart';
import '../authscreens/auth_wrapper.dart';
import 'ngo_search_join_screen.dart';

class VolunteerLanding extends ConsumerStatefulWidget {
  final String? selectedNGOId;

  const VolunteerLanding({super.key, this.selectedNGOId});

  @override
  ConsumerState<VolunteerLanding> createState() => VolunteerLandingState();
}

class VolunteerLandingState extends ConsumerState<VolunteerLanding> {
  int _navIndex = 0;
  String? selectedFileName;
  bool _isUploading = false;
  late DataUploadService _uploadService;
  String? _selectedNGOId;
  List<Map<String, dynamic>> _joinedNGOs = [];
  Map<String, dynamic>? _selectedNGOData;
  bool _isLoadingNGOs = true;

  static const Color _navy = Color(0xFF002B9A);
  static const Color _sky = Color(0xFFCDE8FF);
  static const Color _pageBg = Color(0xFFF4F6F9);
  static const Color _labelGrey = Color(0xFF6B7280);
  static const Color _completeGreen = Color(0xFF1B8A4A);
  static const Color _alertRed = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _uploadService = DataUploadService();
    _selectedNGOId = widget.selectedNGOId;
    _loadJoinedNGOs();
  }

  Future<void> _loadJoinedNGOs() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final ngoIds = List<String>.from(userDoc.data()?['ngoid'] ?? []);

      if (ngoIds.isNotEmpty) {
        final ngoSnapshot = await FirebaseFirestore.instance
            .collection('ngos')
            .where('ngoid', whereIn: ngoIds)
            .get();

        final ngos = ngoSnapshot.docs.map((doc) => doc.data()).toList();

        setState(() {
          _joinedNGOs = ngos;
          // Set selected NGO - use passed param or first joined NGO
          if (_selectedNGOId != null && 
              ngos.any((ngo) => ngo['ngoid'] == _selectedNGOId)) {
            _selectedNGOData = ngos.firstWhere((ngo) => ngo['ngoid'] == _selectedNGOId);
          } else if (ngos.isNotEmpty) {
            _selectedNGOId = ngos[0]['ngoid'];
            _selectedNGOData = ngos[0];
          }
          _isLoadingNGOs = false;
        });
      } else {
        setState(() => _isLoadingNGOs = false);
      }
    } catch (e) {
      print("Error loading NGOs: $e");
      setState(() => _isLoadingNGOs = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AuthWrapper()),
      (route) => false,
    );
  }
  
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result == null) {
      print("User canceled file picker");
      return;
    }

    final pickedFile = File(result.files.first.path!);
    final fileName = result.files.first.name;
    
    setState(() {
      selectedFileName = fileName;
    });

    // Get user ID
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showError('User not authenticated');
      return;
    }

    // Get NGO ID from user's joined NGOs
    final userAsync = ref.read(userDetailsProvider(userId));
    final ngoId = userAsync.maybeWhen(
      data: (user) {
        if (user?.ngoid.isEmpty ?? true) {
          _showError('Please join an NGO first');
          return null;
        }
        return user!.ngoid[0]; // Get first NGO
      },
      orElse: () => null,
    );

    if (ngoId == null) {
      _showError('Unable to get NGO information');
      return;
    }

    // Determine file type
    String fileType = _getFileType(fileName);

    setState(() => _isUploading = true);

    try {
      // Step 1: Get signed URL
      final urlResponse = await _uploadService.getUploadUrl(
        userId: userId,
        ngoId: ngoId,
        fileType: fileType,
      );

      if (urlResponse == null) {
        throw Exception('Failed to get upload URL');
      }

      final signedUrl = urlResponse['upload_url'];
      final fileUrl = urlResponse['file_url'];
      final key = urlResponse['key'];

      print('===== SIGNED URL DEBUG =====');
      print('Signed URL: $signedUrl');
      print('File URL: $fileUrl');
      print('Key: $key');
      print('============================');

      // Step 2: Upload file to S3
      final uploadSuccess = await _uploadService.uploadFiletoS3(
        signedUrl: signedUrl,
        file: pickedFile,
        fileType: fileType,
      );

      if (uploadSuccess != true) {
        throw Exception('Failed to upload file to S3');
      }

      // Step 3: Save metadata
      final metaSaved = await _uploadService.saveMetaData(
        userId: userId,
        ngoId: ngoId,
        key: key,
        fileUrl: fileUrl,
      );

      if (metaSaved != true) {
        throw Exception('Failed to save file metadata');
      }

      setState(() => _isUploading = false);
      _showSuccess('File uploaded successfully! ✓');
      
    } catch (e) {
      setState(() => _isUploading = false);
      _showError('Upload failed: $e');
      print("Upload error: $e");
    }
  }

  String _getFileType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    final mimeTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'txt': 'text/plain',
    };
    return mimeTypes[ext] ?? 'application/octet-stream';
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
    final String uid = ref.watch(currentUserUidProvider) ?? '';
    final profileuser =  ref.watch(userDetailsProvider(uid));
    String name = profileuser.maybeWhen(
      data: (user) => user?.name ?? '',
      orElse: () => '',
    );
    return Scaffold(
      backgroundColor: _pageBg,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        indicatorColor: _sky,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: _navy),
            label: 'HOME',
          ),

          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt, color: _navy),
            label: 'TASKS',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: _navy),
            label: 'MAP',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: _navy),
            label: 'PROFILE',
          ),
        ],
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      body: _buildNavigationBody(textTheme, name),
    );
  }

  Widget _buildHeader(TextTheme textTheme, String name) {
    return Row(
      children: [
        InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.75,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                builder: (context, scrollController) => _buildProfileContent(),
              ),
            );
          },
          child: CircleAvatar(
            radius: 22,
            backgroundColor: _sky,
            child: Text(
              name.substring(0, 1),
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: _navy,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NGOSearchJoinScreen(
                  volunteerUid: ref.read(currentUserUidProvider) ?? '',
                ),
              ),
            );
          },
          icon: const Icon(Icons.business_outlined),
          color: _navy,
          tooltip: 'Join More NGOs',
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            shape: const CircleBorder(),
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined),
          color: _navy,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            shape: const CircleBorder(),
          ),
        ),
        IconButton(
          onPressed: () {
            _signOut();
          },
          icon: const Icon(Icons.logout),
          color: _navy,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            shape: const CircleBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationBody(TextTheme textTheme, String name) {
    switch (_navIndex) {
      case 0:
        return _buildHomeContent(textTheme, name);
      case 1:
        return VolunteerTaskScreen(selectedNGOId: _selectedNGOId);
      case 2:
        return _buildMapContent();
      case 3:
        return _buildProfileContent();
      default:
        return _buildHomeContent(textTheme, name);
    }
  }

  Widget _buildHomeContent(TextTheme textTheme, String name) {
    if (_isLoadingNGOs) {
      return Center(
        child: CircularProgressIndicator(color: _navy),
      );
    }

    if (_joinedNGOs.isEmpty) {
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.business_outlined, size: 80, color: _labelGrey),
              const SizedBox(height: 20),
              Text(
                'No NGO Joined',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Join an NGO to get started',
                style: textTheme.bodyMedium?.copyWith(color: _labelGrey),
              ),
              const SizedBox(height: 30),
              FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NGOSearchJoinScreen(
                        volunteerUid: FirebaseAuth.instance.currentUser?.uid ?? '',
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _navy,
                ),
                child: const Text('Join an NGO'),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(textTheme, name),
            const SizedBox(height: 16),
            // NGO Selector
            _buildNGOSelector(),
            const SizedBox(height: 20),
            Text(
              'Welcome back, volunteer.',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: _navy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${_selectedNGOData?['name'] ?? 'NGO'} - ${_selectedNGOData?['ngotype'] ?? 'Organization'}',
              style: textTheme.bodyMedium?.copyWith(color: _labelGrey),
            ),
            const SizedBox(height: 20),
            _buildTaskMetrics(),
            const SizedBox(height: 16),
            _myAssignedTasksCard(textTheme),
            const SizedBox(height: 12),
            _submitReportCard(textTheme),
            const SizedBox(height: 24),
            _sectionRow('Active Tasks', 'VIEW ALL'),
            const SizedBox(height: 10),
            _buildActiveTasks(textTheme),
            const SizedBox(height: 24),
            _impactCard(textTheme),
            const SizedBox(height: 10),
            _statPill(
              textTheme,
              value: '120+',
              caption: 'Lives helped',
              bg: _sky,
              valueColor: _navy,
            ),
            const SizedBox(height: 10),
            _statPill(
              textTheme,
              value: '92%',
              caption: 'Efficiency rating',
              bg: _sky,
              valueColor: _navy,
            ),
            const SizedBox(height: 24),
            Text(
              'Nearby Tasks',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _navy,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'REAL-TIME OPPORTUNITIES',
              style: textTheme.labelSmall?.copyWith(
                color: _labelGrey,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            _nearbyTasksMap(),
            const SizedBox(height: 24),
            _performanceCard(textTheme),
            const SizedBox(height: 24),
            Text(
              'Badges & Achievements',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _navy,
              ),
            ),
            const SizedBox(height: 12),
            _badgeRow(
              icon: Icons.flash_on,
              iconColor: const Color(0xFFFFA726),
              title: 'Fast Responder',
              subtitle: 'Responded within 2 hours',
            ),
            const SizedBox(height: 10),
            _badgeRow(
              icon: Icons.verified,
              iconColor: _completeGreen,
              title: 'Reliable Volunteer',
              subtitle: '10+ tasks completed on time',
            ),
            const SizedBox(height: 24),
            Text(
              'Recent Reports',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _navy,
              ),
            ),
            const SizedBox(height: 12),
            _buildRecentUploads(),
          ],
        ),
      ),
    );
  }

  Widget _buildNGOSelector() {
    if (_joinedNGOs.length <= 1) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _joinedNGOs.map((ngo) {
          final isSelected = ngo['ngoid'] == _selectedNGOId;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedNGOId = ngo['ngoid'];
                  _selectedNGOData = ngo;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? _navy : Colors.white,
                  border: Border.all(
                    color: isSelected ? _navy : _sky,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ngo['name'] ?? 'Unknown NGO',
                  style: TextStyle(
                    color: isSelected ? Colors.white : _navy,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTaskMetrics() {
    if (_selectedNGOId == null) {
      return const SizedBox.shrink();
    }

    final tasksAsync = ref.watch(ngoTasksProvider(_selectedNGOId!));

    return tasksAsync.when(
      data: (tasks) {
        final myTasks = tasks.where((t) => 
          (t['status'] ?? 'ASSIGNED').toString().toUpperCase() == 'ASSIGNED').length;
        final completed = tasks.where((t) => 
          (t['status'] ?? '').toString().toUpperCase() == 'COMPLETED').length;

        return Row(
          children: [
            Expanded(
              child: _metricCard(
                label: 'MY TASKS',
                value: myTasks.toString(),
                footer: myTasks > 0 ? '🔔 ${myTasks} assignment${myTasks > 1 ? 's' : ''}' : '✓ All caught up',
                footerColor: myTasks > 0 ? _alertRed : _completeGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                label: 'COMPLETED',
                value: completed.toString(),
                footer: '✓ This month',
                footerColor: _completeGreen,
              ),
            ),
          ],
        );
      },
      loading: () => Row(
        children: [
          Expanded(
            child: _metricCard(
              label: 'MY TASKS',
              value: '-',
              footer: 'Loading...',
              footerColor: _labelGrey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _metricCard(
              label: 'COMPLETED',
              value: '-',
              footer: 'Loading...',
              footerColor: _labelGrey,
            ),
          ),
        ],
      ),
      error: (_, __) => Row(
        children: [
          Expanded(
            child: _metricCard(
              label: 'MY TASKS',
              value: '0',
              footer: 'Error loading',
              footerColor: _alertRed,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _metricCard(
              label: 'COMPLETED',
              value: '0',
              footer: 'Error loading',
              footerColor: _alertRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTasks(TextTheme textTheme) {
    if (_selectedNGOId == null) {
      return Center(
        child: Text(
          'Select an NGO to view tasks',
          style: TextStyle(color: _labelGrey),
        ),
      );
    }

    final tasksAsync = ref.watch(ngoTasksProvider(_selectedNGOId!));

    return tasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _sky),
            ),
            child: Column(
              children: [
                Icon(Icons.task_alt_outlined, color: _labelGrey, size: 48),
                const SizedBox(height: 12),
                Text(
                  'No Tasks Available',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Check back later for new opportunities',
                  style: TextStyle(color: _labelGrey, fontSize: 13),
                ),
              ],
            ),
          );
        }

        // Show up to 2 most recent tasks
        final displayTasks = tasks.take(2).toList();

        return Column(
          children: List.generate(
            displayTasks.length,
            (index) {
              final task = displayTasks[index];
              final status = (task['status'] ?? 'ASSIGNED').toString().toUpperCase();
              Color statusBg = _sky;
              Color statusFg = _navy;

              if (status == 'IN PROGRESS') {
                statusBg = _completeGreen;
                statusFg = Colors.white;
              } else if (status == 'COMPLETED') {
                statusBg = _completeGreen.withOpacity(0.2);
                statusFg = _completeGreen;
              }

              return Column(
                children: [
                  _recentTaskCard(
                    icon: Icons.local_shipping_outlined,
                    title: task['title'] ?? 'Untitled Task',
                    status: status,
                    statusBg: statusBg,
                    statusFg: statusFg,
                    priority: task['description'] ?? 'No details',
                  ),
                  if (index < displayTasks.length - 1) const SizedBox(height: 10),
                ],
              );
            },
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      ),
      error: (error, _) => Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          color: _alertRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _alertRed),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: _alertRed, size: 48),
            const SizedBox(height: 12),
            Text(
              'Error Loading Tasks',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _alertRed,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error.toString(),
              style: TextStyle(color: _labelGrey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapContent() {
    return VolunteerMapScreen(selectedNGOId: _selectedNGOId);
  }

  Widget _buildProfileContent() {
    final String uid = ref.watch(currentUserUidProvider) ?? '';
    final userDetails = ref.watch(userDetailsProvider(uid));
    final volunteerDetails = ref.watch(volunteerDetailsProvider(uid));

    return SafeArea(
      child: userDetails.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: _navy),
        ),
        data: (user) {
          if (user == null) {
            return Center(
              child: Text('No user found'),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: _sky,
                    child: Text(
                      user.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: _navy,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _navy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.role.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          color: _labelGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                if (_selectedNGOData != null) ...[
                  Text(
                    'Current NGO',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _profileDetailCard(
                    'Organization',
                    _selectedNGOData!['name'] ?? 'Unknown',
                  ),
                  const SizedBox(height: 12),
                  _profileDetailCard(
                    'Type',
                    _selectedNGOData!['ngotype'] ?? 'Unknown',
                  ),
                  const SizedBox(height: 30),
                ],
                Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 12),
                _profileDetailCard('Email', user.email),
                const SizedBox(height: 12),
                _profileDetailCard('Phone', user.phone ?? 'Not provided'),
                const SizedBox(height: 12),
                _profileDetailCard('Member Since', user.createdAt.toString().split(' ')[0]),
                const SizedBox(height: 12),
                _profileDetailCard('Status', user.isActive ? 'Active' : 'Inactive'),
                const SizedBox(height: 30),
                _buildNGOTaskStats(),
                const SizedBox(height: 30),
                volunteerDetails.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  data: (volunteer) {
                    if (volunteer == null) {
                      return SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall Statistics',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _navy,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _statBox('Completed', volunteer.tasksCompleted.toString()),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _statBox('Accepted', volunteer.tasksAccepted.toString()),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _statBox('Rating', volunteer.rating.toStringAsFixed(1)),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  error: (err, _) => Text('Error: $err'),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _signOut,
                    style: FilledButton.styleFrom(
                      backgroundColor: _alertRed,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Sign Out'),
                  ),
                ),
              ],
            ),
          );
        },
        error: (err, _) => Center(
          child: Text('Error: $err'),
        ),
      ),
    );
  }

  Widget _buildNGOTaskStats() {
    if (_selectedNGOId == null) {
      return const SizedBox.shrink();
    }

    final tasksAsync = ref.watch(ngoTasksProvider(_selectedNGOId!));

    return tasksAsync.when(
      data: (tasks) {
        final assigned = tasks.where((t) => 
          (t['status'] ?? 'ASSIGNED').toString().toUpperCase() == 'ASSIGNED').length;
        final inProgress = tasks.where((t) => 
          (t['status'] ?? '').toString().toUpperCase() == 'IN PROGRESS').length;
        final completed = tasks.where((t) => 
          (t['status'] ?? '').toString().toUpperCase() == 'COMPLETED').length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_selectedNGOData?['name'] ?? 'NGO'} - Task Statistics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _navy,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _statBox('Assigned', assigned.toString()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statBox('In Progress', inProgress.toString()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statBox('Completed', completed.toString()),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NGO Task Statistics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
          ),
          const SizedBox(height: 12),
          const Center(child: CircularProgressIndicator()),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _profileDetailCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _sky, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: _labelGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _sky,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: _labelGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required String label,
    required String value,
    required String footer,
    required Color footerColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _labelGrey,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            footer,
            style: TextStyle(fontSize: 12, color: footerColor),
          ),
        ],
      ),
    );
  }

  Widget _myAssignedTasksCard(TextTheme textTheme,) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context)=>VolunteerTaskScreen(selectedNGOId: _selectedNGOId,)));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _navy,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: Icon(
                Icons.assignment_outlined,
                color: Colors.white.withValues(alpha: 0.9),
                size: 28,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'View Assignments',
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Accept or view your assigned tasks',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _submitReportCard(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _sky,
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(color: _navy, width: 5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.camera_alt_outlined, color: _navy, size: 28),
          const SizedBox(height: 8),
          Text(
            'Submit Task Report',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Upload images, notes & completion status for your tasks.',
            style: textTheme.bodySmall?.copyWith(color: _labelGrey),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isUploading ? null : () => _pickFile(),
              style: FilledButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isUploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Submit Report 📤'),
            ),
          ),
          if(selectedFileName != null) ...[
            const SizedBox(height: 10,),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: _completeGreen,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Selected: $selectedFileName",
                    style: TextStyle(
                      color: _completeGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionRow(String title, String action) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: _navy,
            ),
          ),
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            action,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _navy,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _recentTaskCard({
    required IconData icon,
    required String title,
    required String status,
    required Color statusBg,
    required Color statusFg,
    required String priority,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _navy, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusFg,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  priority,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _labelGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _impactCard(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -8,
            bottom: -16,
            child: Icon(
              Icons.favorite_outlined,
              size: 96,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🌟',
                style: textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'You\'re making a real difference',
                style: textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statPill(
    TextTheme textTheme, {
    required String value,
    required String caption,
    required Color bg,
    required Color valueColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: textTheme.bodyMedium?.copyWith(color: _labelGrey),
          ),
        ],
      ),
    );
  }

  Widget _nearbyTasksMap() {
    return GestureDetector(
      onTap: () {
        // Redirect to map screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VolunteerMapScreen(selectedNGOId: _selectedNGOId),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 160,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1A2744),
                      Color(0xFF243B55),
                      Color(0xFF2D4A3E),
                    ],
                  ),
                ),
              ),
              CustomPaint(painter: _TopoLinesPainter()),
              Align(
                alignment: const Alignment(0.25, -0.15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Text(
                        'NEAR YOU',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _navy,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: _completeGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _performanceCard(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Performance',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
          ),
          const Divider(height: 24),
          _performanceRow('Response time', '2.1 hrs', highlight: false),
          const SizedBox(height: 12),
          _performanceRow('Avg. distance', '1.8 km', highlight: false),
          const SizedBox(height: 12),
          _performanceRow('On-time rate', '100%', highlight: true),
        ],
      ),
    );
  }

  Widget _performanceRow(String label, String value, {required bool highlight}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: _labelGrey, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: highlight ? _completeGreen : _navy,
          ),
        ),
      ],
    );
  }

  Widget _badgeRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _labelGrey,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.star, color: iconColor, size: 20),
        ],
      ),
    );
  }

  Widget _buildRecentUploads() {
    final userId = ref.read(currentUserUidProvider);
    if (_selectedNGOId == null || userId == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<dynamic>(
      future: _getRecentUploads(userId, _selectedNGOId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Text('No recent reports');
        }

        final uploads = snapshot.data as List<dynamic>;
        if (uploads.isEmpty) {
          return const Text('No recent reports');
        }

        return Column(
          children: List.generate(
            uploads.length,
            (index) {
              final upload = uploads[index] as Map<String, dynamic>;
              final fileName = upload['s3_key']?.toString().split('/').last ?? 'Unknown file';
              final fileSize = upload['file_size'] ?? 'Unknown size';
              final createdAt = upload['created_at'];
              
              final timeDiff = _getTimeDifference(_parseDateTime(createdAt));
              final icon = _getFileIcon(fileName);
              
              return Column(
                children: [
                  _uploadRow(
                    icon: icon,
                    iconColor: index == 0 ? _navy : _completeGreen,
                    name: fileName,
                    meta: '$fileSize • $timeDiff',
                  ),
                  if (index < uploads.length - 1) const SizedBox(height: 10),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<List<dynamic>> _getRecentUploads(String userId, String ngoId) async {
    try {
      final response = await http.get(
        Uri.parse('https://flux-test-cg9c.onrender.com/uploads/ngo/$ngoId/user/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final uploads = (data is List) ? data : [];
        return uploads.take(3).toList();
      }
      return [];
    } catch (e) {
      print('[VolunteerLanding] Error fetching uploads: $e');
      return [];
    }
  }

  DateTime? _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return null;
    if (dateTime is String) {
      try {
        return DateTime.parse(dateTime);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  String _getTimeDifference(DateTime? dateTime) {
    if (dateTime == null) return 'recently';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return dateTime.toString().split(' ')[0];
    }
  }

  IconData _getFileIcon(String fileName) {
    if (fileName.toLowerCase().endsWith('.pdf')) {
      return Icons.picture_as_pdf_outlined;
    } else if (fileName.toLowerCase().endsWith('.txt')) {
      return Icons.description_outlined;
    } else if (fileName.toLowerCase().endsWith('.jpg') || 
               fileName.toLowerCase().endsWith('.png') ||
               fileName.toLowerCase().endsWith('.jpeg')) {
      return Icons.image_outlined;
    } else if (fileName.toLowerCase().endsWith('.xls') || 
               fileName.toLowerCase().endsWith('.xlsx')) {
      return Icons.table_chart_outlined;
    }
    return Icons.attach_file_outlined;
  }

  Widget _uploadRow({
    required IconData icon,
    required Color iconColor,
    required String name,
    required String meta,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: const TextStyle(fontSize: 12, color: _labelGrey),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.visibility_outlined, color: _navy),
          ),
        ],
      ),
    );
  }
}

class _TopoLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 0; i < 8; i++) {
      final path = Path();
      final y = size.height * (0.15 + i * 0.12);
      path.moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 24) {
        path.lineTo(
          x,
          y + 6 * (i.isEven ? 1 : -1) * (0.5 + (x % 48) / 48),
        );
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}