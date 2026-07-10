import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/expert_requests.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../common/field_label.dart';

// (#) Pops open the composer bottom sheet where an expert types up a deliverable to send a client.
void showDeliverableComposer(BuildContext context, String requestId) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => _ComposerSheet(requestId: requestId),
  );
}

// (#) The sheet body itself. Holds the form and fires the SendDeliverable control when SEND is tapped.
class _ComposerSheet extends ConsumerStatefulWidget {
  const _ComposerSheet({required this.requestId});

  final String requestId; // (#) which request this deliverable belongs to
  // (#) Makes the state object that keeps the typed-in text.
  @override
  ConsumerState<_ComposerSheet> createState() => _ComposerSheetState();
}

// (#) Live state for the composer: the four text boxes plus a flag for the in-flight send.
class _ComposerSheetState extends ConsumerState<_ComposerSheet> {
  final _title = TextEditingController();   // (#) the deliverable title
  final _note = TextEditingController();    // (#) an optional note for the client
  final _heading = TextEditingController(); // (#) optional heading for the one section
  final _lines = TextEditingController();   // (#) section items, one per line
  bool _sending = false; // (#) true while the send is going out

  // (#) Cleans up the four text boxes when the sheet closes.
  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _heading.dispose();
    _lines.dispose();
    super.dispose();
  }

  // (#) Gathers the fields and asks SendDeliverable to send them, then closes the sheet if it worked.
  Future<void> _send() async {
    setState(() => _sending = true);
    final ok = await ref.read(sendDeliverableProvider).call(
          requestId: widget.requestId,
          title: _title.text,
          note: _note.text.trim().isEmpty ? null : _note.text,
          sectionHeading: _heading.text,
          sectionLines: _lines.text,
        );
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) Navigator.of(context).pop();
  }


  // (#) Lays out the sheet: heading, the title, note, section heading and items fields, and the SEND button.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SEND DELIVERABLE', style: AppTypography.caption2),
          const SizedBox(height: 14),
          const FieldLabel('TITLE (REQUIRED)'),
          TextField(
            controller: _title,
            onChanged: (_) => setState(() {}),
            decoration:
                const InputDecoration(hintText: 'e.g. Weeks 1–4 Training Block'),
          ),
          const SizedBox(height: 12),
          const FieldLabel('NOTE (OPTIONAL)'),
          TextField(
            controller: _note,
            decoration:
                const InputDecoration(hintText: 'A short note for your client'),
          ),
          const SizedBox(height: 12),
          const FieldLabel('SECTION HEADING (OPTIONAL)'),
          TextField(
            controller: _heading,
            decoration: const InputDecoration(hintText: 'e.g. Day A — Lower'),
          ),
          const SizedBox(height: 12),
          const FieldLabel('SECTION ITEMS'),
          TextField(
            controller: _lines,
            maxLines: 4,
            decoration: const InputDecoration(
                hintText: 'One item per line, e.g.\nBack squat 4x6'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _title.text.trim().isEmpty || _sending ? null : _send,
            child: _sending
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.bg))
                : const Text('SEND'),
          ),
        ],
      ),
    );
  }
}
