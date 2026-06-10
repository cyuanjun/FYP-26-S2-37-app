import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/save_workout_details.dart';
import '../../../controls/share_workout.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/enums.dart';
import '../../../entities/workout_type.dart';

/// BOUNDARY (#10 Workout Summary). Post-session recap: stats + XP, name / feel /
/// notes, and Share to Social (creates a workout_share Post + named-platform share).
class WorkoutSummaryScreen extends ConsumerStatefulWidget {
  const WorkoutSummaryScreen({
    super.key,
    required this.sessionId,
    required this.type,
    required this.elapsed,
    required this.distanceMeters,
    required this.result,
  });

  final String sessionId;
  final WorkoutType type;
  final Duration elapsed;
  final double distanceMeters;
  final Map<String, dynamic> result;

  @override
  ConsumerState<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends ConsumerState<WorkoutSummaryScreen> {
  final _name = TextEditingController();
  final _notes = TextEditingController();
  final _caption = TextEditingController();
  FeelRating? _feel;
  bool _saving = false;
  bool _share = false;

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    _caption.dispose();
    super.dispose();
  }

  String _shareText() {
    final t = widget.type.name;
    final dur = fmtDuration(widget.elapsed);
    return widget.type.isCardio
        ? 'I just finished a $t workout — ${fmtKm(widget.distanceMeters)} km in $dur on Wise Workout!'
        : 'I just finished a $t workout — $dur on Wise Workout!';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(saveWorkoutDetailsProvider).call(
          sessionId: widget.sessionId,
          customName: _name.text,
          feelRating: _feel,
          notes: _notes.text,
        );
    if (_share) {
      await ref.read(createWorkoutSharePostProvider).call(
            sessionId: widget.sessionId,
            caption: _caption.text,
          );
    }
    if (!mounted) return;
    Navigator.of(context).pop(); // back to the app shell (Train tab)
  }

  @override
  Widget build(BuildContext context) {
    final xp = widget.result['xp_gained'] ?? 0;
    final leveledUp = widget.result['leveled_up'] == true;
    final newLevel = widget.result['new_level'];
    final streak = widget.result['current_streak'] ?? 0;

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Workout complete')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.check_circle, color: AppColors.accent, size: 72),
          const SizedBox(height: 8),
          Center(child: Text('+$xp XP', style: AppTypography.title1.copyWith(color: AppColors.accent))),
          if (leveledUp)
            Center(child: Text('Level up! You reached level $newLevel 🎉', style: AppTypography.headline)),
          Center(child: Text('🔥 $streak-week streak', style: AppTypography.subheadline)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Stat(label: 'DURATION', value: fmtDuration(widget.elapsed)),
              if (widget.type.isCardio) ...[
                _Stat(label: 'DISTANCE', value: '${fmtKm(widget.distanceMeters)} km'),
                _Stat(label: 'AVG PACE', value: '${fmtPace(widget.distanceMeters, widget.elapsed)} /km'),
              ],
              _Stat(label: 'TYPE', value: widget.type.name),
            ],
          ),
          const SizedBox(height: 24),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'NAME THIS WORKOUT (OPTIONAL)')),
          const SizedBox(height: 16),
          Text('HOW DID IT FEEL?', style: AppTypography.caption2),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: FeelRating.values.map((f) {
              final selected = _feel == f;
              return ChoiceChip(
                label: Text(_feelLabel(f)),
                selected: selected,
                onSelected: (_) => setState(() => _feel = selected ? null : f),
                selectedColor: AppColors.accent,
                labelStyle: TextStyle(color: selected ? AppColors.bg : AppColors.ink),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'PRIVATE NOTES (OPTIONAL)'),
          ),
          const SizedBox(height: 16),
          // Share to Social — posts a workout_share to the feed (on save) and
          // offers named-platform external shares.
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Share to Social', style: AppTypography.headline),
            subtitle: Text('Posts to your feed', style: AppTypography.footnote),
            value: _share,
            activeThumbColor: AppColors.accent,
            onChanged: (v) => setState(() => _share = v),
          ),
          if (_share) ...[
            TextField(
              controller: _caption,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'DESCRIPTION (PUBLIC, OPTIONAL)'),
            ),
            const SizedBox(height: 12),
            Text('SHARE TO', style: AppTypography.caption2),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SocialPlatform.values
                  .map((p) => OutlinedButton(
                        onPressed: () =>
                            ref.read(shareWorkoutToSocialProvider).call(p, text: _shareText()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          side: const BorderSide(color: AppColors.faint),
                        ),
                        child: Text(p.label),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg))
                : const Text('SAVE & FINISH'),
          ),
        ],
      ),
    );
  }

  String _feelLabel(FeelRating f) => switch (f) {
        FeelRating.great => '🔥 Great',
        FeelRating.good => '💪 Good',
        FeelRating.okay => '😐 Okay',
        FeelRating.tough => '😣 Tough',
      };
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption2),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.title3),
        ],
      ),
    );
  }
}
