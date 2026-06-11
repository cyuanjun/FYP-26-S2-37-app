import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../experts/experts_tab.dart';
import '../history/history_screen.dart';
import '../social/social_tab.dart';
import '../train/train_screen.dart';
import 'dashboard_tab.dart';

/// BOUNDARY — the authenticated app shell. The spec's 5-tab bottom nav
/// (Home · Experts · Train · Social · History); Experts and Social are
/// later-sprint placeholders.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  static const path = '/home';

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [
    DashboardTab(),
    ExpertsTab(),
    TrainScreen(),
    SocialTab(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Experts'),
          NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: 'Train'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Social'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}
