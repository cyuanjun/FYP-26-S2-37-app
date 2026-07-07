import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/authenticate.dart';
import '../../../controls/browse_experts.dart';
import '../../../controls/publish_service.dart';
import '../../../core/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/enums.dart';
import '../../../entities/expert_service.dart';

/// BOUNDARY (#21.2 Create / Edit Service). The expert's listing editor —
/// create when [existing] is null, edit otherwise. Status (draft / live /
/// archived) is part of the form; saving live publishes straight to the
/// client marketplace (#6).
class ServiceEditorScreen extends ConsumerStatefulWidget {
  const ServiceEditorScreen({super.key, this.existing});

  final ExpertService? existing;

  @override
  ConsumerState<ServiceEditorScreen> createState() =>
      _ServiceEditorScreenState();
}

class _ServiceEditorScreenState extends ConsumerState<ServiceEditorScreen> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _description =
      TextEditingController(text: widget.existing?.description ?? '');
  late final _price = TextEditingController(
      text: widget.existing == null
          ? ''
          : (widget.existing!.priceCents / 100).toStringAsFixed(
              widget.existing!.priceCents % 100 == 0 ? 0 : 2));
  late final _durationWeeks = TextEditingController(
      text: widget.existing?.durationWeeks?.toString() ?? '');
  late final _bullets =
      TextEditingController(text: (widget.existing?.detailBullets ?? []).join('\n'));

  late String? _category = widget.existing?.category;
  late FulfillmentType _fulfillment =
      widget.existing?.fulfillment ?? FulfillmentType.coaching;
  late PricingModel _pricingModel =
      widget.existing?.pricingModel ?? PricingModel.oneTime;
  late ResponseTime _responseTime =
      widget.existing?.responseTime ?? ResponseTime.h48;
  late ServiceStatus _status = widget.existing?.status ?? ServiceStatus.live;
  late bool _acceptingBookings = widget.existing?.acceptingBookings ?? true;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _durationWeeks.dispose();
    _bullets.dispose();
    super.dispose();
  }

  bool get _valid =>
      _name.text.isNotBlank &&
      _category != null &&
      (double.tryParse(_price.text.trim()) ?? -1) >= 0;

  Future<void> _save() async {
    final me = ref.read(currentUserIdProvider);
    if (me == null || !_valid) return;
    setState(() => _busy = true);
    try {
      final priceCents = (double.parse(_price.text.trim()) * 100).round();
      final service = ExpertService(
        id: widget.existing?.id ?? '',
        expertUserId: me,
        status: _status,
        name: _name.text.trim(),
        description:
            _description.text.isBlank ? null : _description.text.trim(),
        detailBullets: _bullets.text
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList(),
        category: _category!,
        fulfillment: _fulfillment,
        pricingModel: _pricingModel,
        priceCents: priceCents,
        durationWeeks: int.tryParse(_durationWeeks.text.trim()),
        acceptingBookings: _acceptingBookings,
        responseTime: _responseTime,
      );
      await ref.read(publishServiceProvider).call(service);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_status == ServiceStatus.live
              ? 'Service is live in the marketplace.'
              : 'Service saved.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(expertCategoriesProvider).value ?? [];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
          title: Text(widget.existing == null ? 'NEW SERVICE' : 'EDIT SERVICE',
              style: AppTypography.caption2),
          centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _label('SERVICE NAME'),
          TextField(
            controller: _name,
            onChanged: (_) => setState(() {}),
            decoration:
                const InputDecoration(hintText: 'e.g. 12-Week Strength Block'),
          ),
          const SizedBox(height: 16),
          _label('DESCRIPTION'),
          TextField(
            controller: _description,
            maxLines: 3,
            decoration: const InputDecoration(
                hintText: 'One or two sentences clients see on the listing'),
          ),
          const SizedBox(height: 16),
          _label('CATEGORY'),
          DropdownButtonFormField<String>(
            initialValue: _category,
            hint: const Text('Choose a category'),
            style: AppTypography.body,
            dropdownColor: AppColors.surface,
            items: [
              for (final c in categories.where((c) => c.isActive))
                DropdownMenuItem(
                    value: c.id,
                    child: Text(c.label, style: AppTypography.body)),
            ],
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 16),
          _label('WHAT THE CLIENT GETS (FULFILLMENT)'),
          DropdownButtonFormField<FulfillmentType>(
            initialValue: _fulfillment,
            style: AppTypography.body,
            dropdownColor: AppColors.surface,
            items: [
              for (final f in FulfillmentType.values)
                DropdownMenuItem(
                    value: f, child: Text(f.label, style: AppTypography.body)),
            ],
            onChanged: (v) =>
                setState(() => _fulfillment = v ?? _fulfillment),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('PRICE (USD)'),
                    TextField(
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(hintText: '80'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('DURATION (WEEKS)'),
                    TextField(
                      controller: _durationWeeks,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(hintText: 'Optional'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _label('BILLING'),
          _pills<PricingModel>(
            values: PricingModel.values,
            selected: _pricingModel,
            labelOf: (m) => m == PricingModel.oneTime ? 'One-time' : 'Monthly',
            onTap: (m) => setState(() => _pricingModel = m),
          ),
          const SizedBox(height: 16),
          _label('RESPONSE TIME'),
          _pills<ResponseTime>(
            values: ResponseTime.values,
            selected: _responseTime,
            labelOf: (r) => r.dbValue,
            onTap: (r) => setState(() => _responseTime = r),
          ),
          const SizedBox(height: 16),
          _label("WHAT'S INCLUDED (ONE PER LINE)"),
          TextField(
            controller: _bullets,
            maxLines: 4,
            decoration: const InputDecoration(
                hintText: 'Weekly programming\nForm reviews\nChat support'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: Text('Accepting new bookings',
                      style: AppTypography.subheadline
                          .copyWith(color: AppColors.ink))),
              Switch(
                value: _acceptingBookings,
                activeThumbColor: AppColors.bg,
                activeTrackColor: AppColors.accent,
                onChanged: (v) => setState(() => _acceptingBookings = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _label('LISTING STATUS'),
          _pills<ServiceStatus>(
            values: widget.existing == null
                ? const [ServiceStatus.draft, ServiceStatus.live]
                : ServiceStatus.values,
            selected: _status,
            labelOf: (s) => switch (s) {
              ServiceStatus.draft => 'Draft',
              ServiceStatus.live => 'Live',
              ServiceStatus.archived => 'Archived',
            },
            onTap: (s) => setState(() => _status = s),
          ),
          const SizedBox(height: 4),
          Text(
              'Live listings appear in the client marketplace immediately. '
              'Archived listings are hidden but keep their history.',
              style: AppTypography.caption2),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _busy || !_valid ? null : _save,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(_busy ? 'SAVING…' : 'SAVE SERVICE',
                style: const TextStyle(
                    fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: AppTypography.caption2),
      );

  Widget _pills<T>({
    required List<T> values,
    required T selected,
    required String Function(T) labelOf,
    required void Function(T) onTap,
  }) {
    return Row(
      children: [
        for (final v in values) ...[
          GestureDetector(
            onTap: () => onTap(v),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: v == selected ? AppColors.accent : AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color:
                        v == selected ? AppColors.accent : AppColors.faint),
              ),
              child: Text(labelOf(v),
                  style: AppTypography.footnote.copyWith(
                      color: v == selected ? AppColors.bg : AppColors.ink,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
}
