import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'health_tag.freezed.dart';
part 'health_tag.g.dart';

// (#) A health label a user carries, like a diet, an allergy or an injury. It
// (#) comes from a catalog, or the user makes their own when nothing fits.
@freezed
abstract class HealthTag with _$HealthTag {
  const factory HealthTag({
    required String id,
    required HealthTagKind kind, // (#) which sort of tag: diet, allergy or injury
    required String name,
    @Default(false) bool isCustom, // (#) true when the user made this one, not the catalog
    String? createdByUserId, // (#) who made it, only filled in for custom tags
  }) = _HealthTag;

  // (#) Rebuilds a HealthTag from the JSON a gateway pulled out of Postgres.
  factory HealthTag.fromJson(Map<String, dynamic> json) => _$HealthTagFromJson(json);
}
