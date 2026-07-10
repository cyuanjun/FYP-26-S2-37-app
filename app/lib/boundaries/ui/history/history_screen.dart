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
import '../common/app_card.dart';
import '../common/premium_cta.dart';
import '../common/stat_tile.dart';
import '../common/workout_list_card.dart';
import '../common/status_badge.dart';
import '../premium/upgrade_screen.dart';
import 'advanced_analytics_screen.dart';
import '../workout/history_detail_screen.dart';

// (#) The three time buckets the basic analytics can show.
enum _Period { day, week, month }

// (#) Month names indexed 1 to 12, with a blank at slot 0 so the month number lines up.
const _monthNames = ['', 'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'];

// (#) History screen. Shows the basic Day/Week/Month analytics plus the list of past workouts grouped
// (#) by week, and an AI summary sheet. Free members hit the upgrade prompts here; it only talks to controls.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  // (#) Makes the state that keeps the picked period and the search text.
  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

// (#) Live state for the history screen: the current period pill and the search box.
class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  _Period _period = _Period.week; // (#) which analytics period is selected
  final _search = TextEditingController(); // (#) the Premium search text

  // (#) Frees the search box when the screen closes.
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // (#) Pushes the Premium upgrade screen.
  void _goUpgrade() => Navigator.of(context, rootNavigator: true)
      .push(MaterialPageRoute(builder: (_) => const UpgradeScreen()));

  // (#) Opens a bottom sheet that watches the SummariseProgress control and shows the AI summary text.
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

  // (#) Reads the history and lays out search, the analytics card, and the grouped workout list, with empty and cap states.
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
            final hiddenEarlier = ref.watch(earlierHistoryHiddenProvider).value ?? false;
            if (hiddenEarlier) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('No workouts in ${_monthNames[DateTime.now().month]} yet',
                          style: AppTypography.title3, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(
                        'Free history only covers the current month. Your earlier '
                        'workouts are still saved.',
                        style: AppTypography.subheadline,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.premium,
                          foregroundColor: AppColors.ink,
                        ),
                        onPressed: _goUpgrade,
                        child: const Text('Upgrade to Premium'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Center(
              child: Text('No workouts yet. Start one from Train.', style: AppTypography.subheadline),
            );
          }

          // Premium search narrows both the aggregates and the groups (#12).
          final query = _search.text;
          final visible = isPremium
              ? filterSessionsByQuery(sessions, typeById, query)
              : sessions;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(historyProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                if (isPremium) _searchField() else _searchLockedPill(),
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Row(
                    children: [
                      const Expanded(
                          child: Text('BASIC WORKOUT ANALYTICS',
                              style: AppTypography.caption2)),
                      if (isPremium)
                        GestureDetector(
                          onTap: () => Navigator.of(context,
                                  rootNavigator: true)
                              .push(MaterialPageRoute(
                                  builder: (_) =>
                                      const AdvancedAnalyticsScreen())),
                          child: Text('Advanced ›',
                              style: AppTypography.footnote.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                ),
                _analyticsCard(visible, isPremium),
                const SizedBox(height: 20),
                if (visible.isEmpty && query.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('No history matches "${query.trim()}".',
                          style: AppTypography.subheadline),
                    ),
                  )
                else
                  ..._buildGroups(visible, typeById),
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

  // ---- Search (Premium = live filter · Free = locked pill → #16) ----
  // (#) The live search box Premium members type into to filter their history.
  Widget _searchField() {
    return TextField(
      controller: _search,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Search history by name or type',
        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.muted),
        suffixIcon: _search.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18, color: AppColors.muted),
                onPressed: () => setState(_search.clear),
              ),
      ),
    );
  }

  // (#) The locked search pill Free members see, tapping it nudges them to upgrade.
  Widget _searchLockedPill() {
    return GestureDetector(
      onTap: _goUpgrade, // point-of-friction upsell (#12 spec)
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
            const StatusBadge('PREMIUM', bg: AppColors.premium, fg: AppColors.ink),
          ],
        ),
      ),
    );
  }

  // ---- Basic Workout Analytics card ----
  // (#) The stats card: period pills, this-window totals with deltas versus the prior window, and a Free upsell.
  Widget _analyticsCard(List<WorkoutSession> all, bool isPremium) {
    final now = DateTime.now();
    final (curWin, priorWin) = _windows(_period, now);
    final cur = _aggregate(all.where((s) => _inWindow(s, curWin)));
    final prior = _aggregate(all.where((s) => _inWindow(s, priorWin)));
    final hasPrior = prior.sessions > 0;

    const vs = {_Period.day: 'VS YESTERDAY', _Period.week: 'VS LAST WEEK', _Period.month: 'VS LAST MONTH'};

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // period pills
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _Period.values.map((p) {
              final sel = p == _period;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
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
          if (hasPrior) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(vs[_period]!, style: AppTypography.caption2),
            ),
          ],
          const SizedBox(height: 12),
          Row(children: [
            StatTile('SESSIONS', '${cur.sessions}', delta: hasPrior ? cur.sessions - prior.sessions : null),
            StatTile('ACTIVE MIN', '${cur.activeMin}', delta: hasPrior ? cur.activeMin - prior.activeMin : null),
            StatTile('CALORIES', '${cur.calories}', delta: hasPrior ? cur.calories - prior.calories : null),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            StatTile('AVG HR', cur.avgHr?.toString() ?? '—'),
            StatTile('MAX HR', cur.maxHr?.toString() ?? '—'),
            const Spacer(),
          ]),
          if (!isPremium) ...[
            const SizedBox(height: 16),
            PremiumCta('⚡ Unlock with Premium →',
                onTap: _goUpgrade,
                fullWidth: true,
                padding: const EdgeInsets.symmetric(vertical: 10)),
          ],
        ],
      ),
    );
  }

  // ---- Session list grouped by relative week ----
  // (#) Splits the sessions into This week, Last week and Earlier, then builds a header and cards for each group.
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
        widgets.add(WorkoutListCard(
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

  // (#) The banner reminding Free members their history only covers this month, with an upgrade button.
  Widget _capBanner(int visible) {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.premium.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.premium.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Free history covers ${_monthNames[now.month]} only.',
              textAlign: TextAlign.center,
              style: AppTypography.footnote.copyWith(color: AppColors.ink)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _goUpgrade,
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.premium,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('⚡ Upgrade for full history →',
                  style: AppTypography.footnote
                      .copyWith(color: AppColors.ink, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // ---- analytics helpers ----
  // (#) Works out the current and prior date ranges for the picked period.
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

  // (#) True when a session's end time falls inside the given range.
  bool _inWindow(WorkoutSession s, DateTimeRange w) {
    final when = (s.endedAt ?? s.startedAt).toLocal();
    return !when.isBefore(w.start) && when.isBefore(w.end);
  }

  // (#) Rolls up a set of sessions into totals: count, minutes, calories, and duration-weighted avg and max HR.
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

// (#) Small holder for one window's rolled-up numbers.
class _Agg {
  const _Agg(this.sessions, this.activeMin, this.calories, this.avgHr, this.maxHr);
  final int sessions, activeMin, calories; // (#) session count, active minutes and calories
  final int? avgHr, maxHr; // (#) average and max heart rate, null when there's no HR data
}
