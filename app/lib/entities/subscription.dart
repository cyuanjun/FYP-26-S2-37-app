import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'expert_service.dart';

part 'subscription.freezed.dart';
part 'subscription.g.dart';

/// ENTITY — the premium role's 1:1 specialization row (shared key with the
/// user, like FitnessProfile/ExpertProfile). Premium users have one; Free
/// users don't. Payment is simulated: [priceCents] is a display figure.
@freezed
abstract class Subscription with _$Subscription {
  const Subscription._();

  const factory Subscription({
    required String id,
    @Default(SubscriptionStatus.active) SubscriptionStatus status,
    required DateTime startedAt,
    required DateTime renewsAt,
    @Default(999) int priceCents,
  }) = _Subscription;

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);

  bool get isActive => status == SubscriptionStatus.active;
  bool get isCancelled => status == SubscriptionStatus.cancelled;

  /// "$9.99 / mo"
  String get priceLabel => '${ExpertService.formatCents(priceCents)} / mo';

  /// #13.6 billing history is synthesised, not stored (no BillingRecord in
  /// v1): one charge per month from [startedAt] up to [now], most recent
  /// first, capped at 12.
  List<DateTime> billingDates(DateTime now) {
    final dates = <DateTime>[];
    var d = DateTime(startedAt.year, startedAt.month, startedAt.day);
    while (!d.isAfter(now)) {
      dates.add(d);
      d = DateTime(d.year, d.month + 1, d.day);
    }
    return dates.reversed.take(12).toList();
  }
}
