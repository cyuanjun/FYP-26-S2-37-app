import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../common/app_card.dart';

/// BOUNDARY — the expert's incoming-requests view (role-swap of the Experts
/// tab). Fleshed out in Phase 3; this placeholder keeps the swap wired.
class ExpertRequestsView extends StatelessWidget {
  const ExpertRequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: AppCard(
        width: double.infinity,
        borderColor: AppColors.faint,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your requests', style: AppTypography.title3),
            const SizedBox(height: 6),
            Text('Incoming service requests land here — next phase of this sprint.',
                style: AppTypography.subheadline),
          ],
        ),
      ),
    );
  }
}
