import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/authenticate.dart';
import '../../../controls/update_fitness_profile.dart';
import '../../../controls/view_profile.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/enums.dart';
import '../../../entities/fitness_profile.dart';
import '../../gateways/workout_gateway.dart';
import '../common/app_card.dart';
import 'profile_widgets.dart';

// (#) Fitness profile screen. Edit body metrics, activity level, training
// experience, preferred workouts and health tags. Changes are gathered locally
// and SAVE PROFILE pushes them all at once via the UpdateFitnessProfile control.
class FitnessProfileScreen extends ConsumerStatefulWidget {
  const FitnessProfileScreen({super.key});

  // (#) Creates the state holding the local draft of the profile.
  @override
  ConsumerState<FitnessProfileScreen> createState() => _FitnessProfileScreenState();
}

// (#) Local draft of the profile, seeded once from the loaded FitnessProfile.
class _FitnessProfileScreenState extends ConsumerState<FitnessProfileScreen> {
  bool _seeded = false; // (#) so we copy the loaded profile in only once
  DateTime? _dob; // (#) date of birth
  Sex? _sex; // (#) selected sex
  int? _heightCm; // (#) height in centimetres
  double? _weightKg; // (#) weight in kilograms
  ActivityLevel? _activity; // (#) day-to-day activity level
  TrainingExperience? _experience; // (#) beginner/intermediate/advanced
  Set<String> _healthTagIds = {}; // (#) picked diet/allergy/injury tag ids
  Set<String> _workoutTypeIds = {}; // (#) picked preferred workout type ids

  // (#) Copies the loaded profile into the draft fields, just the first time.
  void _seed(FitnessProfile fp) {
    if (_seeded) return;
    _seeded = true;
    _dob = fp.dateOfBirth;
    _sex = fp.sex;
    _heightCm = fp.heightCm;
    _weightKg = fp.weightKg;
    _activity = fp.activityLevel;
    _experience = fp.trainingExperience;
    _healthTagIds = {...fp.healthTagIds};
    _workoutTypeIds = {...fp.preferredWorkoutTypeIds};
  }

  // (#) Bundles the whole draft into a map and saves it through the control,
  // then snackbars and pops on success.
  Future<void> _save() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final ok = await ref.read(updateFitnessProfileProvider.notifier).save(userId, {
      'date_of_birth': _dob == null
          ? null
          : '${_dob!.year.toString().padLeft(4, '0')}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}',
      'sex': _sex?.name,
      'height_cm': _heightCm,
      'weight_kg': _weightKg,
      'activity_level': _activity?.name,
      'training_experience': _experience?.name,
      'health_tag_ids': _healthTagIds.toList(),
      'preferred_workout_type_ids': _workoutTypeIds.toList(),
    });
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Fitness profile saved.')));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not save. Please try again.')));
    }
  }

  // (#) Builds the screen: body-metric rows, activity picker, experience chips,
  // the workout and tag sections, and the save button.
  @override
  Widget build(BuildContext context) {
    final fitnessAsync = ref.watch(fitnessProfileProvider);
    final saving = ref.watch(updateFitnessProfileProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const Text('FITNESS PROFILE',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.ink)),
      ),
      body: fitnessAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Could not load fitness profile.', style: AppTypography.subheadline)),
        data: (fp) {
          if (fp == null) return const SizedBox.shrink();
          _seed(fp);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              const SectionLabel(label: 'Body Metrics'),
              SettingRow(
                label: 'Date of Birth',
                value: _dob == null
                    ? 'Not set'
                    : '${_dob!.day} ${monthName(_dob!.month)} ${_dob!.year} · ${FitnessProfile.ageFrom(_dob!, DateTime.now())} yrs',
                onTap: _pickDob,
              ),
              const Divider(color: AppColors.faint, height: 1),
              SettingRow(
                label: 'Sex',
                value: _sex == null ? 'Not set' : _sex!.name[0].toUpperCase() + _sex!.name.substring(1),
                onTap: _pickSex,
              ),
              const Divider(color: AppColors.faint, height: 1),
              SettingRow(
                label: 'Height',
                value: _heightCm == null ? 'Not set' : '$_heightCm cm',
                onTap: () => showNumberInputDialog(context,
                    title: 'Height',
                    unit: 'cm',
                    current: _heightCm?.toDouble(),
                    min: 100,
                    max: 250,
                    onSet: (v) => setState(() => _heightCm = v.round())),
              ),
              const Divider(color: AppColors.faint, height: 1),
              SettingRow(
                label: 'Weight',
                value: _weightKg == null ? 'Not set' : '${_weightKg!.toStringAsFixed(1)} kg',
                onTap: () => showNumberInputDialog(context,
                    title: 'Weight',
                    unit: 'kg',
                    current: _weightKg,
                    min: 30,
                    max: 250,
                    onSet: (v) => setState(() => _weightKg = v)),
              ),
              const SizedBox(height: 24),

              const SectionLabel(label: 'Activity Level'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickActivity,
                borderRadius: BorderRadius.circular(16),
                child: AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_activity?.label ?? 'Not set',
                                style: AppTypography.body
                                    .copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(_activity?.description ?? 'Tap to choose',
                                style: AppTypography.subheadline),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.muted),
                    ],
                  ),
                ),
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

              _workoutSection(),
              const SizedBox(height: 24),
              _tagSection('Diet', HealthTagKind.diet),
              const SizedBox(height: 24),
              _tagSection('Allergies', HealthTagKind.allergy),
              const SizedBox(height: 24),
              _tagSection('Injuries / Limitations', HealthTagKind.injury),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: saving ? null : _save,
                child: saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg))
                    : const Text('SAVE PROFILE'),
              ),
            ],
          );
        },
      ),
    );
  }

  // (#) The preferred-workouts block: default chips plus anything picked, with
  // a "+" that opens the full workout-type picker.
  Widget _workoutSection() {
    final types = ref.watch(workoutTypesProvider).value ?? [];
    final byId = {for (final t in types) t.id: t};
    // Show defaults + anything selected; full catalog lives in the picker.
    const defaultSlugs = {'running', 'strength', 'cycling'};
    final visible = types
        .where((t) => defaultSlugs.contains(t.slug) || _workoutTypeIds.contains(t.id))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          label: 'Preferred Workouts',
          onAction: () async {
            final userId = ref.read(currentUserIdProvider);
            final picked = await showTagPicker(
              context,
              title: 'Preferred Workouts',
              options: [
                for (final t in types)
                  PickerOption(id: t.id, label: t.name, isCustom: t.isCustom)
              ],
              selected: _workoutTypeIds,
              onAddCustom: userId == null
                  ? null
                  : (name) async {
                      final type = await ref
                          .read(updateFitnessProfileProvider.notifier)
                          .addCustomWorkoutType(userId: userId, name: name);
                      return type == null
                          ? null
                          : PickerOption(id: type.id, label: type.name, isCustom: true);
                    },
            );
            if (picked != null) setState(() => _workoutTypeIds = picked);
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in visible)
              SelectChip(
                label: byId[t.id]?.name ?? '',
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

  // (#) One health-tag block (diet, allergies or injuries) with chips and a
  // "+" that opens the tag picker for that kind.
  Widget _tagSection(String label, HealthTagKind kind) {
    final tags = (ref.watch(healthTagsProvider).value ?? [])
        .where((t) => t.kind == kind)
        .toList();
    // Show the first few catalog entries + anything selected.
    final visible = [
      ...tags.take(3),
      ...tags.skip(3).where((t) => _healthTagIds.contains(t.id)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          label: label,
          onAction: () async {
            final userId = ref.read(currentUserIdProvider);
            final picked = await showTagPicker(
              context,
              title: label,
              options: [
                for (final t in tags)
                  PickerOption(id: t.id, label: t.name, isCustom: t.isCustom)
              ],
              selected: _healthTagIds.intersection({for (final t in tags) t.id}),
              onAddCustom: userId == null
                  ? null
                  : (name) async {
                      final tag = await ref
                          .read(updateFitnessProfileProvider.notifier)
                          .addCustomTag(userId: userId, kind: kind, name: name);
                      return tag == null
                          ? null
                          : PickerOption(id: tag.id, label: tag.name, isCustom: true);
                    },
            );
            if (picked != null) {
              setState(() {
                // Replace only this kind's ids; keep other kinds' selections.
                _healthTagIds
                  ..removeWhere((id) => tags.any((t) => t.id == id))
                  ..addAll(picked);
              });
            }
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in visible)
              SelectChip(
                label: t.name,
                selected: _healthTagIds.contains(t.id),
                onTap: () => setState(() => _healthTagIds.contains(t.id)
                    ? _healthTagIds.remove(t.id)
                    : _healthTagIds.add(t.id)),
              ),
            if (tags.isEmpty)
              Text('No catalog entries yet.', style: AppTypography.footnote),
          ],
        ),
      ],
    );
  }


  // (#) Opens the date picker and stores the chosen date of birth.
  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  // (#) Opens a bottom sheet to pick sex and stores the choice.
  Future<void> _pickSex() async {
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
                trailing: _sex == s
                    ? const Icon(Icons.check, color: AppColors.accent)
                    : null,
                onTap: () => Navigator.of(ctx).pop(s),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _sex = picked);
  }

  // (#) Opens a bottom sheet listing activity levels and stores the pick.
  Future<void> _pickActivity() async {
    final picked = await showModalBottomSheet<ActivityLevel>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final a in ActivityLevel.values)
              ListTile(
                title: Text(a.label, style: AppTypography.body),
                subtitle: Text(a.description, style: AppTypography.footnote),
                trailing: _activity == a
                    ? const Icon(Icons.check, color: AppColors.accent)
                    : null,
                onTap: () => Navigator.of(ctx).pop(a),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _activity = picked);
  }

}
