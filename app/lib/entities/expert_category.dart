import 'package:freezed_annotation/freezed_annotation.dart';

part 'expert_category.freezed.dart';
part 'expert_category.g.dart';

/// ENTITY — admin-curated expert category catalog (slug PK). Retired
/// categories flip isActive false (hidden from pickers, labels still resolve).
@freezed
abstract class ExpertCategory with _$ExpertCategory {
  const factory ExpertCategory({
    required String id,
    required String label,
    @Default('') String description,
    @Default(true) bool isActive,
  }) = _ExpertCategory;

  factory ExpertCategory.fromJson(Map<String, dynamic> json) =>
      _$ExpertCategoryFromJson(json);
}
