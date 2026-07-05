import 'package:freezed_annotation/freezed_annotation.dart';

part 'deliverable.freezed.dart';
part 'deliverable.g.dart';

/// ENTITY — an expert's work product on an engagement (#6.2 "From {expert}",
/// authored in the expert view). [sections] reuses the WorkoutSegment display
/// shape (label / detail / sub) grouped under headings.
@freezed
abstract class Deliverable with _$Deliverable {
  const Deliverable._();

  const factory Deliverable({
    required String id,
    required String serviceRequestId,
    required String title,
    String? note,
    @Default(<DeliverableSection>[]) List<DeliverableSection> sections,
    required DateTime createdAt,
  }) = _Deliverable;

  factory Deliverable.fromJson(Map<String, dynamic> json) =>
      _$DeliverableFromJson(json);
}

@freezed
abstract class DeliverableSection with _$DeliverableSection {
  const DeliverableSection._();

  const factory DeliverableSection({
    required String heading,
    @Default(<DeliverableItem>[]) List<DeliverableItem> items,
  }) = _DeliverableSection;

  factory DeliverableSection.fromJson(Map<String, dynamic> json) =>
      _$DeliverableSectionFromJson(json);

  /// Composer helper: one plain-text line per item.
  static DeliverableSection fromLines(String heading, String lines) =>
      DeliverableSection(
        heading: heading,
        items: [
          for (final line in lines.split('\n'))
            if (line.trim().isNotEmpty) DeliverableItem(label: line.trim()),
        ],
      );
}

@freezed
abstract class DeliverableItem with _$DeliverableItem {
  const factory DeliverableItem({
    required String label,
    String? detail,
    String? sub,
  }) = _DeliverableItem;

  factory DeliverableItem.fromJson(Map<String, dynamic> json) =>
      _$DeliverableItemFromJson(json);
}
