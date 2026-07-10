import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/submit_feedback.dart';
import '../../../core/theme/app_buttons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/enums.dart';

// (#) The three feedback categories with their labels and hint text.
const _categories = <(FeedbackCategory, String, String)>[
  (FeedbackCategory.bug, 'Bug', 'Something is broken or behaving unexpectedly'),
  (FeedbackCategory.featureRequest, 'Feature request', "Idea for something new you'd like to see"),
  (FeedbackCategory.general, 'General', 'Praise, complaints, or anything else'),
];

// (#) Submit-feedback screen. Pick a category, write at least a few characters,
// tap submit and the SubmitFeedback control fires it off. Flips to a thank-you
// state once it's sent.
class SubmitFeedbackScreen extends ConsumerStatefulWidget {
  const SubmitFeedbackScreen({super.key});

  // (#) Creates the state holding the form and submitted flag.
  @override
  ConsumerState<SubmitFeedbackScreen> createState() => _SubmitFeedbackScreenState();
}

// (#) Live state: chosen category, the body text and whether it's been sent.
class _SubmitFeedbackScreenState extends ConsumerState<SubmitFeedbackScreen> {
  FeedbackCategory _category = FeedbackCategory.general; // (#) selected category, valid by default
  final _body = TextEditingController(); // (#) the feedback text the user types
  bool _submitted = false; // (#) true once submit succeeded, switches to success view

  // (#) Frees the body text controller when the screen closes.
  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  // (#) Placeholder hint for the body field, changes with the chosen category.
  String get _placeholder => switch (_category) {
        FeedbackCategory.bug => 'What happened? What did you expect?',
        FeedbackCategory.featureRequest => 'What would you like to see? How would it help you?',
        FeedbackCategory.general => "Tell us what's on your mind…",
      };

  // (#) How many more characters are needed before the body is long enough.
  int get _remaining => SubmitFeedback.minBodyLength - _body.text.trim().length;

  // (#) Sends the feedback via the control; shows success or an error snackbar.
  Future<void> _submit() async {
    final ok = await ref
        .read(submitFeedbackProvider.notifier)
        .submit(category: _category, body: _body.text);
    if (!mounted) return;
    if (ok) {
      setState(() => _submitted = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not submit. Please try again.')));
    }
  }

  // (#) Builds either the form or the success view depending on _submitted.
  @override
  Widget build(BuildContext context) {
    final sending = ref.watch(submitFeedbackProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text('SUBMIT FEEDBACK',
            style: AppTypography.caption2
                .copyWith(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 2)),
      ),
      body: _submitted ? _success() : _form(sending),
    );
  }

  // (#) Builds the form: intro, category tiles, body field, char counter and
  // the pinned submit button at the bottom.
  Widget _form(bool sending) {
    final valid = _remaining <= 0;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            children: [
              Text('Found a bug or have an idea for the app? Tell us — we read every submission.',
                  style: AppTypography.subheadline),
              const SizedBox(height: 16),
              for (final (cat, label, hint) in _categories) ...[
                GestureDetector(
                  onTap: () => setState(() => _category = cat),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _category == cat
                          ? AppColors.accent.withValues(alpha: 0.1)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppColors.cardShadow,
                      border: Border.all(
                          color: _category == cat ? AppColors.accent : AppColors.faint),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label.toUpperCase(),
                            style: AppTypography.caption1.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: _category == cat ? AppColors.accent : AppColors.ink)),
                        const SizedBox(height: 2),
                        Text(hint, style: AppTypography.caption2),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _body,
                maxLines: 8,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(hintText: _placeholder),
              ),
              const SizedBox(height: 6),
              Text(
                valid
                    ? '${_body.text.trim().length} characters'
                    : '$_remaining more character${_remaining == 1 ? '' : 's'} needed',
                style: AppTypography.caption2,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.faint))),
          child: SafeArea(
            top: false,
            child: ElevatedButton(
              onPressed: valid && !sending ? _submit : null,
              child: sending
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg))
                  : const Text('SUBMIT FEEDBACK'),
            ),
          ),
        ),
      ],
    );
  }

  // (#) Builds the thank-you view with buttons to submit another or go back.
  Widget _success() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.check_circle, size: 64, color: AppColors.success),
            const SizedBox(height: 16),
            Text('THANKS FOR YOUR FEEDBACK',
                textAlign: TextAlign.center,
                style: AppTypography.title2.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
              'We read every submission. Bugs go to the team for triage; ideas help shape what we build next.',
              textAlign: TextAlign.center,
              style: AppTypography.subheadline,
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: () => setState(() {
                _submitted = false;
                _body.clear();
                _category = FeedbackCategory.general;
              }),
              style: AppButtonStyles.outlinedAccent(height: 52),
              child: const Text('SUBMIT ANOTHER'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('BACK TO PROFILE'),
            ),
          ],
        ),
      ),
    );
  }
}
