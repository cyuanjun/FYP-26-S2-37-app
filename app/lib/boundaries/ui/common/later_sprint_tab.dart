import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

// (#) Placeholder screen for a tab whose feature isn't built yet. Just an icon,
// a "coming later" line and a short blurb, so the nav bar can still show every
// tab while the actual feature waits for a later sprint.
class LaterSprintTab extends StatelessWidget {
  const LaterSprintTab({
    super.key,
    required this.title, // (#) the tab name shown in the app bar
    required this.icon, // (#) the big circle icon in the middle
    required this.blurb, // (#) one line describing what's coming
  });

  final String title;
  final IconData icon;
  final String blurb;

  // (#) Builds the placeholder: centred icon, the coming soon caption and the blurb.
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
