import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/log_manual_workout.dart';
import '../../gateways/workout_gateway.dart';
import '../common/field_label.dart';
import '../common/selector_pills.dart';
import '../../../core/format.dart';
import '../../../core/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/enums.dart';
import '../../../entities/workout_type.dart';

/// BOUNDARY — Manual workout entry (US13). For sessions done without the
/// phone: pick a type, when, how long (+ distance for cardio), feel + notes,
/// and it lands in History like any tracked session (no source device;
/// XP/streak via the same RPC).
class ManualEntryScreen extends ConsumerStatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  WorkoutType? _type;
  late DateTime _date = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 18, minute: 0);
  final _duration = TextEditingController();
  final _distance = TextEditingController();
  FeelRating? _feel;
  final _notes = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _duration.dispose();
    _distance.dispose();
    _notes.dispose();
    super.dispose();
  }

  DateTime get _startedAt => DateTime(
      _date.year, _date.month, _date.day, _startTime.hour, _startTime.minute);

  bool get _valid =>
      _type != null &&
      (int.tryParse(_duration.text.trim()) ?? 0) > 0 &&
      !_startedAt.isAfter(DateTime.now());

  Future<void> _save() async {
    if (!_valid) return;
    setState(() => _busy = true);
    try {
      final km = double.tryParse(_distance.text.trim());
      final result = await ref.read(logManualWorkoutProvider).call(
            type: _type!,
            startedAt: _startedAt,
            duration: Duration(minutes: int.parse(_duration.text.trim())),
            distanceMeters: km == null ? null : (km * 1000).round(),
            feelRating: _feel,
            notes: _notes.text.isBlank ? null : _notes.text.trim(),
          );
      if (!mounted) return;
      Navigator.pop(context);
      final xp = result['xp_gained'];
      final levelled = result['leveled_up'] == true;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(levelled
              ? 'Workout logged — +$xp XP, level up! 🎉'
              : 'Workout logged — +$xp XP')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not log workout: $e')));
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _startTime);
    if (picked != null) setState(() => _startTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final types = ref.watch(workoutTypesProvider).value ?? const <WorkoutType>[];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
          title: const Text('LOG A WORKOUT', style: AppTypography.caption2),
          centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const FieldLabel('WORKOUT TYPE'),
          SelectorPills<WorkoutType>(
            values: types,
            selected: _type,
            labelOf: (t) => '${iconForSlug(t.slug)} ${t.name}',
            onTap: (t) => setState(() => _type = t),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('DATE'),
                    OutlinedButton(
                      onPressed: _pickDate,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        side: const BorderSide(color: AppColors.faint),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(relativeDay(_date),
                          style: AppTypography.footnote
                              .copyWith(color: AppColors.ink)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('START TIME'),
                    OutlinedButton(
                      onPressed: _pickTime,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        side: const BorderSide(color: AppColors.faint),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(_startTime.format(context),
                          style: AppTypography.footnote
                              .copyWith(color: AppColors.ink)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_startedAt.isAfter(DateTime.now())) ...[
            const SizedBox(height: 6),
            Text('Start time is in the future.',
                style: AppTypography.caption2
                    .copyWith(color: AppColors.danger)),
          ],
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('DURATION (MIN)'),
                    TextField(
                      controller: _duration,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(hintText: '45'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: (_type?.isCardio ?? false)
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FieldLabel('DISTANCE (KM)'),
                          TextField(
                            controller: _distance,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration:
                                const InputDecoration(hintText: 'Optional'),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const FieldLabel('HOW DID IT FEEL?'),
          SelectorPills<FeelRating>(
            values: FeelRating.values,
            selected: _feel,
            labelOf: _feelLabel,
            onTap: (f) => setState(() => _feel = _feel == f ? null : f),
          ),
          const SizedBox(height: 16),
          const FieldLabel('NOTES (PRIVATE)'),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(
                hintText: 'Only you can see these'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _busy || !_valid ? null : _save,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(_busy ? 'SAVING…' : 'LOG WORKOUT',
                style: const TextStyle(
                    fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('Manual entries earn XP and count toward your streak.',
                style: AppTypography.caption2),
          ),
        ],
      ),
    );
  }


  String _feelLabel(FeelRating f) => switch (f) {
        FeelRating.great => '🔥 Great',
        FeelRating.good => '💪 Good',
        FeelRating.okay => '🙂 Okay',
        FeelRating.tough => '😮‍💨 Tough',
      };
}
