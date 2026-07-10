import 'package:freezed_annotation/freezed_annotation.dart';

part 'expert_category.freezed.dart';
part 'expert_category.g.dart';

// (#) A bucket experts get grouped under, like Nutrition or Strength. Admin
// (#) curates the list and retired ones just get switched off rather than deleted.
@freezed
abstract class ExpertCategory with _$ExpertCategory {
  const factory ExpertCategory({
    required String id, // (#) slug primary key
    required String label,
    @Default('') String description,
    @Default(true) bool isActive, // (#) false hides it from pickers but labels still resolve
  }) = _ExpertCategory;

  factory ExpertCategory.fromJson(Map<String, dynamic> json) =>
      _$ExpertCategoryFromJson(json);
}
