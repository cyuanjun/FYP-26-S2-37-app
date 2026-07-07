import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/save_workout_details.dart';
import '../../../controls/social_feed.dart';
import '../../../controls/workout_history.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_buttons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/enums.dart';
import '../../../entities/workout_session.dart';
import '../../gateways/workout_gateway.dart';
import '../common/stat_tile.dart';
import '../common/training_effect_card.dart';
import '../social/post_detail_screen.dart';
import '../common/status_badge.dart';

/// BOUNDARY (#12.1 History Detail). Read-only recap of a completed session with
/// an edit mode (name / feel / notes) and a delete action. Matches the activity
/// diagram: View Completed Workout Details → Update / Delete.
class HistoryDetailScreen extends ConsumerStatefulWidget {
  const HistoryDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends ConsumerState<HistoryDetailScreen> {
  bool _editing = false;
  bool _busy = false;
  final _name = TextEditingController();
  final _notes = TextEditingController();
  FeelRating? _feel;
  bool _seeded = false;

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _seed(WorkoutSession s) {
    if (_seeded) return;
    _name.text = s.customName ?? '';
    _notes.text = s.notes ?? '';
    _feel = s.feelRating;
    _seeded = true;
  }

  Future<void> _saveAndExitEdit() async {
    setState(() => _busy = true);
    await ref.read(saveWorkoutDetailsProvider).call(
          sessionId: widget.sessionId,
          customName: _name.text,
          feelRating: _feel,
          notes: _notes.text,
        );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _editing = false;
    });
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete this session?'),
        content: const Text("Stats, exercises, and notes will be removed. This can't be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(deleteWorkoutSessionProvider).call(widget.sessionId);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    final types = ref.watch(workoutTypesProvider).value ?? [];
    final session = history.value?.where((s) => s.id == widget.sessionId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('WORKOUT', style: AppTypography.caption2),
            if (_editing) ...[
              const SizedBox(width: 8),
              StatusBadge('EDITING',
                  bg: AppColors.muted.withValues(alpha: 0.15),
                  borderColor: AppColors.muted),
            ],
          ],
        ),
        actions: [
          if (session != null)
            TextButton(
              onPressed: _busy ? null : () => _editing ? _saveAndExitEdit() : setState(() => _editing = true),
              child: Text(_editing ? 'Done' : 'Edit',
                  style: AppTypography.body.copyWith(color: AppColors.accent)),
            ),
        ],
      ),
      body: session == null
          ? const Center(child: CircularProgressIndicator())
          : _body(session, {for (final t in types) t.id: t}),
    );
  }

  Widget _body(WorkoutSession s, Map<String, dynamic> typeById) {
    _seed(s);
    final type = typeById[s.workoutTypeId];
    final cardio = type?.isCardio ?? false;
    final name = (s.customName?.isNotEmpty ?? false) ? s.customName! : (type?.name ?? 'Workout');
    final when = s.endedAt ?? s.startedAt;
    final dur = Duration(seconds: s.durationSeconds);
    final freeform = s.plannedWorkoutId == null;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Name
        if (_editing)
          _editField('WORKOUT NAME', _name, hint: type?.name ?? 'Workout')
        else
          Text(name, style: AppTypography.title1),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('${relativeDay(when)} · ${(s.durationSeconds / 60).round()} min',
                style: AppTypography.caption2),
            if (freeform)
              Text('  · Freeform', style: AppTypography.caption2.copyWith(color: AppColors.muted)),
          ],
        ),
        const SizedBox(height: 20),
        // Stats grid (type-aware)
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _stat('DURATION', fmtDuration(dur)),
            if (cardio) ...[
              _stat('DISTANCE', '${fmtKm((s.distanceMeters ?? 0).toDouble())} km'),
              _stat('AVG PACE', '${fmtPace((s.distanceMeters ?? 0).toDouble(), dur)} /km'),
            ],
            _stat('CALORIES', s.caloriesBurned?.toString() ?? '—'),
            _stat('AVG HR', s.avgHeartRate?.toString() ?? '—'),
            _stat('MAX HR', s.maxHeartRate?.toString() ?? '—'),
          ],
        ),
        const SizedBox(height: 24),
        // Training Effect — shared card; dimmed while editing (spec: locked).
        Opacity(
          opacity: _editing ? 0.5 : 1,
          child: TrainingEffectCard(session: s),
        ),
        const SizedBox(height: 24),
        // Feel
        Text(_editing ? '✏ HOW IT FELT' : 'HOW IT FELT',
            style: AppTypography.caption2.copyWith(color: AppColors.muted)),
        const SizedBox(height: 8),
        if (_editing)
          Wrap(
            spacing: 8,
            children: FeelRating.values.map((f) {
              final sel = _feel == f;
              return ChoiceChip(
                label: Text(_feelLabel(f)),
                selected: sel,
                onSelected: (_) => setState(() => _feel = sel ? null : f),
                selectedColor: AppColors.accent,
                labelStyle: TextStyle(color: sel ? AppColors.bg : AppColors.ink),
              );
            }).toList(),
          )
        else
          Text(s.feelRating != null ? _feelLabel(s.feelRating!) : 'Not recorded',
              style: AppTypography.body),
        const SizedBox(height: 24),
        // Notes (private)
        Text(_editing ? '✏ NOTES (private)' : 'NOTES (private)',
            style: AppTypography.caption2.copyWith(color: AppColors.muted)),
        const SizedBox(height: 8),
        if (_editing)
          TextField(controller: _notes, maxLines: 3, decoration: const InputDecoration(hintText: 'Private notes'))
        else
          Text((s.notes?.isNotEmpty ?? false) ? s.notes! : '—', style: AppTypography.body),
        const SizedBox(height: 24),
        // Shared to the feed? Link the session to its post's likes/comments.
        if (!_editing)
          Consumer(builder: (context, ref, _) {
            final postId =
                ref.watch(sessionSharePostProvider(s.id)).value;
            if (postId == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context, rootNavigator: true)
                    .push(MaterialPageRoute(
                        builder: (_) => PostDetailScreen(postId: postId))),
                style: AppButtonStyles.outlinedAccent(height: 48, radius: 12),
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('VIEW SHARED POST'),
              ),
            );
          }),
        const SizedBox(height: 8),
        if (_editing)
          OutlinedButton(
            onPressed: _busy ? null : _delete,
            style: AppButtonStyles.outlinedDanger(height: 52),
            child: const Text('DELETE SESSION'),
          ),
      ],
    );
  }

  Widget _editField(String label, TextEditingController c, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('✏ $label', style: AppTypography.caption2.copyWith(color: AppColors.muted)),
        const SizedBox(height: 6),
        TextField(controller: c, decoration: InputDecoration(hintText: hint)),
      ],
    );
  }

  Widget _stat(String label, String value) => StatTile(label, value, boxed: true);

  String _feelLabel(FeelRating f) => switch (f) {
        FeelRating.great => '🔥 Great',
        FeelRating.good => '💪 Good',
        FeelRating.okay => '😐 Okay',
        FeelRating.tough => '😣 Tough',
      };
}
