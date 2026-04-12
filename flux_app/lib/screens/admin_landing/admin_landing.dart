import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../authscreens/auth_wrapper.dart';

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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(textTheme),
              const SizedBox(height: 20),
              Text(
                'Welcome back, Director.',
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
                      value: '24',
                      footer: '📈 +4 from yesterday',
                      footerColor: _completeGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _metricCard(
                      label: 'PENDING REPORTS',
                      value: '07',
                      footer: '❗ Reports for review',
                      footerColor: _alertRed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _viewReportsCard(textTheme),
              const SizedBox(height: 12),
              _unassignedTasksCard(textTheme),
              const SizedBox(height: 24),
              _sectionRow('Recent Tasks', 'VIEW ALL'),
              const SizedBox(height: 10),
              _recentTaskCard(
                icon: Icons.lock_outline,
                title: 'Medical Supply Delivery - Sector 4',
                status: 'COMPLETE',
                statusBg: _completeGreen,
                statusFg: Colors.white,
                priority: 'PRIORITY: HIGH',
              ),
              const SizedBox(height: 10),
              _recentTaskCard(
                icon: Icons.local_shipping_outlined,
                title: 'Logistics Hub Calibration',
                status: 'IN PROGRESS',
                statusBg: _sky,
                statusFg: _navy,
                priority: 'PRIORITY: MEDIUM',
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
        ),
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    return Row(
      children: [
        PopupMenuButton<String>(
          offset: const Offset(0, 48),
          onSelected: (value) {
            if (value == 'signout') _signOut();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'signout', child: Text('Sign out')),
          ],
          child: CircleAvatar(
            radius: 22,
            backgroundColor: _sky,
            child: Text(
              'SC',
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
            'Sovereign Cobalt',
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
          Text(
            footer,
            style: TextStyle(fontSize: 12, color: footerColor),
          ),
        ],
      ),
    );
  }

  Widget _viewReportsCard(TextTheme textTheme) {
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
                'Consolidated field data',
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

  Widget _unassignedTasksCard(TextTheme textTheme) {
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
              onPressed: () {},
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
    );
  }

  Widget _auditRow(String label, String value, {required bool highlight}) {
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
            color: highlight ? _alertRed : _navy,
          ),
        ),
      ],
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
