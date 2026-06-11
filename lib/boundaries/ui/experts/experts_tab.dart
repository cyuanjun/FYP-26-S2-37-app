import 'package:flutter/material.dart';

import '../common/later_sprint_tab.dart';

/// BOUNDARY (#6 Experts — placeholder). The discovery surface for paid
/// coaching: expert directory + service listings. Out of the vertical slice;
/// the tab exists so the bottom nav matches the 5-tab spec.
class ExpertsTab extends StatelessWidget {
  const ExpertsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const LaterSprintTab(
      title: 'EXPERTS',
      icon: Icons.school_outlined,
      blurb: 'Browse certified experts and their coaching services — '
          'directory, search, and à-la-carte service requests.',
    );
  }
}
