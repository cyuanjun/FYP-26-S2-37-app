import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../common/status_badge.dart';

/// Shared building blocks for the Profile cluster (#13.x): iOS grouped-settings
/// rows, section labels, chips, and the searchable multi-select picker sheet.

class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.label, this.onAction, this.actionIcon});

  final String label;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label.toUpperCase(),
            style: AppTypography.caption2.copyWith(letterSpacing: 1.5)),
        if (onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Icon(actionIcon ?? Icons.add, size: 18, color: AppColors.accent),
          ),
      ],
    );
  }
}

/// Label-above-value row with a chevron (#13.1 body metrics, #13.3 personal info).
class SettingRow extends StatelessWidget {
  const SettingRow({super.key, required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.headline),
                  const SizedBox(height: 2),
                  Text(value, style: AppTypography.subheadline),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

/// Emoji + label + chevron menu row (#13 menu list).
class MenuRow extends StatelessWidget {
  const MenuRow({super.key, required this.emoji, required this.label, required this.onTap});

  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: AppTypography.headline)),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class SelectChip extends StatelessWidget {
  const SelectChip({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.accent : AppColors.faint),
        ),
        child: Text(label,
            style: AppTypography.footnote.copyWith(
                color: selected ? AppColors.bg : AppColors.ink,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// Boxed numeric-entry dialog (height/weight etc.) — visible input field with
/// a unit suffix, used by Fitness Profile (#13.1) and Onboarding (#3).
Future<void> showNumberInputDialog(
  BuildContext context, {
  required String title,
  required String unit,
  double? current,
  required double min,
  required double max,
  required void Function(double) onSet,
}) async {
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
        style: AppTypography.title3,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.bg,
          hintText: '0',
          hintStyle: AppTypography.title3.copyWith(color: AppColors.faint),
          suffixText: unit,
          suffixStyle: AppTypography.subheadline,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.faint),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accent),
          ),
        ),
        onSubmitted: (_) => Navigator.of(ctx).pop(double.tryParse(ctl.text.trim())),
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

/// One pickable option in [showTagPicker].
class PickerOption {
  const PickerOption({required this.id, required this.label, this.isCustom = false});

  final String id;
  final String label;
  final bool isCustom;
}

/// Searchable multi-select sheet (#13.1 "+ More" pattern). Returns the updated
/// selection set, or null if dismissed. When [onAddCustom] is provided and the
/// query has no exact match, an `+ Add "X"` row appears at the top.
Future<Set<String>?> showTagPicker(
  BuildContext context, {
  required String title,
  required List<PickerOption> options,
  required Set<String> selected,
  Future<PickerOption?> Function(String name)? onAddCustom,
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetCtx) => _TagPickerSheet(
        title: title, options: options, initial: selected, onAddCustom: onAddCustom),
  );
}

class _TagPickerSheet extends StatefulWidget {
  const _TagPickerSheet(
      {required this.title, required this.options, required this.initial, this.onAddCustom});

  final String title;
  final List<PickerOption> options;
  final Set<String> initial;
  final Future<PickerOption?> Function(String name)? onAddCustom;

  @override
  State<_TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends State<_TagPickerSheet> {
  late final Set<String> _selected = {...widget.initial};
  late List<PickerOption> _options = [...widget.options];
  final _searchCtl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  List<PickerOption> get _visible {
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _options
        : _options.where((o) => o.label.toLowerCase().contains(q)).toList();
    // selected+custom > selected > custom > catalog (stable within tiers)
    int tier(PickerOption o) {
      final sel = _selected.contains(o.id);
      if (sel && o.isCustom) return 0;
      if (sel) return 1;
      if (o.isCustom) return 2;
      return 3;
    }

    final indexed = filtered.asMap().entries.toList()
      ..sort((a, b) {
        final t = tier(a.value).compareTo(tier(b.value));
        return t != 0 ? t : a.key.compareTo(b.key);
      });
    return indexed.map((e) => e.value).toList();
  }

  bool get _showAddCustom {
    final q = _query.trim();
    return widget.onAddCustom != null &&
        q.isNotEmpty &&
        !_options.any((o) => o.label.toLowerCase() == q.toLowerCase());
  }

  Future<void> _addCustom() async {
    final added = await widget.onAddCustom!(_query.trim());
    if (added == null) return;
    _searchCtl.clear();
    setState(() {
      _options = [..._options, added];
      _selected.add(added.id);
      _query = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.title.toUpperCase(),
                      style: AppTypography.caption2.copyWith(letterSpacing: 1.5)),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(_selected),
                    child: Text('DONE',
                        style: AppTypography.caption2
                            .copyWith(color: AppColors.accent, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _searchCtl,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(hintText: 'Search…', isDense: true),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  if (_showAddCustom)
                    ListTile(
                      leading: const Icon(Icons.add, color: AppColors.accent),
                      title: Text('Add "${_query.trim()}" as new',
                          style: AppTypography.body.copyWith(color: AppColors.accent)),
                      onTap: _addCustom,
                    ),
                  for (final o in _visible)
                    ListTile(
                      onTap: () => setState(() => _selected.contains(o.id)
                          ? _selected.remove(o.id)
                          : _selected.add(o.id)),
                      title: Row(
                        children: [
                          Flexible(child: Text(o.label, style: AppTypography.body)),
                          if (o.isCustom) ...[
                            const SizedBox(width: 8),
                            const StatusBadge('CUSTOM',
                                borderColor: AppColors.faint,
                                padding:
                                    EdgeInsets.symmetric(horizontal: 6, vertical: 2)),
                          ],
                        ],
                      ),
                      trailing: _selected.contains(o.id)
                          ? const Icon(Icons.check_circle, color: AppColors.accent)
                          : const Icon(Icons.circle_outlined, color: AppColors.faint),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
