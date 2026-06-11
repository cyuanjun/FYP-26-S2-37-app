import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'health_tag.freezed.dart';
part 'health_tag.g.dart';

/// ENTITY — diet / allergy / injury catalog entry (#13.1). Users can add
/// custom tags (isCustom + createdByUserId) when the catalog doesn't cover them.
@freezed
abstract class HealthTag with _$HealthTag {
  const factory HealthTag({
    required String id,
    required HealthTagKind kind,
    required String name,
    @Default(false) bool isCustom,
    String? createdByUserId,
  }) = _HealthTag;

  factory HealthTag.fromJson(Map<String, dynamic> json) => _$HealthTagFromJson(json);
}
