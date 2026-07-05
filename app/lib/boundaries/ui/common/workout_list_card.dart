import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/workout_session.dart';
import '../../../entities/workout_type.dart';
import 'stat_tile.dart';

/// Shared session card — glyph + name + date line + type-aware stats row.
/// Used by History's list and embedded inside Social's workout_share posts
/// (there with [onTap] null and [chevron] false, per the spec's no-nested-
/// anchors rule).
class WorkoutListCard extends StatelessWidget {
  const WorkoutListCard({
    super.key,
    required this.session,
    required this.type,
    this.onTap,
    this.chevron = true,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  final WorkoutSession session;
  final WorkoutType? type;
  final VoidCallback? onTap;
  final bool chevron;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final name = session.customName ?? type?.name ?? 'Workout';
    final cardio = type?.isCardio ?? false;
    final when = session.endedAt ?? session.startedAt;
    final mins = (session.durationSeconds / 60).round();

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Card(
        color: AppColors.surface,
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.faint),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(iconForSlug(type?.slug ?? ''), style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(name, style: AppTypography.headline, overflow: TextOverflow.ellipsis)),
                    if (chevron) const Icon(Icons.chevron_right, color: AppColors.faint),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${relativeDay(when)} · $mins min', style: AppTypography.caption2),
                const Divider(color: AppColors.faint, height: 20),
                Row(
                  children: cardio
                      ? [
                          _cell('KM', fmtKm((session.distanceMeters ?? 0).toDouble())),
                          _cell('/KM', fmtPace((session.distanceMeters ?? 0).toDouble(),
                              Duration(seconds: session.durationSeconds))),
                          _cell('AVG HR', session.avgHeartRate?.toString() ?? '—'),
                        ]
                      : [
                          _cell('KCAL', session.caloriesBurned?.toString() ?? '—'),
                          _cell('AVG HR', session.avgHeartRate?.toString() ?? '—'),
                          _cell('MAX HR', session.maxHeartRate?.toString() ?? '—'),
                        ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cell(String label, String value) => StatTile(label, value,
      valueFirst: true, valueStyle: AppTypography.headline, gap: 0);
}
