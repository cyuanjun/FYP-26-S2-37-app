import 'package:flutter/material.dart';

import '../common/later_sprint_tab.dart';

/// BOUNDARY (#11 Social — placeholder). Community feed + challenges. Out of
/// the vertical slice (share posts are created from the Workout Summary);
/// the tab exists so the bottom nav matches the 5-tab spec.
class SocialTab extends StatelessWidget {
  const SocialTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const LaterSprintTab(
      title: 'SOCIAL',
      icon: Icons.groups_outlined,
      blurb: 'The community feed — shared workouts, challenges, reactions, '
          'and friends. Your shared sessions already post here.',
    );
  }
}
