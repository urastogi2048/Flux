import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../authscreens/auth_wrapper.dart';

class VolunteerLanding extends ConsumerStatefulWidget {
  const VolunteerLanding({super.key});

  @override
  ConsumerState<VolunteerLanding> createState() => VolunteerLandingState();
}

class VolunteerLandingState extends ConsumerState<VolunteerLanding> {
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
        return _buildTasksContent();
      case 2:
        return _buildMapContent();
      case 3:
        return _buildProfileContent();
      default:
        return _buildHomeContent(textTheme, name);
    }
  }

  Widget _buildHomeContent(TextTheme textTheme, String name) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(textTheme, name),
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
              'Your impact matters, let\'s make a difference today.',
              style: textTheme.bodyMedium?.copyWith(color: _labelGrey),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _metricCard(
                    label: 'MY TASKS',
                    value: '2',
                    footer: '🔔 1 new assignment',
                    footerColor: _alertRed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _metricCard(
                    label: 'COMPLETED',
                    value: '18',
                    footer: '✓ This month',
                    footerColor: _completeGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _myAssignedTasksCard(textTheme),
            const SizedBox(height: 12),
            _submitReportCard(textTheme),
            const SizedBox(height: 24),
            _sectionRow('Active Tasks', 'VIEW ALL'),
            const SizedBox(height: 10),
            _recentTaskCard(
              icon: Icons.local_shipping_outlined,
              title: 'Medical Supply Delivery - Sector 4',
              status: 'ASSIGNED',
              statusBg: _sky,
              statusFg: _navy,
              priority: 'STARTS: Today, 10:00 AM',
            ),
            const SizedBox(height: 10),
            _recentTaskCard(
              icon: Icons.local_shipping_outlined,
              title: 'Emergency Relief Kit Distribution',
              status: 'IN PROGRESS',
              statusBg: _completeGreen,
              statusFg: Colors.white,
              priority: 'DUE: Today, 5:00 PM',
            ),
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
            _uploadRow(
              icon: Icons.image_outlined,
              iconColor: _navy,
              name: 'Task_Report_Medical_Delivery.jpg',
              meta: '2.1 MB • 2h ago',
            ),
            const SizedBox(height: 10),
            _uploadRow(
              icon: Icons.description_outlined,
              iconColor: _completeGreen,
              name: 'Relief_Distribution_Notes.txt',
              meta: '0.3 MB • 5h ago',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksContent() {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 80, color: _navy),
            const SizedBox(height: 20),
            Text(
              'Tasks Screen',
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
                _profileDetailCard('Email', user.email),
                const SizedBox(height: 12),
                _profileDetailCard('Phone', user.phone ?? 'Not provided'),
                const SizedBox(height: 12),
                _profileDetailCard('Member Since', user.createdAt.toString().split(' ')[0]),
                const SizedBox(height: 12),
                _profileDetailCard('Status', user.isActive ? 'Active' : 'Inactive'),
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
                          'Volunteer Statistics',
                          style: TextStyle(
                            fontSize: 18,
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

  Widget _myAssignedTasksCard(TextTheme textTheme) {
    return Container(
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
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Submit Report 📤'),
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