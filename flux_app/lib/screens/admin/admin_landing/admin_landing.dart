import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux_app/screens/admin/admin_create_task.dart';
import 'package:flux_app/screens/admin/admin_documents_screen.dart';
import 'package:flux_app/screens/admin/ml_task_generation_screen.dart';
import 'package:flux_app/screens/admin/news_results_screen.dart';
import '../../../services/taskgenerationservice.dart';

import '../../../providers/auth_provider.dart';
import '../../authscreens/auth_wrapper.dart';

/// Admin home / landing — layout matches product mock (navy + sky blue).
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
            icon: Icon(Icons.hub_outlined),
            selectedIcon: Icon(Icons.hub, color: _navy),
            label: 'ALLOCATION',
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
        return _allocationAuditCard(textTheme);
      default:
        return _buildHomeContent(textTheme, name);
    }
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
                          footer: '📈 Real-time count',
                          footerColor: _completeGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _metricCard(
                          label: 'PENDING REPORTS',
                          value: pendingDocsCount,
                          footer: '❗ Awaiting Smart Match',
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
                  _allocationAuditCard(textTheme),
                  const SizedBox(height: 24),
                  Text(
                    'Volunteers',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _volunteerRow(
                    initials: 'SM',
                    tint: const Color(0xFF7C4DFF),
                    name: 'Sarah Miller',
                    tags: const ['MEDICAL', 'TRUCKING'],
                  ),
                  const SizedBox(height: 10),
                  _volunteerRow(
                    initials: 'MT',
                    tint: const Color(0xFF00897B),
                    name: 'Marcus Thompson',
                    tags: const ['LOGISTICS', 'SUPPLY'],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Recent Uploads',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _uploadRow(
                    icon: Icons.picture_as_pdf,
                    iconColor: _alertRed,
                    name: 'Aurora_impact_study.pdf',
                    meta: '2.4 MB • 2h ago',
                  ),
                  const SizedBox(height: 10),
                  _uploadRow(
                    icon: Icons.image_outlined,
                    iconColor: _navy,
                    name: 'Field_Report_04.jpg',
                    meta: '1.2 MB • 3h ago',
                  ),
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

    Widget _buildMapContent() {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 80, color: _navy),
            const SizedBox(height: 20),
            Text(
              'Map Screen',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _navy),
            ),
            const SizedBox(height: 10),
            Text(
              'Coming soon',
              style: TextStyle(fontSize: 16, color: _labelGrey),
            ),
          ],
        ),
      ),
    );
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
    return ClipRRect(
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
    );
  }

  Widget _allocationAuditCard(TextTheme textTheme) {
    return SafeArea(
      child: Container(
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
              'Allocation Audit',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: _navy,
              ),
            ),
            const Divider(height: 24),
            _auditRow('Efficiency rate', '94.2%', highlight: false),
            const SizedBox(height: 12),
            _auditRow('Avg. proximity', '1.2km', highlight: false),
            const SizedBox(height: 12),
            _auditRow('Conflicts', '0', highlight: true),
          ],
        ),
      ),
    );
  }

  Widget _auditRow(String label, String value, {required bool highlight}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: _labelGrey, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: highlight ? _alertRed : _navy,
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


  Widget _volunteerRow({
    required String initials,
    required Color tint,
    required String name,
    required List<String> tags,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
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
          CircleAvatar(
            backgroundColor: tint.withValues(alpha: 0.25),
            child: Text(
              initials,
              style: TextStyle(
                color: tint,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
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
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: tags
                      .map(
                        (t) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _sky,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            t,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _navy,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: _labelGrey),
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
