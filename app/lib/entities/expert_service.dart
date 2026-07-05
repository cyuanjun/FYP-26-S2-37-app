import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'expert_service.freezed.dart';
part 'expert_service.g.dart';

/// ENTITY — one à-la-carte expert offering (#6.2). Payment is simulated:
/// [priceCents] is a display figure, never charged.
@freezed
abstract class ExpertService with _$ExpertService {
  const ExpertService._();

  const factory ExpertService({
    required String id,
    required String expertUserId,
    @Default(ServiceStatus.draft) ServiceStatus status,
    required String name,
    String? description,
    @Default(<String>[]) List<String> detailBullets,
    required String category,
    required FulfillmentType fulfillment,
    @Default(PricingModel.oneTime) PricingModel pricingModel,
    @Default(0) int priceCents,
    int? durationWeeks,
    @Default(true) bool acceptingBookings,
    @Default(ResponseTime.h48) ResponseTime responseTime,
  }) = _ExpertService;

  factory ExpertService.fromJson(Map<String, dynamic> json) =>
      _$ExpertServiceFromJson(json);

  /// "$120" / "$45.50" — whole dollars unless there are cents.
  String get priceLabel => formatCents(priceCents);

  /// "$80/mo" for recurring services.
  String get priceWithModel =>
      pricingModel == PricingModel.recurring ? '$priceLabel/mo' : priceLabel;

  static String formatCents(int cents) {
    final dollars = cents / 100;
    return dollars == dollars.roundToDouble()
        ? '\$${dollars.round()}'
        : '\$${dollars.toStringAsFixed(2)}';
  }
}
