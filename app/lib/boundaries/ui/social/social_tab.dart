import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../common/app_card.dart';
import '../common/avatar_button.dart';
import 'community_feed.dart';

/// BOUNDARY (#11 Social). Segmented Community / Challenges tab. Community is
/// the live feed; Challenges arrives in Phase 3 (inline placeholder card).
class SocialTab extends StatefulWidget {
  const SocialTab({super.key});

  @override
  State<SocialTab> createState() => _SocialTabState();
}

enum _SocialSubTab { community, challenges }

class _SocialTabState extends State<SocialTab> {
  _SocialSubTab _tab = _SocialSubTab.community;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text('SOCIAL', style: AppTypography.title1),
        actions: const [AvatarButton()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                _pill('Community', _SocialSubTab.community),
                const SizedBox(width: 8),
                _pill('Challenges', _SocialSubTab.challenges),
              ],
            ),
          ),
          Expanded(
            child: switch (_tab) {
              _SocialSubTab.community => const CommunityFeed(),
              _SocialSubTab.challenges => const _ChallengesPlaceholder(),
            },
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, _SocialSubTab value) {
    final selected = _tab == value;
    return GestureDetector(
      onTap: () => setState(() => _tab = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.accent : AppColors.faint),
        ),
        child: Text(label,
            style: AppTypography.footnote
                .copyWith(color: selected ? AppColors.bg : AppColors.muted)),
      ),
    );
  }
}

class _ChallengesPlaceholder extends StatelessWidget {
  const _ChallengesPlaceholder();

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
            const Text('Challenges', style: AppTypography.title3),
            const SizedBox(height: 6),
            Text('Join community fitness challenges and climb the leaderboard — '
                'landing in the next phase of this sprint.',
                style: AppTypography.subheadline),
          ],
        ),
      ),
    );
  }
}
