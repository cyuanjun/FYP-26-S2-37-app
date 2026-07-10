import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/publish_service.dart';
import '../../../core/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/expert_profile.dart';
import '../common/field_label.dart';

// (#) Form where the expert edits their public info: title, years, about, credentials and specialties.
// (#) Tapping save hands it to the UpdateExpertProfile control. Stats and verification aren't editable here.
class ProfessionalInfoScreen extends ConsumerStatefulWidget {
  const ProfessionalInfoScreen({super.key, required this.profile});

  final ExpertProfile profile; // (#) the expert's current profile to prefill the form

  // (#) Makes the state that holds the editable text boxes.
  @override
  ConsumerState<ProfessionalInfoScreen> createState() =>
      _ProfessionalInfoScreenState();
}

// (#) Live state for the editor: the five text boxes prefilled from the profile, plus a saving flag.
class _ProfessionalInfoScreenState
    extends ConsumerState<ProfessionalInfoScreen> {
  late final _title = TextEditingController(text: widget.profile.title); // (#) professional title
  late final _years =
      TextEditingController(text: widget.profile.yearsCoaching.toString()); // (#) years coaching
  late final _about = TextEditingController(text: widget.profile.about); // (#) the about blurb
  late final _credentials =
      TextEditingController(text: widget.profile.credentials.join('\n')); // (#) credentials, one per line
  late final _specialties =
      TextEditingController(text: widget.profile.specialties.join(', ')); // (#) specialties, comma separated
  bool _busy = false; // (#) true while the save is running

  // (#) Frees the five text boxes when the screen closes.
  @override
  void dispose() {
    _title.dispose();
    _years.dispose();
    _about.dispose();
    _credentials.dispose();
    _specialties.dispose();
    super.dispose();
  }

  // (#) True when the title isn't blank and years is a real number, so save can be enabled.
  bool get _valid =>
      _title.text.isNotBlank && int.tryParse(_years.text.trim()) != null;

  // (#) Splits the fields into lists and calls UpdateExpertProfile, then pops with a snackbar or shows the error.
  Future<void> _save() async {
    if (!_valid) return;
    setState(() => _busy = true);
    try {
      await ref.read(updateExpertProfileProvider).call(
            title: _title.text,
            yearsCoaching: int.parse(_years.text.trim()),
            about: _about.text,
            credentials: _credentials.text
                .split('\n')
                .map((l) => l.trim())
                .where((l) => l.isNotEmpty)
                .toList(),
            specialties: _specialties.text
                .split(',')
                .map((s) => s.trim().toLowerCase())
                .where((s) => s.isNotEmpty)
                .toList(),
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Professional info updated.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save: $e')));
    }
  }

  // (#) Lays out the form: title, years, about, credentials and specialties fields plus the SAVE button.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
          title: const Text('PROFESSIONAL INFO', style: AppTypography.caption2),
          centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const FieldLabel('PROFESSIONAL TITLE'),
          TextField(
            controller: _title,
            onChanged: (_) => setState(() {}),
            decoration:
                const InputDecoration(hintText: 'e.g. Strength Coach'),
          ),
          const SizedBox(height: 16),
          const FieldLabel('YEARS COACHING'),
          TextField(
            controller: _years,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: '9'),
          ),
          const SizedBox(height: 16),
          const FieldLabel('ABOUT'),
          TextField(
            controller: _about,
            maxLines: 5,
            decoration: const InputDecoration(
                hintText: 'What clients should know about how you coach'),
          ),
          const SizedBox(height: 16),
          const FieldLabel('CREDENTIALS (ONE PER LINE)'),
          TextField(
            controller: _credentials,
            maxLines: 4,
            decoration: const InputDecoration(
                hintText: 'NASM CPT\nBSc Exercise Science'),
          ),
          const SizedBox(height: 16),
          const FieldLabel('SPECIALTIES (COMMA-SEPARATED)'),
          TextField(
            controller: _specialties,
            decoration:
                const InputDecoration(hintText: 'strength, mobility'),
          ),
          const SizedBox(height: 8),
          Text(
              'Rating, reviews, clients, earnings and verification are '
              'system-managed and cannot be edited.',
              style: AppTypography.caption2),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _busy || !_valid ? null : _save,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(_busy ? 'SAVING…' : 'SAVE',
                style: const TextStyle(
                    fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          ),
        ],
      ),
    );
  }

}
