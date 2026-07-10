import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'expert_service.dart';

part 'subscription.freezed.dart';
part 'subscription.g.dart';

// (#) A premium user's subscription record: start and renewal dates plus the
// (#) monthly price. Free users have none. Payment is faked, so the price is
// (#) really just for show.
@freezed
abstract class Subscription with _$Subscription {
  const Subscription._();

  const factory Subscription({
    required String id,
    @Default(SubscriptionStatus.active) SubscriptionStatus status, // (#) active or cancelled
    required DateTime startedAt, // (#) when they first went premium
    required DateTime renewsAt, // (#) when the next billing cycle rolls over
    @Default(999) int priceCents, // (#) monthly price in cents, display only since payment is simulated
  }) = _Subscription;

  // (#) Rebuilds a Subscription from its stored JSON.
  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);

  // (#) True while the subscription is still running.
  bool get isActive => status == SubscriptionStatus.active;
  // (#) True once the user has cancelled.
  bool get isCancelled => status == SubscriptionStatus.cancelled;

  // (#) The price formatted for display, like "$9.99 / mo".
  String get priceLabel => '${ExpertService.formatCents(priceCents)} / mo';

  // (#) Makes up a fake billing history since we store no charge records: one
  // (#) charge per month from the start date up to now, newest first, capped at 12.
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
