import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../history/history_screen.dart';
import '../train/train_screen.dart';
import 'dashboard_tab.dart';

/// BOUNDARY — the authenticated app shell. Bottom nav across the vertical-slice
/// tabs (Home / Train / History). Other tabs (Social, Experts) arrive later.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  static const path = '/home';

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [DashboardTab(), TrainScreen(), HistoryScreen()];

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
          NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: 'Train'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}
