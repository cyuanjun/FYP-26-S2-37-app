import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// BOUNDARY — shared body for bottom-nav tabs whose feature is scoped to a
/// later sprint (Experts #6, Social #11). Keeps the 5-tab nav matching the
/// spec while the slice only implements Home / Train / History flows.
class LaterSprintTab extends StatelessWidget {
  const LaterSprintTab({
    super.key,
    required this.title,
    required this.icon,
    required this.blurb,
  });

  final String title;
  final IconData icon;
  final String blurb;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Text(title, style: AppTypography.title1),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: AppColors.accent),
              ),
              const SizedBox(height: 20),
              const Text('COMING IN A LATER SPRINT', style: AppTypography.caption2),
              const SizedBox(height: 8),
              Text(
                blurb,
                textAlign: TextAlign.center,
                style: AppTypography.subheadline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
