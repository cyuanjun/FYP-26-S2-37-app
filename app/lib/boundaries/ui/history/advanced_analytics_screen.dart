import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/view_profile.dart';
import '../../../controls/workout_history.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/advanced_analytics.dart';
import '../../../entities/workout_session.dart';
import '../common/app_card.dart';
import '../common/selector_pills.dart';
import '../common/status_badge.dart';

// (#) Advanced analytics screen for Premium members. Pulls the session history through a control and
// (#) charts trends: workload ratio, weekly volume, HR zones and all-time bests. The maths lives in the entity.
class AdvancedAnalyticsScreen extends ConsumerStatefulWidget {
  const AdvancedAnalyticsScreen({super.key});

  // (#) Makes the state that remembers the picked range and volume metric.
  @override
  ConsumerState<AdvancedAnalyticsScreen> createState() =>
      _AdvancedAnalyticsScreenState();
}

// (#) The time windows the charts can be scoped to, each with a label and a week count (null means all).
enum _Range {
  fourWeeks('4 wks', 4),
  threeMonths('3 mo', 13),
  oneYear('1 yr', 52),
  all('All', null);

  const _Range(this.label, this.weeks);
  final String label; // (#) short label shown on the pill
  final int? weeks; // (#) how many weeks back, null for all time
}

// (#) The three things the weekly volume chart can plot.
enum _VolumeMetric { sessions, minutes, calories }

// (#) Live state for the analytics screen: the current range and the current volume metric.
class _AdvancedAnalyticsScreenState
    extends ConsumerState<AdvancedAnalyticsScreen> {
  _Range _range = _Range.fourWeeks; // (#) currently selected time window
  _VolumeMetric _metric = _VolumeMetric.minutes; // (#) currently selected volume metric

  // (#) Reads the history, runs the analytics maths for the range, and lays out the ACWR tile and chart cards.
  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(historyProvider).value ?? const <WorkoutSession>[];
    final fitness = ref.watch(fitnessProfileProvider).value;
    final now = DateTime.now();
    final restingHr = fitness?.restingHeartRate;
    final age = fitness?.ageAt(now);

    final acwr = computeAcwr(sessions, now: now, restingHr: restingHr, age: age);
    final buckets = weeklyBuckets(sessions,
        now: now, weeks: _range.weeks, restingHr: restingHr, age: age);
    final inRange = sessions.where((s) {
      if (_range.weeks == null) return s.isEnded;
      return s.isEnded &&
          s.startedAt
              .toLocal()
              .isAfter(now.subtract(Duration(days: 7 * _range.weeks!)));
    }).toList();
    final zones = computeHrZones(inRange, restingHr: restingHr, age: age);
    final bests = computePersonalBests(sessions);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
          title:
              const Text('ADVANCED ANALYTICS', style: AppTypography.caption2),
          centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _acwrTile(acwr),
          const SizedBox(height: 20),
          SelectorPills<_Range>(
            values: _Range.values,
            selected: _range,
            labelOf: (r) => r.label,
            onTap: (r) => setState(() => _range = r),
          ),
          const SizedBox(height: 16),
          _card('WEEKLY VOLUME', [
            _metricToggle(),
            const SizedBox(height: 12),
            _barChart(
              buckets
                  .map((b) => switch (_metric) {
                        _VolumeMetric.sessions => b.sessions.toDouble(),
                        _VolumeMetric.minutes => b.activeMinutes.toDouble(),
                        _VolumeMetric.calories => b.calories.toDouble(),
                      })
                  .toList(),
              color: AppColors.accent,
            ),
            const SizedBox(height: 6),
            Text('Per week over the selected range.',
                style: AppTypography.caption2),
          ]),
          _card('HR EFFICIENCY', [
            _barChart(
              buckets.map((b) => b.avgHr ?? 0).toList(),
              color: const Color(0xFFE11D74),
            ),
            const SizedBox(height: 6),
            Text('Avg HR per week — lower at the same pace = fitter.',
                style: AppTypography.caption2),
          ]),
          _card('TRAINING LOAD', [
            _barChart(buckets.map((b) => b.load).toList(),
                color: AppColors.premium),
            const SizedBox(height: 6),
            Text(
                hasAcuteSpike(buckets)
                    ? 'Latest week jumped >50% over the prior week — an acute spike.'
                    : 'Weekly sum of session load (duration × HR intensity).',
                style: AppTypography.caption2.copyWith(
                    color: hasAcuteSpike(buckets)
                        ? AppColors.premiumText
                        : AppColors.muted)),
          ]),
          _card('HR ZONES', [
            _zonesBar(zones),
            const SizedBox(height: 10),
            for (var i = 0; i < 5; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, color: _zoneColors[i]),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(hrZoneLabels[i],
                            style: AppTypography.caption2)),
                    Text('${(zones[i] * 100).round()}%',
                        style: AppTypography.caption2
                            .copyWith(color: AppColors.ink)),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Text(
                'Karvonen %HRR from each session’s avg HR · resting '
                '${restingHr ?? defaultRestingHr} bpm · max ~${estimatedMaxHr(age)} bpm.',
                style: AppTypography.caption2),
          ]),
          _card('PERSONAL BESTS (ALL-TIME)', [
            _bestRow('Longest distance', bests.longestDistance),
            _bestRow('Fastest pace', bests.fastestPace),
            _bestRow('Longest session', bests.longestSession),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                      child: Text('Longest day streak',
                          style: AppTypography.footnote)),
                  Text(
                      bests.longestStreakDays == 0
                          ? '—'
                          : '${bests.longestStreakDays} day${bests.longestStreakDays == 1 ? '' : 's'}',
                      style: AppTypography.headline),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // ---- ACWR ----

  // (#) The headline card: the ACWR ratio, its band chip, and a note, or a hint when there isn't enough history.
  Widget _acwrTile(AcwrResult acwr) {
    return AppCard(
      borderColor: AppColors.faint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WORKLOAD RATIO (ACWR)', style: AppTypography.caption2),
          const SizedBox(height: 8),
          if (!acwr.hasEnoughHistory)
            Text(
                'Not enough training history yet — needs ~3 weeks of sessions to compute.',
                style: AppTypography.subheadline)
          else ...[
            Row(
              children: [
                Text(acwr.ratio!.toStringAsFixed(2),
                    style: AppTypography.title1
                        .copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(width: 12),
                _bandChip(acwr.band!),
              ],
            ),
            const SizedBox(height: 6),
            Text('Acute load (7d) ÷ chronic baseline (28d avg). '
                'Sweet spot is 0.8–1.3.',
                style: AppTypography.caption2),
          ],
        ],
      ),
    );
  }

  // (#) Colours the little band badge by how safe the workload ratio is.
  Widget _bandChip(AcwrBand band) => switch (band) {
        AcwrBand.detraining =>
          StatusBadge(band.label, borderColor: AppColors.faint),
        AcwrBand.sustainable => StatusBadge(band.label,
            bg: AppColors.successBright, fg: AppColors.ink),
        AcwrBand.highLoad =>
          StatusBadge(band.label, bg: AppColors.premium, fg: AppColors.ink),
        AcwrBand.overreaching =>
          StatusBadge(band.label, bg: AppColors.danger, fg: AppColors.bg),
      };

  // ---- Range + metric selectors ----



  // (#) The little Sessions/Minutes/Calories toggle above the weekly volume chart.
  Widget _metricToggle() {
    const labels = {
      _VolumeMetric.sessions: 'Sessions',
      _VolumeMetric.minutes: 'Minutes',
      _VolumeMetric.calories: 'Calories',
    };
    return Row(
      children: [
        for (final m in _VolumeMetric.values) ...[
          GestureDetector(
            onTap: () => setState(() => _metric = m),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _metric == m ? AppColors.surface2 : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(labels[m]!,
                  style: AppTypography.caption2.copyWith(
                      color:
                          _metric == m ? AppColors.ink : AppColors.muted,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ],
    );
  }

  // ---- Charts (lightweight bar rendering — no chart package) ----

  // (#) Draws a simple row of bars scaled to the biggest value, no chart package needed.
  Widget _barChart(List<double> values, {required Color color}) {
    final maxV =
        values.fold(0.0, (a, b) => a > b ? a : b).clamp(1.0, double.infinity);
    return SizedBox(
      height: 96,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final v in values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Container(
                  height: v <= 0 ? 3 : (v / maxV * 92).clamp(3.0, 92.0),
                  decoration: BoxDecoration(
                    color: v <= 0 ? AppColors.faint : color,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(3)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // (#) The five colours used for the HR zones, easy to hard.
  static const _zoneColors = [
    Color(0xFF38BDF8), // Z1 sky
    Color(0xFF10B981), // Z2 aerobic
    Color(0xFFFACC15), // Z3 tempo
    Color(0xFFFB923C), // Z4 threshold
    Color(0xFFEF4444), // Z5 VO2 max
  ];

  // (#) Draws the stacked HR-zone bar, each zone sized by its share, or a note if there's no HR data.
  Widget _zonesBar(List<double> zones) {
    final total = zones.fold(0.0, (a, b) => a + b);
    if (total == 0) {
      return Text('No HR data in this range.', style: AppTypography.subheadline);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 22,
        child: Row(
          children: [
            for (var i = 0; i < 5; i++)
              if (zones[i] > 0)
                Expanded(
                  flex: (zones[i] * 1000).round(),
                  child: Container(color: _zoneColors[i]),
                ),
          ],
        ),
      ),
    );
  }

  // ---- Personal bests ----

  // (#) A titled surface card that wraps a section's contents.
  Widget _card(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        borderColor: AppColors.faint,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.caption2),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  // (#) One personal best row: the label plus the value and when it happened, or a dash if there's none.
  Widget _bestRow(String label, PersonalBest? best) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.footnote)),
          if (best == null)
            Text('—', style: AppTypography.headline)
          else ...[
            Text(best.value, style: AppTypography.headline),
            const SizedBox(width: 8),
            Text(relativeDay(best.date), style: AppTypography.caption2),
          ],
        ],
      ),
    );
  }
}
