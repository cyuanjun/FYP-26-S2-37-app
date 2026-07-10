import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'expert_service.freezed.dart';
part 'expert_service.g.dart';

// (#) One thing an expert sells, like a plan or a review. Holds the name,
// (#) category, price and how it gets delivered. Payment is simulated so the
// (#) price is display-only, nobody is actually charged.
@freezed
abstract class ExpertService with _$ExpertService {
  const ExpertService._();

  const factory ExpertService({
    required String id,
    required String expertUserId, // (#) the expert who owns it
    @Default(ServiceStatus.draft) ServiceStatus status, // (#) draft, live or archived
    required String name,
    String? description,
    @Default(<String>[]) List<String> detailBullets, // (#) "what you get" points
    required String category, // (#) category slug it's listed under
    required FulfillmentType fulfillment, // (#) how it's delivered
    @Default(PricingModel.oneTime) PricingModel pricingModel, // (#) one-off vs recurring
    @Default(0) int priceCents, // (#) price in cents, display only
    int? durationWeeks,
    @Default(true) bool acceptingBookings, // (#) can new clients request it right now
    @Default(ResponseTime.h48) ResponseTime responseTime,
  }) = _ExpertService;

  factory ExpertService.fromJson(Map<String, dynamic> json) =>
      _$ExpertServiceFromJson(json);

  // (#) price as a plain dollar string, dropping cents when it's a round amount
  String get priceLabel => formatCents(priceCents);

  // (#) same price but tacks on "/mo" when it's a recurring service
  String get priceWithModel =>
      pricingModel == PricingModel.recurring ? '$priceLabel/mo' : priceLabel;

  // (#) shared cents-to-dollars formatter, whole dollars unless cents are needed
  static String formatCents(int cents) {
    final dollars = cents / 100;
    return dollars == dollars.roundToDouble()
        ? '\$${dollars.round()}'
        : '\$${dollars.toStringAsFixed(2)}';
  }
}
