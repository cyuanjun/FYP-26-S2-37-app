import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/workout_type.dart';
import '../../gateways/workout_gateway.dart';
import '../workout/active_workout_screen.dart';

/// BOUNDARY (#7 Train). Free-form capture: pick a discipline to start recording.
class TrainScreen extends ConsumerWidget {
  const TrainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final types = ref.watch(workoutTypesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Train')),
      body: types.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load workout types.\n$e', style: AppTypography.footnote)),
        data: (list) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('START A FREE-FORM WORKOUT', style: AppTypography.caption2),
            const SizedBox(height: 12),
            ...list.map((t) => _TypeTile(
                  type: t,
                  onTap: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => ActiveWorkoutScreen(type: t)),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({required this.type, required this.onTap});

  final WorkoutType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        title: Text(type.name, style: AppTypography.headline),
        subtitle: Text(type.isCardio ? 'Cardio · GPS distance & pace' : 'Strength / mobility',
            style: AppTypography.footnote),
        trailing: const Icon(Icons.play_circle_fill, color: AppColors.accent, size: 32),
      ),
    );
  }
}
