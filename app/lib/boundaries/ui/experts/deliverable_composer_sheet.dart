import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/expert_requests.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Deliverable composer (expert view) — deliberately simple: title, note,
/// and one optional section where each line becomes an item. Not the full
/// WorkoutSegment editor (approved trim).
void showDeliverableComposer(BuildContext context, String requestId) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => _ComposerSheet(requestId: requestId),
  );
}

class _ComposerSheet extends ConsumerStatefulWidget {
  const _ComposerSheet({required this.requestId});

  final String requestId;

  @override
  ConsumerState<_ComposerSheet> createState() => _ComposerSheetState();
}

class _ComposerSheetState extends ConsumerState<_ComposerSheet> {
  final _title = TextEditingController();
  final _note = TextEditingController();
  final _heading = TextEditingController();
  final _lines = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _heading.dispose();
    _lines.dispose();
    super.dispose();
  }

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

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: AppTypography.caption2),
      );

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
          _label('TITLE (REQUIRED)'),
          TextField(
            controller: _title,
            onChanged: (_) => setState(() {}),
            decoration:
                const InputDecoration(hintText: 'e.g. Weeks 1–4 Training Block'),
          ),
          const SizedBox(height: 12),
          _label('NOTE (OPTIONAL)'),
          TextField(
            controller: _note,
            decoration:
                const InputDecoration(hintText: 'A short note for your client'),
          ),
          const SizedBox(height: 12),
          _label('SECTION HEADING (OPTIONAL)'),
          TextField(
            controller: _heading,
            decoration: const InputDecoration(hintText: 'e.g. Day A — Lower'),
          ),
          const SizedBox(height: 12),
          _label('SECTION ITEMS'),
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
