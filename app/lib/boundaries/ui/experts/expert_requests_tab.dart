import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'expert_requests_view.dart';

/// BOUNDARY (#22 Expert Requests). The inbox tab of the expert shell —
/// wraps the requests view in its own scaffold.
class ExpertRequestsTab extends StatelessWidget {
  const ExpertRequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text('REQUESTS', style: AppTypography.title1),
      ),
      body: const ExpertRequestsView(),
    );
  }
}
