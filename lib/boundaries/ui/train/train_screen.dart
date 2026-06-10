import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';

/// BOUNDARY (#7 Train) — placeholder until Phase 2 (workout capture).
class TrainScreen extends StatelessWidget {
  const TrainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Train')),
      body: Center(
        child: Text('Workout capture arrives in Phase 2.', style: AppTypography.subheadline),
      ),
    );
  }
}
