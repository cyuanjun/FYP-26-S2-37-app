import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/challenges.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/challenge.dart';
import '../../../entities/enums.dart';
import '../../gateways/workout_gateway.dart';
import '../profile/profile_widgets.dart';

const _icons = ['⚡', '🏃', '🚴', '🏊', '🏋️', '🧘', '🥊', '🧗', '🎯', '🏆'];

/// Create Challenge (#11) — full-screen sheet: visibility + metric-kind
/// toggles, icon picker, name/short-name/description, kind-filtered metric,
/// target (accumulator only), optional workout type, date range.
void showCreateChallengeSheet(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
      fullscreenDialog: true, builder: (_) => const _CreateChallengeScreen()));
}

class _CreateChallengeScreen extends ConsumerStatefulWidget {
  const _CreateChallengeScreen();

  @override
  ConsumerState<_CreateChallengeScreen> createState() =>
      _CreateChallengeScreenState();
}

class _CreateChallengeScreenState
    extends ConsumerState<_CreateChallengeScreen> {
  final _name = TextEditingController();
  final _shortName = TextEditingController();
  final _description = TextEditingController();
  final _target = TextEditingController();

  var _visibility = ChallengeVisibility.public;
  var _kind = ChallengeMetricKind.accumulator;
  var _metric = ChallengeMetric.totalSessions;
  String _icon = '⚡';
  String? _workoutTypeId;
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 14));
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _shortName.dispose();
    _description.dispose();
    _target.dispose();
    super.dispose();
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      _shortName.text.trim().isNotEmpty &&
      !_end.isBefore(_start) &&
      (_kind == ChallengeMetricKind.bestOf ||
          (int.tryParse(_target.text) ?? 0) > 0);

  Future<void> _submit() async {
    setState(() => _saving = true);
    final challenge = await ref.read(createChallengeProvider).call({
      'name': _name.text.trim(),
      'short_name': _shortName.text.trim().toUpperCase(),
      if (_description.text.trim().isNotEmpty)
        'description': _description.text.trim(),
      'icon': _icon,
      'visibility': _visibility == ChallengeVisibility.public
          ? 'public'
          : 'invite_only',
      'metric_kind':
          _kind == ChallengeMetricKind.accumulator ? 'accumulator' : 'best_of',
      'metric': switch (_metric) {
        ChallengeMetric.totalDistance => 'total_distance',
        ChallengeMetric.totalSessions => 'total_sessions',
        ChallengeMetric.totalCalories => 'total_calories',
        ChallengeMetric.activeDays => 'active_days',
        ChallengeMetric.fastestTime => 'fastest_time',
        ChallengeMetric.longestDistance => 'longest_distance',
        ChallengeMetric.mostCalories => 'most_calories',
      },
      if (_kind == ChallengeMetricKind.accumulator)
        'target_value': int.parse(_target.text),
      if (_workoutTypeId != null) 'workout_type_id': _workoutTypeId,
      'started_at': _start.toUtc().toIso8601String(),
      'ended_at': _end.toUtc().toIso8601String(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (challenge != null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final types = ref.watch(workoutTypesProvider).value ?? [];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
          title: const Text('CREATE CHALLENGE', style: AppTypography.caption2)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const SectionLabel(label: 'Type'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            SelectChip(
                label: 'Public',
                selected: _visibility == ChallengeVisibility.public,
                onTap: () =>
                    setState(() => _visibility = ChallengeVisibility.public)),
            SelectChip(
                label: 'Invite only',
                selected: _visibility == ChallengeVisibility.inviteOnly,
                onTap: () => setState(
                    () => _visibility = ChallengeVisibility.inviteOnly)),
          ]),
          const SizedBox(height: 16),
          Wrap(spacing: 8, children: [
            SelectChip(
                label: 'Race a target',
                selected: _kind == ChallengeMetricKind.accumulator,
                onTap: () => setState(() {
                      _kind = ChallengeMetricKind.accumulator;
                      _metric = Challenge.metricsFor(_kind).first;
                    })),
            SelectChip(
                label: 'Best single effort',
                selected: _kind == ChallengeMetricKind.bestOf,
                onTap: () => setState(() {
                      _kind = ChallengeMetricKind.bestOf;
                      _metric = Challenge.metricsFor(_kind).first;
                    })),
          ]),
          const SizedBox(height: 20),
          const SectionLabel(label: 'Icon'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final icon in _icons)
                GestureDetector(
                  onTap: () => setState(() => _icon = icon),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              _icon == icon ? AppColors.accent : AppColors.faint,
                          width: _icon == icon ? 1.5 : 1),
                    ),
                    child: Text(icon, style: const TextStyle(fontSize: 20)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
              controller: _name,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'NAME')),
          const SizedBox(height: 12),
          TextField(
              controller: _shortName,
              maxLength: 20,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                  labelText: 'SHORT NAME', counterText: '')),
          const SizedBox(height: 12),
          TextField(
              controller: _description,
              maxLines: 2,
              decoration:
                  const InputDecoration(labelText: 'DESCRIPTION (OPTIONAL)')),
          const SizedBox(height: 20),
          const SectionLabel(label: 'Metric'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final m in Challenge.metricsFor(_kind))
              SelectChip(
                  label: m.label,
                  selected: _metric == m,
                  onTap: () => setState(() => _metric = m)),
          ]),
          if (_kind == ChallengeMetricKind.accumulator) ...[
            const SizedBox(height: 12),
            TextField(
                controller: _target,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                    labelText: 'TARGET VALUE',
                    helperText:
                        'metres for distance · count for sessions/days · kcal')),
          ],
          const SizedBox(height: 20),
          const SectionLabel(label: 'Workout type (optional)'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            SelectChip(
                label: 'Any',
                selected: _workoutTypeId == null,
                onTap: () => setState(() => _workoutTypeId = null)),
            for (final t in types.where((t) => !t.isCustom))
              SelectChip(
                  label: t.name,
                  selected: _workoutTypeId == t.id,
                  onTap: () => setState(() => _workoutTypeId = t.id)),
          ]),
          const SizedBox(height: 20),
          const SectionLabel(label: 'Window'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _dateButton(isStart: true)),
            const SizedBox(width: 10),
            Expanded(child: _dateButton(isStart: false)),
          ]),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _valid && !_saving ? _submit : null,
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.bg))
                : const Text('CREATE CHALLENGE'),
          ),
        ],
      ),
    );
  }

  Widget _dateButton({required bool isStart}) {
    final value = isStart ? _start : _end;
    return OutlinedButton(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime.now().subtract(const Duration(days: 30)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          setState(() => isStart ? _start = picked : _end = picked);
        }
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.faint),
      ),
      child: Text(
          '${isStart ? 'Starts' : 'Ends'} ${value.day}/${value.month}',
          style: AppTypography.footnote),
    );
  }
}
