import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/active_workout.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/workout_type.dart';
import '../../gateways/workout_gateway.dart';
import 'workout_summary_screen.dart';

/// BOUNDARY (#9 Active Workout). Free-form capture with a pre-start phase:
/// landing does NOT start the session — the user confirms/swaps the activity,
/// then taps START. Same layout pre-start and in-session (values switch on).
class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key, this.initialTypeId});

  /// Pre-selects the activity (e.g. "Start today's workout" from Plan Detail).
  final String? initialTypeId;

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  WorkoutType? _selected;
  bool _finishing = false;

  Future<void> _pickActivity(List<WorkoutType> types) async {
    final picked = await showModalBottomSheet<WorkoutType>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: types
              .map((t) => ListTile(
                    title: Text(t.name, style: AppTypography.body),
                    trailing: t.id == _selected?.id
                        ? const Icon(Icons.check, color: AppColors.accent)
                        : null,
                    onTap: () => Navigator.pop(context, t),
                  ))
              .toList(),
        ),
      ),
    );
    if (picked != null) setState(() => _selected = picked);
  }

  Future<void> _start() async {
    if (_selected == null) return;
    await ref.read(activeWorkoutProvider.notifier).start(_selected!);
  }

  Future<void> _confirmEnd() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('End workout?'),
        content: const Text('Save your session and see your stats.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save & Finish')),
        ],
      ),
    );
    if (ok == true) _finish();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    final s = ref.read(activeWorkoutProvider);
    final elapsed = s.elapsed;
    final distance = s.distanceMeters;
    final sessionId = s.sessionId;
    final type = s.type ?? _selected!;
    final result = await ref.read(activeWorkoutProvider.notifier).end();
    if (!mounted || sessionId == null) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => WorkoutSummaryScreen(
        sessionId: sessionId,
        type: type,
        elapsed: elapsed,
        distanceMeters: distance,
        result: result,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(workoutTypesProvider);
    final s = ref.watch(activeWorkoutProvider);
    final notifier = ref.read(activeWorkoutProvider.notifier);

    final preStart = s.status == WorkoutStatus.idle;
    final running = s.status == WorkoutStatus.running;

    return PopScope(
      canPop: preStart, // back gesture disabled mid-session
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              if (preStart) {
                Navigator.of(context).pop();
              } else {
                _confirmEnd();
              }
            },
          ),
          title: const Text('Free Workout', style: AppTypography.caption2),
          centerTitle: true,
        ),
        body: typesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load activities.\n$e', style: AppTypography.footnote)),
          data: (types) {
            _selected ??= types.firstWhere((t) => t.id == widget.initialTypeId,
                orElse: () => types.firstWhere((t) => t.slug == 'running',
                    orElse: () => types.first));
            // While recording, the type is locked to the session's type.
            final type = s.type ?? _selected;
            final cardio = type?.isCardio ?? false;
            final dim = preStart;
            final ink = dim ? AppColors.faint : AppColors.ink;

            return SafeArea(
              child: Column(
                children: [
                  const Spacer(),
                  Text('TIME', style: AppTypography.caption2),
                  Text(fmtDuration(s.elapsed),
                      style: TextStyle(fontSize: 64, fontWeight: FontWeight.w700, color: ink)),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: cardio
                          ? [
                              _Metric(label: 'DISTANCE', value: '${fmtKm(s.distanceMeters)} km', dim: dim),
                              _Metric(label: 'PACE', value: '${fmtPace(s.distanceMeters, s.elapsed)} /km', dim: dim),
                            ]
                          : [
                              _Metric(label: 'TIME', value: fmtDuration(s.elapsed), dim: dim),
                              _Metric(label: 'STEPS', value: '${s.steps}', dim: dim),
                            ],
                    ),
                  ),
                  // Live HR from the active wearable (#7.1; simulated stream).
                  if (s.heartRate != null) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('♥ ', style: TextStyle(color: AppColors.danger, fontSize: 18)),
                        Text('${s.heartRate} bpm',
                            style: AppTypography.title3.copyWith(color: AppColors.ink)),
                        if (s.wearableName != null)
                          Text('  ·  ${s.wearableName}', style: AppTypography.caption2),
                      ],
                    ),
                  ],
                  const Spacer(),
                  // Control row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Activity selector (free-form, pre-start only)
                        SizedBox(
                          width: 116,
                          child: preStart
                              ? OutlinedButton(
                                  onPressed: () => _pickActivity(types),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.ink,
                                    side: const BorderSide(color: AppColors.faint),
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    textStyle: AppTypography.footnote.copyWith(color: AppColors.ink),
                                  ),
                                  child: Text(type?.name ?? '—', overflow: TextOverflow.ellipsis, maxLines: 1),
                                )
                              : Text(type?.name.toUpperCase() ?? '',
                                  style: AppTypography.caption2),
                        ),
                        // Center: START / PAUSE / RESUME
                        GestureDetector(
                          onTap: _finishing
                              ? null
                              : (preStart
                                  ? _start
                                  : (running ? notifier.pause : notifier.resume)),
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                preStart ? 'START' : (running ? 'PAUSE' : 'RESUME'),
                                style: AppTypography.headline.copyWith(color: AppColors.bg),
                              ),
                            ),
                          ),
                        ),
                        // Right: END (in-session only)
                        SizedBox(
                          width: 116,
                          child: preStart
                              ? const SizedBox.shrink()
                              : Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: _finishing ? null : _confirmEnd,
                                    child: Container(
                                      width: 68,
                                      height: 68,
                                      decoration: const BoxDecoration(
                                        color: AppColors.danger,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: _finishing
                                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink))
                                            : Text('END', style: AppTypography.caption2.copyWith(color: AppColors.ink)),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    preStart ? 'TAP TO BEGIN' : (running ? 'TAP TO PAUSE' : 'TAP TO RESUME'),
                    style: AppTypography.caption2,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.dim = false});

  final String label;
  final String value;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: AppTypography.caption2),
          const SizedBox(height: 4),
          Text(value,
              style: AppTypography.title2.copyWith(color: dim ? AppColors.faint : AppColors.ink)),
        ],
      ),
    );
  }
}
