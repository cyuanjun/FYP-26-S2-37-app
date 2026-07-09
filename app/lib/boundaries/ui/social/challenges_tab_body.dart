import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/challenges.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/challenge_summary.dart';
import 'challenge_card.dart';
import 'challenge_detail_screen.dart';
import 'create_challenge_sheet.dart';

enum _ChallengeFilter { joined, active, past }

/// BOUNDARY — the Challenges tab body (#11): create button + Joined/Active/
/// Past sub-tabs over challenge cards. Partitioning uses the entity's window
/// rules; invite-only challenges appear only once joined (approved trim).
class ChallengesTabBody extends ConsumerStatefulWidget {
  const ChallengesTabBody({super.key});

  @override
  ConsumerState<ChallengesTabBody> createState() => _ChallengesTabBodyState();
}

class _ChallengesTabBodyState extends ConsumerState<ChallengesTabBody> {
  _ChallengeFilter _filter = _ChallengeFilter.joined;
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  List<ChallengeSummary> _partition(List<ChallengeSummary> all) {
    final now = DateTime.now();
    return switch (_filter) {
      _ChallengeFilter.joined => all.where((s) => s.joined).toList(),
      _ChallengeFilter.active => all
          .where((s) =>
              s.challenge.isActive(now) &&
              (s.challenge.visibility.name == 'public' || s.joined))
          .toList(),
      _ChallengeFilter.past =>
        all.where((s) => s.challenge.isPast(now) && s.joined).toList(),
    };
  }

  /// Resolve a typed join code → open the challenge detail so the user reviews
  /// it before joining. Unknown code → inline error.
  Future<void> _resolveCode(String code) async {
    if (code.trim().isEmpty) return;
    final challenge = await ref.read(findChallengeByCodeProvider).call(code);
    if (!mounted) return;
    if (challenge == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No challenge found for that code.')));
      return;
    }
    _codeCtrl.clear();
    FocusScope.of(context).unfocus();
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
        builder: (_) => ChallengeDetailScreen(challengeId: challenge.id)));
  }

  String get _emptyCopy => switch (_filter) {
        _ChallengeFilter.joined =>
          "You haven't joined any challenges yet — browse Active to find one.",
        _ChallengeFilter.active => 'No active challenges right now.',
        _ChallengeFilter.past => 'No finished challenges yet.',
      };

  @override
  Widget build(BuildContext context) {
    final challenges = ref.watch(challengesProvider);

    return Column(
      children: [
        // Join-by-code search — enter a shared code to open its challenge.
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: TextField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.go,
            maxLength: 6,
            onSubmitted: _resolveCode,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
              TextInputFormatter.withFunction((_, n) =>
                  n.copyWith(text: n.text.toUpperCase())),
            ],
            decoration: InputDecoration(
              hintText: 'Enter challenge code',
              prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20),
              isDense: true,
              counterText: '',
              suffixIcon: TextButton(
                onPressed: () => _resolveCode(_codeCtrl.text),
                child: const Text('Join'),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            children: [
              for (final f in _ChallengeFilter.values) ...[
                _pill(f),
                const SizedBox(width: 8),
              ],
              const Spacer(),
              GestureDetector(
                onTap: () => showCreateChallengeSheet(context),
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      color: AppColors.accent, shape: BoxShape.circle),
                  child:
                      const Icon(Icons.add, color: AppColors.bg, size: 20),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: challenges.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
                child: Text('Could not load challenges.\n$e',
                    style: AppTypography.footnote,
                    textAlign: TextAlign.center)),
            data: (all) {
              final shown = _partition(all);
              if (shown.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(_emptyCopy,
                        style: AppTypography.subheadline,
                        textAlign: TextAlign.center),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(challengesProvider),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    for (final s in shown) ChallengeCard(summary: s),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _pill(_ChallengeFilter f) {
    final selected = _filter == f;
    final label = switch (f) {
      _ChallengeFilter.joined => 'Joined',
      _ChallengeFilter.active => 'Active',
      _ChallengeFilter.past => 'Past',
    };
    return GestureDetector(
      onTap: () => setState(() => _filter = f),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.bg,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: selected ? AppColors.accent : AppColors.faint),
        ),
        child: Text(label,
            style: AppTypography.footnote
                .copyWith(color: selected ? AppColors.bg : AppColors.muted)),
      ),
    );
  }
}
