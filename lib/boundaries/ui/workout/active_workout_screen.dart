import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/active_workout.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/workout_type.dart';
import 'workout_summary_screen.dart';

/// BOUNDARY (#9 Active Workout). Live timer + phone-sensor metrics; Pause/End.
class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key, required this.type});

  final WorkoutType type;

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activeWorkoutProvider.notifier).start(widget.type);
    });
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    final s = ref.read(activeWorkoutProvider);
    final elapsed = s.elapsed;
    final distance = s.distanceMeters;
    final sessionId = s.sessionId;
    final result = await ref.read(activeWorkoutProvider.notifier).end();
    if (!mounted || sessionId == null) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => WorkoutSummaryScreen(
        sessionId: sessionId,
        type: widget.type,
        elapsed: elapsed,
        distanceMeters: distance,
        result: result,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(activeWorkoutProvider);
    final notifier = ref.read(activeWorkoutProvider.notifier);
    final running = s.status == WorkoutStatus.running;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(widget.type.name)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Text('TIME', style: AppTypography.caption2),
              Text(fmtDuration(s.elapsed),
                  style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 32),
              Row(
                children: [
                  if (widget.type.isCardio) ...[
                    _Metric(label: 'DISTANCE', value: '${fmtKm(s.distanceMeters)} km'),
                    _Metric(label: 'PACE', value: '${fmtPace(s.distanceMeters, s.elapsed)} /km'),
                  ] else
                    _Metric(label: 'STEPS', value: '${s.steps}'),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: _finishing ? null : (running ? notifier.pause : notifier.resume),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      minimumSize: const Size(120, 56),
                    ),
                    child: Text(running ? 'PAUSE' : 'RESUME'),
                  ),
                  ElevatedButton(
                    onPressed: _finishing ? null : _finish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: AppColors.ink,
                      minimumSize: const Size(120, 56),
                    ),
                    child: _finishing
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink))
                        : const Text('END'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: AppTypography.caption2),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.title2),
        ],
      ),
    );
  }
}
