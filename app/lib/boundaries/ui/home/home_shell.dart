import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/authenticate.dart';
import '../../../controls/schedule_reminders.dart';
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

// (#) The main shell after login. Holds the bottom nav bar and flips between
// tabs. Shows the athlete tabs or the expert tabs depending on the role, and
// packs brand-new athletes off to onboarding first.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  static const path = '/home'; // (#) route the router uses to reach the shell

  // (#) Makes the state object that tracks which tab is open.
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

// (#) Live state for the shell: which tab is selected and whether reminders
// have been synced yet this session.
class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0; // (#) index of the currently selected bottom-nav tab
  bool _remindersSynced = false; // (#) guard so we only sync reminders once

  // (#) Asks for notification permission once and runs the reminder sync,
  // athletes only. Later re-syncs come from the #13.4 toggles.
  Future<void> _syncReminders() async {
    if (_remindersSynced) return;
    _remindersSynced = true;
    await ref.read(syncRemindersProvider).requestPermission();
    await ref.read(syncRemindersProvider).call();
  }

  // (#) The five screens shown to athletes, one per bottom-nav slot.
  static const _athleteTabs = [
    DashboardTab(),
    ExpertsTab(),
    TrainScreen(),
    SocialTab(),
    HistoryScreen(),
  ];

  // (#) The matching nav bar icons and labels for the athlete tabs.
  static const _athleteDestinations = [
    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Experts'),
    NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: 'Train'),
    NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Social'),
    NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'History'),
  ];

  // (#) The five screens shown to experts instead of the athlete set.
  static const _expertTabs = [
    ExpertHomeTab(),
    ExpertServicesTab(),
    ExpertRequestsTab(),
    ExpertClientsTab(),
    ExpertProfileTab(),
  ];

  // (#) The matching nav bar icons and labels for the expert tabs.
  static const _expertDestinations = [
    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Services'),
    NavigationDestination(icon: Icon(Icons.inbox_outlined), selectedIcon: Icon(Icons.inbox), label: 'Requests'),
    NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Clients'),
    NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
  ];

  // (#) Picks athlete vs expert tabs by role, sends first-time athletes to
  // onboarding, kicks off the reminder sync, and draws the nav bar.
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
    if (profile != null && !isExpert) {
      // Post-frame so the first build isn't blocked on the permission prompt.
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncReminders());
    }
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
