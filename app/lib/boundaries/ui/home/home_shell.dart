import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/authenticate.dart';
import '../../../core/theme/app_colors.dart';
import '../experts/expert_clients_tab.dart';
import '../experts/expert_home_tab.dart';
import '../experts/expert_profile_tab.dart';
import '../experts/expert_requests_tab.dart';
import '../experts/expert_services_tab.dart';
import '../experts/experts_tab.dart';
import '../history/history_screen.dart';
import '../onboarding/onboarding_flow.dart';
import '../social/social_tab.dart';
import '../train/train_screen.dart';
import 'dashboard_tab.dart';

/// BOUNDARY — the authenticated app shell. First-time athletes are routed
/// through Onboarding (#3) first. The nav is role-based:
/// athletes (free/premium) get Home · Experts · Train · Social · History;
/// experts get their own track (#20–#24: Home · Services · Requests ·
/// Clients · Profile), mirroring the wireframes' dedicated expert nav.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  static const path = '/home';

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  static const _athleteTabs = [
    DashboardTab(),
    ExpertsTab(),
    TrainScreen(),
    SocialTab(),
    HistoryScreen(),
  ];

  static const _athleteDestinations = [
    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Experts'),
    NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: 'Train'),
    NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Social'),
    NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'History'),
  ];

  static const _expertTabs = [
    ExpertHomeTab(),
    ExpertServicesTab(),
    ExpertRequestsTab(),
    ExpertClientsTab(),
    ExpertProfileTab(),
  ];

  static const _expertDestinations = [
    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Services'),
    NavigationDestination(icon: Icon(Icons.inbox_outlined), selectedIcon: Icon(Icons.inbox), label: 'Requests'),
    NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Clients'),
    NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    // First login → onboarding wizard before the shell (spec: Splash/Login
    // route on OnboardingCompletedAt; the gate lives here so both paths hit
    // it). Experts skip athlete onboarding — their setup is seed/admin-side.
    final profile = ref.watch(currentProfileProvider).value;
    if (profile != null && profile.needsOnboarding && !profile.isExpert) {
      return const OnboardingFlow();
    }

    final isExpert = profile?.isExpert ?? false;
    final tabs = isExpert ? _expertTabs : _athleteTabs;
    final destinations = isExpert ? _expertDestinations : _athleteDestinations;
    final index = _index.clamp(0, tabs.length - 1);

    return Scaffold(
      body: IndexedStack(index: index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent,
        destinations: destinations,
      ),
    );
  }
}
