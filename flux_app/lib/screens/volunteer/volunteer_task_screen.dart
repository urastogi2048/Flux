import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux_app/providers/auth_provider.dart';

class VolunteerTaskScreen extends ConsumerStatefulWidget {
  const VolunteerTaskScreen({super.key});

  @override
  ConsumerState<VolunteerTaskScreen> createState() => _VolunteerTaskScreenState();
}

class _VolunteerTaskScreenState extends ConsumerState<VolunteerTaskScreen>
    with WidgetsBindingObserver {
  static const Color _navy = Color(0xFF002B9A);
  static const Color _sky = Color(0xFFCDE8FF);
  static const Color _pageBg = Color(0xFFF4F6F9);
  static const Color _labelGrey = Color(0xFF6B7280);
  static const Color _completeGreen = Color(0xFF1B8A4A);
  static const Color _alertRed = Color(0xFFE53935);

  String _filterStatus = 'ALL';
  final List<String> _statusFilters = ['ALL', 'ASSIGNED', 'IN PROGRESS', 'COMPLETED'];
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Auto-refresh when app comes back to foreground
      _refreshTasks();
    }
  }

  Future<void> _refreshTasks() async {
    if (!mounted) return;
    
    setState(() => _isRefreshing = true);

    final uid = ref.read(currentUserUidProvider);
    final userAsync = await ref.read(userDetailsProvider(uid ?? "").future);

    if (userAsync != null && userAsync.ngoid.isNotEmpty) {
      final ngoid = userAsync.ngoid.first;
      // Invalidate the provider to force a refresh
      ref.refresh(ngoTasksProvider(ngoid));
    }

    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final uid = ref.watch(currentUserUidProvider);
    final userAsync = ref.watch(userDetailsProvider(uid ?? ""));

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _navy,
        elevation: 0,
        title: const Text(
          'My Tasks',
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
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isRefreshing ? null : _refreshTasks,
            tooltip: 'Refresh Tasks',
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null || user.ngoid.isEmpty) {
            return _buildEmptyState(
              icon: Icons.business_outlined,
              title: 'No NGO Joined',
              subtitle: 'Please join an NGO to view and manage tasks.',
            );
          }

          final ngoid = user.ngoid.first;
          final tasksAsync = ref.watch(ngoTasksProvider(ngoid));

          return tasksAsync.when(
            data: (tasks) {
              if (tasks.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.task_alt_outlined,
                  title: 'No Tasks Available',
                  subtitle: 'Check back later for new volunteer opportunities.',
                );
              }

              // Filter tasks based on status
              final filteredTasks = _filterStatus == 'ALL'
                  ? tasks
                  : tasks
                      .where((task) =>
                          (task['status'] ?? 'ASSIGNED').toString().toUpperCase() ==
                          _filterStatus)
                      .toList();

              return RefreshIndicator(
                onRefresh: _refreshTasks,
                color: _navy,
                backgroundColor: Colors.white,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTaskStats(tasks),
                      const SizedBox(height: 24),
                      _buildFilterChips(),
                      const SizedBox(height: 20),
                      if (filteredTasks.isEmpty)
                        _buildEmptyFilterState()
                      else
                        Column(
                          children: List.generate(
                            filteredTasks.length,
                            (index) => Column(
                              children: [
                                _buildTaskCard(
                                  textTheme,
                                  filteredTasks[index],
                                ),
                                if (index < filteredTasks.length - 1)
                                  const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (e, _) => Center(
              child: Text('Error loading tasks: $e'),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e'),
        ),
      ),
    );
  }

  Widget _buildTaskStats(List<dynamic> tasks) {
    final assigned = tasks.where((t) => (t['status'] ?? 'ASSIGNED') == 'ASSIGNED').length;
    final inProgress =
        tasks.where((t) => (t['status'] ?? '').toString().toUpperCase() == 'IN PROGRESS').length;
    final completed =
        tasks.where((t) => (t['status'] ?? '').toString().toUpperCase() == 'COMPLETED').length;

    return Row(
      children: [
        Expanded(
          child: _statMetric(
            label: 'ASSIGNED',
            value: assigned.toString(),
            color: _sky,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statMetric(
            label: 'IN PROGRESS',
            value: inProgress.toString(),
            color: Color(0xFFFFF3CD),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statMetric(
            label: 'COMPLETED',
            value: completed.toString(),
            color: Color(0xFFD4EDDA),
          ),
        ),
      ],
    );
  }

  Widget _statMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _labelGrey,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          _statusFilters.length,
          (index) => Padding(
            padding: EdgeInsets.only(right: index < _statusFilters.length - 1 ? 8 : 0),
            child: FilterChip(
              label: Text(
                _statusFilters[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _filterStatus == _statusFilters[index] ? Colors.white : _navy,
                ),
              ),
              selected: _filterStatus == _statusFilters[index],
              onSelected: (selected) {
                setState(() {
                  _filterStatus = _statusFilters[index];
                });
              },
              backgroundColor: Colors.white,
              selectedColor: _navy,
              side: BorderSide(
                color: _filterStatus == _statusFilters[index] ? _navy : _sky,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(TextTheme textTheme, dynamic task) {
    final status = (task['status'] ?? 'ASSIGNED').toString().toUpperCase();
    final title = task['title'] ?? 'Untitled Task';
    final description = task['description'] ?? 'No description provided';
    final deadline = task['deadline'] ?? 'No deadline set';
    final maxVolunteers = task['maxvolunteers'] ?? 0;

    Color statusBg;
    Color statusFg;

    switch (status) {
      case 'COMPLETED':
        statusBg = Color(0xFFD4EDDA);
        statusFg = _completeGreen;
        break;
      case 'IN PROGRESS':
        statusBg = Color(0xFFFFF3CD);
        statusFg = Color(0xFF856404);
        break;
      default:
        statusBg = _sky;
        statusFg = _navy;
    }

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _sky,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: _navy,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
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
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: _labelGrey,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _infoChip(
                  icon: Icons.calendar_today_outlined,
                  label: deadline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoChip(
                  icon: Icons.people_outline,
                  label: '$maxVolunteers volunteers',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Task action feature coming soon'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: _navy,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'View Details',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, color: _labelGrey, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: _labelGrey,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: _navy),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: _labelGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          Icon(Icons.filter_list_outlined, size: 60, color: _labelGrey),
          const SizedBox(height: 16),
          Text(
            'No tasks with this status',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try selecting a different filter',
            style: const TextStyle(
              fontSize: 13,
              color: _labelGrey,
            ),
          ),
        ],
      ),
    );
  }
}
