import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux_app/screens/admin/admin_create_task.dart';
import 'package:flux_app/screens/admin/admin_documents_screen.dart';
import 'package:flux_app/screens/admin/ml_task_generation_screen.dart';
import 'package:flux_app/screens/admin/news_results_screen.dart';
import 'package:flux_app/screens/admin/admin_map_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../services/taskgenerationservice.dart';

import '../../../providers/auth_provider.dart';
import '../../authscreens/auth_wrapper.dart';

/// Admin home / landing â€” layout matches product mock (navy + sky blue).
class AdminLandingScreen extends ConsumerStatefulWidget {
  const AdminLandingScreen({super.key});

  @override
  ConsumerState<AdminLandingScreen> createState() => _AdminLandingScreenState();
}

class _AdminLandingScreenState extends ConsumerState<AdminLandingScreen> {
  int _navIndex = 0;

  static const Color _navy = Color(0xFF002B9A);
  static const Color _sky = Color(0xFFCDE8FF);
  static const Color _pageBg = Color(0xFFF4F6F9);
  static const Color _labelGrey = Color(0xFF6B7280);
  static const Color _completeGreen = Color(0xFF1B8A4A);
  static const Color _alertRed = Color(0xFFE53935);

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AuthWrapper()),
      (route) => false,
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
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: _navy),
            label: 'DASHBOARD',
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
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people, color: _navy),
            label: 'VOLUNTEERS',
          ),
        ],
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      body: _buildNavigationBody(textTheme,name),
    );
  }

    Widget _buildNavigationBody(TextTheme textTheme, String name) {
    switch (_navIndex) {
      case 0:
        return _buildHomeContent(textTheme, name);
      case 1:
        return AdminCreateTask();
      case 2:
        return _buildMapContent();
      case 3:
        return _buildAllocationContent();
      default:
        return _buildHomeContent(textTheme, name);
    }
  }

  Widget _buildAllocationContent() {
    final user = FirebaseAuth.instance.currentUser;
    final userDetailsAsync = ref.watch(userDetailsProvider(user?.uid ?? ''));

    return userDetailsAsync.when(
      data: (userModel) {
        final ngoId = userModel?.ngoid.isNotEmpty == true ? userModel!.ngoid.first : '';
        
        if (ngoId.isEmpty) {
          return const Center(child: Text('No NGO assigned'));
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registered Volunteers',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 16),
                _buildVolunteersList(ngoId: ngoId),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildHomeContent(TextTheme textTheme , String name){
    final user = FirebaseAuth.instance.currentUser;
    final userDataAsync = ref.watch(userProfileProvider(user!.uid));
    final userDetailsAsync = ref.watch(userDetailsProvider(user.uid));

    return SafeArea(
        child: userDataAsync.when(
          data: (data) {
            final ngoId = userDetailsAsync.maybeWhen(
              data: (userModel) => userModel?.ngoid.isNotEmpty == true ? userModel!.ngoid.first : '',
              orElse: () => '',
            );

            // Watch the count providers
            final activeTasksAsync = ref.watch(activeTasksCountProvider(ngoId));
            final pendingDocsAsync = ref.watch(pendingDocumentsProvider(ngoId));
            final tasksAsync = (ngoId.isNotEmpty && user != null)
                ? ref.watch(adminCreatedTasksProvider((ngoid: ngoId, adminUid: user.uid)))
                : AsyncValue.data([]);

            final activeTasksCount = activeTasksAsync.maybeWhen(
              data: (count) => count.toString(),
              orElse: () => '0',
            );

            final pendingDocsCount = pendingDocsAsync.maybeWhen(
              data: (count) => count.toString().padLeft(2, '0'),
              orElse: () => '00',
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(textTheme, data),

                  const SizedBox(height: 20),
                  Text(
                    "Welcome back, ${data?['name'] ?? 'Admin'}",
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Mission oversight for NGO Smart Allocation project is active.',
                    style: textTheme.bodyMedium?.copyWith(color: _labelGrey),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          label: 'ACTIVE TASKS',
                          value: activeTasksCount,
                          footer: 'Real-time count',
                          footerColor: _completeGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _metricCard(
                          label: 'PENDING REPORTS',
                          value: pendingDocsCount,
                          footer: 'Smart Match',
                          footerColor: _alertRed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _viewReportsCard(textTheme),
                  const SizedBox(height: 12),
                  _unassignedTasksCard(textTheme, ngoId),
                  const SizedBox(height: 20),
                  _buildActionButtons(textTheme),
                  const SizedBox(height: 24),
                  _sectionRow('Recent Tasks', 'VIEW ALL'),
                  const SizedBox(height: 10),
                  tasksAsync.when(
                    data: (tasks) {
                      if (tasks.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No tasks yet',
                              style: TextStyle(color: _labelGrey, fontSize: 14),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: [
                          ...tasks.take(2).map((task) {
                            final status = task['status']?.toString().toUpperCase() ?? 'PENDING';
                            final priority = task['priority']?.toString().toUpperCase() ?? 'MEDIUM';
                            
                            Color statusBg = _sky;
                            Color statusFg = _navy;
                            
                            if (status == 'COMPLETE') {
                              statusBg = _completeGreen;
                              statusFg = Colors.white;
                            } else if (status == 'IN PROGRESS') {
                              statusBg = _sky;
                              statusFg = _navy;
                            }
                            
                            return Column(
                              children: [
                                _recentTaskCard(
                                  icon: Icons.task_alt_outlined,
                                  title: task['title']?.toString() ?? 'Untitled Task',
                                  status: status,
                                  statusBg: statusBg,
                                  statusFg: statusFg,
                                  priority: 'PRIORITY: $priority',
                                ),
                                const SizedBox(height: 10),
                              ],
                            );
                          }).toList(),
                        ],
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, stack) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'Error loading tasks',
                          style: TextStyle(color: _alertRed, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _objectiveCard(textTheme),
                  const SizedBox(height: 10),
                  _statPill(
                    textTheme,
                    value: '4,200+',
                    caption: 'Lives affected',
                    bg: _sky,
                    valueColor: _navy,
                  ),
                  const SizedBox(height: 10),
                  _statPill(
                    textTheme,
                    value: '88%',
                    caption: 'Optimization score',
                    bg: _sky,
                    valueColor: _navy,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Urgency Map',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'REAL-TIME ZONES',
                    style: textTheme.labelSmall?.copyWith(
                      color: _labelGrey,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _urgencyMap(),
                  const SizedBox(height: 24),
                  _volunteerStatsCard(textTheme, ngoId),
                  const SizedBox(height: 24),
                  Text(
                    'Volunteers',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildVolunteersList(ngoId: ngoId),
                  const SizedBox(height: 24),
                  Text(
                    'Recent Uploads',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAdminRecentUploads(ngoId: ngoId),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              Center(child: Text('Error loading user data: $error')),
        ),
      );
  }

    Widget _buildAdminRecentUploads({required String ngoId}) {
    if (ngoId.isEmpty) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<dynamic>(
      future: _getAdminNGOUploads(ngoId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Text('No recent uploads');
        }

        final uploads = snapshot.data as List<dynamic>;
        if (uploads.isEmpty) {
          return const Text('No recent uploads');
        }

        return Column(
          children: List.generate(
            uploads.length,
            (index) {
              final upload = uploads[index] as Map<String, dynamic>;
              final fileName = upload['s3_key']?.toString().split('/').last ?? 'Unknown file';
              final fileSize = upload['file_size'] ?? 'Unknown size';
              final createdAt = upload['created_at'];
              
              final timeDiff = _getAdminTimeDifference(_parseAdminDateTime(createdAt));
              final icon = _getAdminFileIcon(fileName);
              
              return Column(
                children: [
                  _uploadRow(
                    icon: icon,
                    iconColor: index == 0 ? _alertRed : _navy,
                    name: fileName,
                    meta: '$fileSize â€¢ $timeDiff',
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

  Future<List<dynamic>> _getAdminNGOUploads(String ngoId) async {
    try {
      final response = await http.get(
        Uri.parse('https://flux-test-cg9c.onrender.com/uploads/ngo/$ngoId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final uploads = (data is List) ? data : [];
        // Sort by created_at descending and take last 3
        uploads.sort((a, b) => (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString()));
        return uploads.take(3).toList();
      }
      return [];
    } catch (e) {
      print('[AdminLanding] Error fetching NGO uploads: $e');
      return [];
    }
  }

  DateTime? _parseAdminDateTime(dynamic dateTime) {
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

  String _getAdminTimeDifference(DateTime? dateTime) {
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

  IconData _getAdminFileIcon(String fileName) {
    if (fileName.toLowerCase().endsWith('.pdf')) {
      return Icons.picture_as_pdf;
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

  Widget _buildMapContent() {
    return const AdminMapScreen();
  }

  Widget _buildHeader(TextTheme textTheme, Map<String, dynamic>? data) {
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
              "${(data?['name'] ?? "Admin")[0].toUpperCase()}",
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
            data?['ngoname'] ?? 'NGO',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Colors.black,
            ),
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
          Text(footer, style: TextStyle(fontSize: 12, color: footerColor)),
        ],
      ),
    );
  }

  Widget _viewReportsCard(TextTheme textTheme) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminDocumentsScreen(),
          ),
        );
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
                Icons.grid_view_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: 28,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'View Reports',
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Consolidated field data & documents',
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

  Widget _unassignedTasksCard(TextTheme textTheme, String ngoId) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _sky,
        borderRadius: BorderRadius.circular(14),
        border: const Border(left: BorderSide(color: _navy, width: 5)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.smartphone, color: _navy, size: 28),
          const SizedBox(height: 8),
          Text(
            'Unassigned Tasks: 12',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Optimal matches calculated based on volunteer proximity.',
            style: textTheme.bodySmall?.copyWith(color: _labelGrey),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: ngoId.isNotEmpty
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MLTaskGenerationScreen(ngoId: ngoId),
                        ),
                      );
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Run Smart Match ⚡'),
            ),
          ),
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

  Widget _objectiveCard(TextTheme textTheme) {
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
              Icons.military_tech_outlined,
              size: 96,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '100%',
                style: textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Objective met',
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

  Widget _urgencyMap() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminMapScreen(),
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
                      'CRITICAL ZONE',
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
                      color: _alertRed,
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


  Widget _volunteerStatsCard(TextTheme textTheme, String ngoId) {
    final statsAsync = ref.watch(volunteerTaskStatsProvider(ngoId));

    return SafeArea(
      child: statsAsync.when(
        data: (stats) {
          final accepted = stats['accepted'] ?? 0;
          final completed = stats['completed'] ?? 0;
          final rejected = stats['rejected'] ?? 0;

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
                  'Volunteer Activity',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _navy,
                  ),
                ),
                const Divider(height: 24),
                _statRow('Tasks Accepted', accepted.toString(), Colors.blue),
                const SizedBox(height: 12),
                _statRow('Tasks Completed', completed.toString(), _completeGreen),
                const SizedBox(height: 12),
                _statRow('Tasks Rejected', rejected.toString(), _alertRed),
              ],
            ),
          );
        },
        loading: () => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(child: CircularProgressIndicator(color: _navy)),
        ),
        error: (error, stack) => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text('Error loading stats', style: TextStyle(color: _alertRed)),
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: _labelGrey, fontSize: 14)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileContent() {
    final String uid = ref.watch(currentUserUidProvider) ?? '';
    final userDetails = ref.watch(userDetailsProvider(uid));
    final volunteerDetails = ref.watch(volunteerDetailsProvider(uid));

    return SafeArea(
      child: userDetails.when(
        loading: () => Center(child: CircularProgressIndicator(color: _navy)),
        data: (user) {
          if (user == null) {
            return Center(child: Text('No user found'));
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
                _profileDetailCard('Email', user.email),
                const SizedBox(height: 12),
                _profileDetailCard('Phone', user.phone ?? 'Not provided'),
                const SizedBox(height: 12),
                _profileDetailCard(
                  'Member Since',
                  user.createdAt.toString().split(' ')[0],
                ),
                const SizedBox(height: 12),
                _profileDetailCard(
                  'Status',
                  user.isActive ? 'Active' : 'Inactive',
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
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
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


  Widget _buildVolunteersList({required String ngoId}) {
    final uid = ref.read(currentUserUidProvider);
    if (uid == null || ngoId.isEmpty) {
      return const Text('Unable to load volunteers');
    }

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'volunteer')
          .where('ngoid', arrayContains: ngoId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No volunteers linked to this NGO');
        }

        final volunteers = snapshot.data!.docs;
        final colors = [
          const Color(0xFF7C4DFF),
          const Color(0xFF00897B),
          const Color(0xFFFF6F00),
          const Color(0xFF1976D2),
          const Color(0xFFC62828),
        ];

        return Column(
          children: List.generate(
            volunteers.length,
            (index) {
              final volData = volunteers[index].data() as Map<String, dynamic>;
              final name = volData['name'] ?? 'Unknown';
              final email = volData['email'] ?? 'N/A';
              final phone = volData['phone'] ?? 'N/A';
              final initials = name.split(' ').map((n) => n[0]).join().toUpperCase();
              final isActive = volData['isActive'] ?? false;
              
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('volunteers')
                    .doc(volunteers[index].id)
                    .get(),
                builder: (context, volSnapshot) {
                  int tasksCompleted = 0;
                  int tasksAccepted = 0;
                  int tasksRejected = 0;
                  double rating = 0.0;
                  List<String> skills = [];

                  if (volSnapshot.hasData && volSnapshot.data != null) {
                    final volDetails = volSnapshot.data!.data() as Map<String, dynamic>?;
                    if (volDetails != null) {
                      tasksCompleted = volDetails['tasksCompleted'] ?? 0;
                      tasksAccepted = volDetails['tasksAccepted'] ?? 0;
                      tasksRejected = volDetails['tasksRejected'] ?? 0;
                      rating = (volDetails['rating'] ?? 0.0).toDouble();
                      skills = List<String>.from(volDetails['skills'] ?? []);
                    }
                  }
                  
                  return Column(
                    children: [
                      _volunteerDetailCard(
                        initials: initials,
                        tint: colors[index % colors.length],
                        name: name,
                        email: email,
                        phone: phone,
                        skills: skills,
                        tasksCompleted: tasksCompleted,
                        tasksAccepted: tasksAccepted,
                        tasksRejected: tasksRejected,
                        rating: rating,
                        isActive: isActive,
                      ),
                      if (index < volunteers.length - 1) const SizedBox(height: 16),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _volunteerDetailCard({
    required String initials,
    required Color tint,
    required String name,
    required String email,
    required String phone,
    required List<String> skills,
    required int tasksCompleted,
    required int tasksAccepted,
    required int tasksRejected,
    required double rating,
    required bool isActive,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: tint.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Avatar and Name
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: tint.withValues(alpha: 0.2),
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: tint,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? _completeGreen.withValues(alpha: 0.15) : _alertRed.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isActive ? _completeGreen : _alertRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rating > 0 ? '⭐ $rating' : 'No rating yet',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 14),
            
            // Contact Info
            Row(
              children: [
                Icon(Icons.email_outlined, size: 16, color: tint),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 16, color: tint),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    phone,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            
            // Skills Section
            if (skills.isNotEmpty) ...[
              const Text(
                'Skills',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: skills
                    .map(
                      (skill) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: tint.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: tint.withValues(alpha: 0.3), width: 1),
                        ),
                        child: Text(
                          skill,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: tint,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
            ],
            
            // Tasks Statistics
            Row(
              children: [
                Expanded(
                  child: _statBox(
                    label: 'Accepted',
                    value: tasksAccepted.toString(),
                    color: Color(0xFF2563EB),
                    icon: Icons.thumb_up_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statBox(
                    label: 'Completed',
                    value: tasksCompleted.toString(),
                    color: _completeGreen,
                    icon: Icons.check_circle_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statBox(
                    label: 'Rejected',
                    value: tasksRejected.toString(),
                    color: _alertRed,
                    icon: Icons.cancel_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: tint,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.assignment_outlined, size: 18),
                label: const Text('Assign Task', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
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
            icon: const Icon(Icons.download_outlined, color: _navy),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(TextTheme textTheme) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminCreateTask()),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, color: _navy, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        'Create Task',
                        style: textTheme.labelSmall?.copyWith(
                          color: _navy,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _showNewsDialog();
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.newspaper, color: _completeGreen, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        'Fetch News',
                        style: textTheme.labelSmall?.copyWith(
                          color: _completeGreen,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showNewsDialog() {
    final states = [
      "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar",
      "Chhattisgarh", "Goa", "Gujarat", "Haryana", "Himachal Pradesh",
      "Jharkhand", "Karnataka", "Kerala", "Madhya Pradesh", "Maharashtra",
    ];

    String? selectedState;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Select State for News'),
          content: DropdownButton<String>(
            value: selectedState,
            hint: const Text('Choose a state'),
            isExpanded: true,
            items: states
                .map((state) => DropdownMenuItem(value: state, child: Text(state)))
                .toList(),
            onChanged: (value) => setState(() => selectedState = value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedState == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NewsResultsScreen(state: selectedState!),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(backgroundColor: _navy),
              child: const Text('Fetch', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
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
        path.lineTo(x, y + 6 * (i.isEven ? 1 : -1) * (0.5 + (x % 48) / 48));
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

