import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/authenticate.dart';
import '../../../controls/summarise_progress.dart';
import '../../../controls/workout_history.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/workout_session.dart';
import '../../../entities/workout_type.dart';
import '../../gateways/workout_gateway.dart';
import '../workout/history_detail_screen.dart';

enum _Period { day, week, month }

/// BOUNDARY (#12 History). Basic Workout Analytics (Day/Week/Month) + the
/// "View Workout History" list grouped by relative week. Matches TDM activity
/// diagram: History → analytics + history list → completed-workout details.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  _Period _period = _Period.week;

  void _soon(String what) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text('$what is a Premium feature (later sprint).')));

  void _showAiSummary() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Consumer(
          builder: (context, ref, _) {
            final summary = ref.watch(aiSummaryProvider);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.accent, size: 18),
                    const SizedBox(width: 8),
                    Text('AI PROGRESS SUMMARY', style: AppTypography.caption2),
                  ],
                ),
                const SizedBox(height: 16),
                summary.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text("Couldn't generate a summary right now. Please try again.",
                      style: AppTypography.body),
                  data: (s) => Text(s.text, style: AppTypography.body),
                ),
                const SizedBox(height: 16),
                Text('AI-assisted · for information only, not medical advice.',
                    style: AppTypography.footnote),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    final typesAsync = ref.watch(workoutTypesProvider);
    final isPremium = ref.watch(currentProfileProvider).value?.isPremium ?? false;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text('HISTORY', style: AppTypography.title1),
        actions: [
          IconButton(
            tooltip: 'AI summary',
            icon: const Icon(Icons.auto_awesome, color: AppColors.accent),
            onPressed: _showAiSummary,
          ),
        ],
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load history.\n$e', style: AppTypography.footnote)),
        data: (sessions) {
          final types = typesAsync.value ?? const <WorkoutType>[];
          final typeById = {for (final t in types) t.id: t};

          if (sessions.isEmpty) {
            return Center(
              child: Text('No workouts yet. Start one from Train.', style: AppTypography.subheadline),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(historyProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                if (!isPremium) _searchLockedPill(),
                const SizedBox(height: 12),
                _analyticsCard(sessions, isPremium),
                const SizedBox(height: 20),
                ..._buildGroups(sessions, typeById),
                if (!isPremium) ...[
                  const SizedBox(height: 12),
                  _capBanner(sessions.length),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ---- Search (Free = locked pill) ----
  Widget _searchLockedPill() {
    return GestureDetector(
      onTap: () => _soon('History search'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.faint),
        ),
        child: Row(
          children: [
            const Text('🔒 ', style: TextStyle(fontSize: 14)),
            Text('Search history', style: AppTypography.subheadline),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('PREMIUM', style: AppTypography.caption2.copyWith(color: AppColors.bg)),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Basic Workout Analytics card ----
  Widget _analyticsCard(List<WorkoutSession> all, bool isPremium) {
    final now = DateTime.now();
    final (curWin, priorWin) = _windows(_period, now);
    final cur = _aggregate(all.where((s) => _inWindow(s, curWin)));
    final prior = _aggregate(all.where((s) => _inWindow(s, priorWin)));
    final hasPrior = prior.sessions > 0;

    const labels = {_Period.day: 'Today', _Period.week: 'This week', _Period.month: 'This month'};
    const vs = {_Period.day: 'VS YESTERDAY', _Period.week: 'VS LAST WEEK', _Period.month: 'VS LAST MONTH'};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BASIC WORKOUT ANALYTICS', style: AppTypography.caption2),
          const SizedBox(height: 12),
          // period pills
          Row(
            children: _Period.values.map((p) {
              final sel = p == _period;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _period = p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.accent : AppColors.bg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? AppColors.accent : AppColors.faint),
                    ),
                    child: Text(
                      p.name[0].toUpperCase() + p.name.substring(1),
                      style: AppTypography.footnote.copyWith(color: sel ? AppColors.bg : AppColors.muted),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(labels[_period]!, style: AppTypography.headline),
              if (hasPrior) Text(vs[_period]!, style: AppTypography.caption2),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            _statTile('SESSIONS', '${cur.sessions}', hasPrior ? cur.sessions - prior.sessions : null),
            _statTile('ACTIVE MIN', '${cur.activeMin}', hasPrior ? cur.activeMin - prior.activeMin : null),
            _statTile('CALORIES', '${cur.calories}', hasPrior ? cur.calories - prior.calories : null),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _statTile('AVG HR', cur.avgHr?.toString() ?? '—', null),
            _statTile('MAX HR', cur.maxHr?.toString() ?? '—', null),
            const Spacer(),
          ]),
          if (!isPremium) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _soon('Advanced analytics'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accent),
                ),
                child: Text('⚡ Unlock with Premium →',
                    style: AppTypography.footnote.copyWith(color: AppColors.accent)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, int? delta) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption2),
          if (delta != null && delta != 0)
            Text('${delta > 0 ? '↑' : '↓'} ${delta.abs()}',
                style: AppTypography.caption2.copyWith(
                    color: delta > 0 ? AppColors.accent : AppColors.danger)),
          const SizedBox(height: 2),
          Text(value, style: AppTypography.title3),
        ],
      ),
    );
  }

  // ---- Session list grouped by relative week ----
  List<Widget> _buildGroups(List<WorkoutSession> sessions, Map<String, WorkoutType> typeById) {
    final now = DateTime.now();
    final thisWeek = startOfWeek(now);
    final lastWeek = thisWeek.subtract(const Duration(days: 7));

    final groups = <String, List<WorkoutSession>>{'THIS WEEK': [], 'LAST WEEK': [], 'EARLIER': []};
    for (final s in sessions) {
      final when = s.endedAt ?? s.startedAt;
      if (!when.isBefore(thisWeek)) {
        groups['THIS WEEK']!.add(s);
      } else if (!when.isBefore(lastWeek)) {
        groups['LAST WEEK']!.add(s);
      } else {
        groups['EARLIER']!.add(s);
      }
    }

    final widgets = <Widget>[];
    for (final entry in groups.entries) {
      if (entry.value.isEmpty) continue;
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Text(entry.key, style: AppTypography.caption2),
      ));
      for (final s in entry.value) {
        widgets.add(_WorkoutListCard(
          session: s,
          type: typeById[s.workoutTypeId],
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => HistoryDetailScreen(sessionId: s.id),
          )),
        ));
      }
    }
    return widgets;
  }

  Widget _capBanner(int visible) {
    final now = DateTime.now();
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Free history covers ${months[now.month]} only.',
              style: AppTypography.footnote.copyWith(color: AppColors.ink)),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _soon('Full history'),
            child: Text('⚡ Upgrade for full history →',
                style: AppTypography.footnote.copyWith(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  // ---- analytics helpers ----
  (DateTimeRange, DateTimeRange) _windows(_Period p, DateTime now) {
    switch (p) {
      case _Period.day:
        final start = DateTime(now.year, now.month, now.day);
        return (
          DateTimeRange(start: start, end: start.add(const Duration(days: 1))),
          DateTimeRange(start: start.subtract(const Duration(days: 1)), end: start),
        );
      case _Period.week:
        final start = startOfWeek(now);
        return (
          DateTimeRange(start: start, end: start.add(const Duration(days: 7))),
          DateTimeRange(start: start.subtract(const Duration(days: 7)), end: start),
        );
      case _Period.month:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 1);
        final pStart = DateTime(now.year, now.month - 1, 1);
        return (DateTimeRange(start: start, end: end), DateTimeRange(start: pStart, end: start));
    }
  }

  bool _inWindow(WorkoutSession s, DateTimeRange w) {
    final when = (s.endedAt ?? s.startedAt).toLocal();
    return !when.isBefore(w.start) && when.isBefore(w.end);
  }

  _Agg _aggregate(Iterable<WorkoutSession> s) {
    int sessions = 0, activeMin = 0, calories = 0, hrWeight = 0, hrDur = 0, maxHr = 0;
    bool anyHr = false, anyMax = false;
    for (final w in s) {
      sessions++;
      activeMin += (w.durationSeconds / 60).round();
      if (w.caloriesBurned != null) calories += w.caloriesBurned!;
      if (w.avgHeartRate != null && w.durationSeconds > 0) {
        hrWeight += w.avgHeartRate! * w.durationSeconds;
        hrDur += w.durationSeconds;
        anyHr = true;
      }
      if (w.maxHeartRate != null) {
        if (w.maxHeartRate! > maxHr) maxHr = w.maxHeartRate!;
        anyMax = true;
      }
    }
    return _Agg(sessions, activeMin, calories, anyHr ? (hrWeight / hrDur).round() : null,
        anyMax ? maxHr : null);
  }
}

class _Agg {
  const _Agg(this.sessions, this.activeMin, this.calories, this.avgHr, this.maxHr);
  final int sessions, activeMin, calories;
  final int? avgHr, maxHr;
}

class _WorkoutListCard extends StatelessWidget {
  const _WorkoutListCard({required this.session, required this.type, required this.onTap});

  final WorkoutSession session;
  final WorkoutType? type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = session.customName ?? type?.name ?? 'Workout';
    final cardio = type?.isCardio ?? false;
    final when = session.endedAt ?? session.startedAt;
    final mins = (session.durationSeconds / 60).round();

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
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
                  const Icon(Icons.chevron_right, color: AppColors.faint),
                ],
              ),
              const SizedBox(height: 4),
              Text('${relativeDay(when)} · $mins min', style: AppTypography.caption2),
              const Divider(color: AppColors.faint, height: 20),
              Row(
                children: cardio
                    ? [
                        _cell(fmtKm((session.distanceMeters ?? 0).toDouble()), 'KM'),
                        _cell(fmtPace((session.distanceMeters ?? 0).toDouble(),
                            Duration(seconds: session.durationSeconds)), '/KM'),
                        _cell(session.avgHeartRate?.toString() ?? '—', 'AVG HR'),
                      ]
                    : [
                        _cell(session.caloriesBurned?.toString() ?? '—', 'KCAL'),
                        _cell(session.avgHeartRate?.toString() ?? '—', 'AVG HR'),
                        _cell(session.maxHeartRate?.toString() ?? '—', 'MAX HR'),
                      ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(String value, String label) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTypography.headline),
            Text(label, style: AppTypography.caption2),
          ],
        ),
      );
}
