import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_landing/admin_landing.dart';

/// Entry for signed-in admins; main experience is the landing dashboard.
class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AdminLandingScreen();
  }
}
