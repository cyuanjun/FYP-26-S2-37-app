import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/authenticate.dart';
import '../../../controls/generate_plan.dart';
import '../../../controls/set_fitness_goal.dart';
import '../../../controls/update_fitness_profile.dart';
import '../../../core/format.dart';
import '../../../core/seq_log.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/enums.dart';
import '../../../entities/fitness_goal.dart';
import '../../../entities/fitness_plan.dart';
import '../../gateways/workout_gateway.dart';
import '../profile/profile_widgets.dart';

/// BOUNDARY (#3 Onboarding, post-login). First-time wizard: profile basics →
/// training context → goal → AI/rule plan generation. The plan needs the
/// profile, which is why this flow exists before the main shell.
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final _page = PageController();
  int _step = 0;

  // Step 1 — body metrics
  DateTime? _dob;
  Sex? _sex;
  int? _heightCm;
  double? _weightKg;

  // Step 2 — training context
  ActivityLevel? _activity;
  TrainingExperience? _experience;
  final Set<String> _workoutTypeIds = {};

  // Step 3 — goal
  PrimaryGoal _goal = PrimaryGoal.maintainFitness;
  double? _target;
  int _weeklyDays = 3;
  int _timelineWeeks = 12;
  bool _goalTouched = false;

  // Step 4 — result
  FitnessPlan? _plan;
  String? _error;
  bool _generating = false;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _go(int step) {
    setState(() => _step = step);
    _page.animateToPage(step,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  bool get _step1Valid =>
      _dob != null && _sex != null && _heightCm != null && _weightKg != null;
  bool get _step2Valid => _activity != null && _experience != null;

  Future<void> _generate() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    setState(() {
      _generating = true;
      _error = null;
    });
    SeqLog.msg('onboarding', 'OnboardingFlow', 'UpsertFitnessProfile', 'save profile');
    final savedProfile =
        await ref.read(updateFitnessProfileProvider.notifier).save(userId, {
      'date_of_birth':
          '${_dob!.year.toString().padLeft(4, '0')}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}',
      'sex': _sex!.name,
      'height_cm': _heightCm,
      'weight_kg': _weightKg,
      'activity_level': _activity!.name,
      'training_experience': _experience!.name,
      'preferred_workout_type_ids': _workoutTypeIds.toList(),
    });
    final savedGoal = savedProfile &&
        await ref.read(setFitnessGoalProvider.notifier).save(
              userId: userId,
              primaryGoal: _goal,
              targetValue: _target,
              startingValue: _weightKg,
              timelineWeeks: _timelineWeeks,
              weeklyCommitmentDays: _weeklyDays,
            );
    final plan =
        savedGoal ? await ref.read(generatePlanProvider.notifier).generate() : null;
    if (!mounted) return;
    setState(() {
      _generating = false;
      if (plan != null) {
        _plan = plan;
      } else {
        _error = 'Could not generate your plan. Check your connection and try again.';
      }
    });
  }

  Future<void> _finish() async {
    await ref.read(completeOnboardingProvider).call();
    // currentProfileProvider invalidated by the control → HomeShell takes over.
  }

  @override
  Widget build(BuildContext context) {
    final firstName =
        ref.watch(currentProfileProvider).value?.firstName ?? 'there';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  for (var i = 0; i < 5; i++)
                    Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i <= _step ? AppColors.accent : AppColors.surface,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _welcome(firstName),
                  _bodyMetrics(),
                  _trainingContext(),
                  _goalStep(),
                  _planStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Step 0: welcome ----
  Widget _welcome(String firstName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('WELCOME,', style: AppTypography.title1.copyWith(color: AppColors.muted)),
          Text(firstName.toUpperCase(),
              style: const TextStyle(
                  fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.accent)),
          const SizedBox(height: 16),
          Text(
            "Let's set you up in two minutes:\n\n"
            '1.  A few details about you\n'
            '2.  How you like to train\n'
            '3.  Your goal\n\n'
            "Then we'll generate a weekly plan built around all of it.",
            style: AppTypography.body.copyWith(height: 1.4),
          ),
          const SizedBox(height: 32),
          ElevatedButton(onPressed: () => _go(1), child: const Text("LET'S GO")),
        ],
      ),
    );
  }

  // ---- Step 1: body metrics ----
  Widget _bodyMetrics() {
    return _stepShell(
      title: 'ABOUT YOU',
      subtitle: 'These calibrate calories, intensity, and your plan.',
      valid: _step1Valid,
      onNext: () => _go(2),
      onBack: () => _go(0),
      children: [
        SettingRow(
          label: 'Date of Birth',
          value: _dob == null
              ? 'Not set'
              : '${_dob!.day} ${monthName(_dob!.month)} ${_dob!.year}',
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _dob ?? DateTime(2000, 1, 1),
              firstDate: DateTime(1930),
              lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => _dob = picked);
          },
        ),
        const Divider(color: AppColors.faint, height: 1),
        SettingRow(
          label: 'Sex',
          value: _sex == null
              ? 'Not set'
              : _sex!.name[0].toUpperCase() + _sex!.name.substring(1),
          onTap: () async {
            final picked = await showModalBottomSheet<Sex>(
              context: context,
              backgroundColor: AppColors.surface,
              builder: (ctx) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final s in Sex.values)
                      ListTile(
                        title: Text(s.name[0].toUpperCase() + s.name.substring(1),
                            style: AppTypography.body),
                        onTap: () => Navigator.of(ctx).pop(s),
                      ),
                  ],
                ),
              ),
            );
            if (picked != null) setState(() => _sex = picked);
          },
        ),
        const Divider(color: AppColors.faint, height: 1),
        SettingRow(
          label: 'Height',
          value: _heightCm == null ? 'Not set' : '$_heightCm cm',
          onTap: () => _numberDialog('Height (cm)', _heightCm?.toDouble(), 100, 250,
              (v) => setState(() => _heightCm = v.round())),
        ),
        const Divider(color: AppColors.faint, height: 1),
        SettingRow(
          label: 'Weight',
          value: _weightKg == null ? 'Not set' : '${_weightKg!.toStringAsFixed(1)} kg',
          onTap: () => _numberDialog(
              'Weight (kg)', _weightKg, 30, 250, (v) => setState(() => _weightKg = v)),
        ),
      ],
    );
  }

  // ---- Step 2: training context ----
  Widget _trainingContext() {
    final types = ref.watch(workoutTypesProvider).value ?? [];
    return _stepShell(
      title: 'HOW YOU TRAIN',
      subtitle: 'Your plan adapts to your level and favourites.',
      valid: _step2Valid,
      onNext: () => _go(3),
      onBack: () => _go(1),
      children: [
        const SectionLabel(label: 'Activity Level'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final a in ActivityLevel.values)
              SelectChip(
                label: a.label,
                selected: _activity == a,
                onTap: () => setState(() => _activity = a),
              ),
          ],
        ),
        const SizedBox(height: 24),
        const SectionLabel(label: 'Training Experience'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final e in TrainingExperience.values)
              SelectChip(
                label: e.name[0].toUpperCase() + e.name.substring(1),
                selected: _experience == e,
                onTap: () => setState(() => _experience = e),
              ),
          ],
        ),
        const SizedBox(height: 24),
        const SectionLabel(label: 'Preferred Workouts (optional)'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in types)
              SelectChip(
                label: t.name,
                selected: _workoutTypeIds.contains(t.id),
                onTap: () => setState(() => _workoutTypeIds.contains(t.id)
                    ? _workoutTypeIds.remove(t.id)
                    : _workoutTypeIds.add(t.id)),
              ),
          ],
        ),
      ],
    );
  }

  // ---- Step 3: goal ----
  Widget _goalStep() {
    if (!_goalTouched) {
      _target = FitnessGoal.defaultTargetFor(_goal, currentWeightKg: _weightKg);
      _goalTouched = true;
    }
    final unit = FitnessGoal.unitFor(_goal);
    final hasTarget = _goal != PrimaryGoal.maintainFitness;
    return _stepShell(
      title: 'YOUR GOAL',
      subtitle: 'The plan is built to move you toward it.',
      valid: true,
      nextLabel: 'GENERATE MY PLAN',
      onNext: () {
        _go(4);
        _generate();
      },
      onBack: () => _go(2),
      children: [
        for (final g in PrimaryGoal.values) ...[
          InkWell(
            onTap: () => setState(() {
              _goal = g;
              _target = FitnessGoal.defaultTargetFor(g, currentWeightKg: _weightKg);
            }),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _goal == g ? AppColors.accent : AppColors.faint),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.label,
                            style:
                                AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
                        Text(g.descriptor, style: AppTypography.footnote),
                      ],
                    ),
                  ),
                  if (_goal == g)
                    const Icon(Icons.check_circle, color: AppColors.accent),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        if (hasTarget) ...[
          _miniStepper(
            label: unit == TargetUnit.minutes ? 'TARGET (MINS)' : 'TARGET (KG)',
            value: _target ?? 0,
            onMinus: () =>
                setState(() => _target = (_target ?? 0) - FitnessGoal.stepFor(unit!)),
            onPlus: () =>
                setState(() => _target = (_target ?? 0) + FitnessGoal.stepFor(unit!)),
          ),
          const SizedBox(height: 12),
        ],
        _miniStepper(
          label: 'DAYS PER WEEK',
          value: _weeklyDays.toDouble(),
          onMinus: () => setState(() => _weeklyDays = (_weeklyDays - 1).clamp(1, 7)),
          onPlus: () => setState(() => _weeklyDays = (_weeklyDays + 1).clamp(1, 7)),
        ),
        if (hasTarget) ...[
          const SizedBox(height: 16),
          const SectionLabel(label: 'Timeline (weeks)'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final w in FitnessGoal.timelineOptions)
                SelectChip(
                  label: '$w',
                  selected: _timelineWeeks == w,
                  onTap: () => setState(() => _timelineWeeks = w),
                ),
            ],
          ),
        ],
      ],
    );
  }

  // ---- Step 4: generating / result ----
  Widget _planStep() {
    final premium = ref.watch(currentProfileProvider).value?.isPremium ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_generating) ...[
            const Center(
                child: SizedBox(
                    height: 48,
                    width: 48,
                    child: CircularProgressIndicator(color: AppColors.accent))),
            const SizedBox(height: 24),
            Text(
              premium
                  ? 'Personalising your plan with AI…'
                  : 'Building your weekly plan…',
              textAlign: TextAlign.center,
              style: AppTypography.headline,
            ),
          ] else if (_plan != null) ...[
            const Icon(Icons.check_circle, size: 56, color: AppColors.accent),
            const SizedBox(height: 16),
            Text('YOUR PLAN IS READY',
                textAlign: TextAlign.center,
                style: AppTypography.title2.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_plan!.name,
                      style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(_plan!.description ?? '', style: AppTypography.subheadline),
                  const SizedBox(height: 8),
                  Text(
                    '${_plan!.workoutsPerWeek}x per week · ${_plan!.durationWeeks} weeks'
                    '${_plan!.isPersonalised ? ' · AI-assisted' : ' · rule-based'}',
                    style: AppTypography.caption2.copyWith(color: AppColors.accent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _finish, child: const Text('START TRAINING')),
          ] else ...[
            const Icon(Icons.error_outline, size: 56, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(_error ?? 'Something went wrong.',
                textAlign: TextAlign.center, style: AppTypography.subheadline),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _generate, child: const Text('TRY AGAIN')),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _finish,
              child: Text('Skip for now',
                  style: AppTypography.subheadline.copyWith(color: AppColors.muted)),
            ),
          ],
        ],
      ),
    );
  }

  // ---- shared bits ----
  Widget _stepShell({
    required String title,
    required String subtitle,
    required bool valid,
    required VoidCallback onNext,
    required VoidCallback onBack,
    String nextLabel = 'CONTINUE',
    required List<Widget> children,
  }) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.ink)),
              const SizedBox(height: 4),
              Text(subtitle, style: AppTypography.subheadline),
              const SizedBox(height: 20),
              ...children,
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Row(
            children: [
              TextButton(
                onPressed: onBack,
                child: Text('Back',
                    style: AppTypography.subheadline.copyWith(color: AppColors.muted)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: valid ? onNext : null,
                  child: Text(nextLabel),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniStepper({
    required String label,
    required double value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    final display =
        value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration:
          BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.caption2)),
          IconButton(onPressed: onMinus, icon: const Icon(Icons.remove, color: AppColors.ink)),
          Text(display, style: AppTypography.title3),
          IconButton(onPressed: onPlus, icon: const Icon(Icons.add, color: AppColors.ink)),
        ],
      ),
    );
  }

  Future<void> _numberDialog(String title, double? current, double min, double max,
      void Function(double) onSet) async {
    final ctl = TextEditingController(text: current?.toString() ?? '');
    final v = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: AppTypography.headline),
        content: TextField(
          controller: ctl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(isDense: true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(double.tryParse(ctl.text.trim())),
            child: const Text('Set'),
          ),
        ],
      ),
    );
    if (v != null && v >= min && v <= max) onSet(v);
  }
}
