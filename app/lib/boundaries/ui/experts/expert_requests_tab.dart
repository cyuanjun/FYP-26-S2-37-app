import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'expert_requests_view.dart';

// (#) The Requests tab shell in the expert app. Just wraps a scaffold and title around the requests
// (#) view that does the real work.
class ExpertRequestsTab extends StatelessWidget {
  const ExpertRequestsTab({super.key});

  // (#) Builds the scaffold with a REQUESTS title and drops the requests view in the body.
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
