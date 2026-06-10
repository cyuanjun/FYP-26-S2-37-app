import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';

/// BOUNDARY (#12 History) — placeholder until Phase 3 (session list + analytics).
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Center(
        child: Text('Your workout history arrives in Phase 3.', style: AppTypography.subheadline),
      ),
    );
  }
}
