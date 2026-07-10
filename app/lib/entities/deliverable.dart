import 'package:freezed_annotation/freezed_annotation.dart';

part 'deliverable.freezed.dart';
part 'deliverable.g.dart';

// (#) The finished work an expert hands back on a job. A titled document split
// (#) into headed sections of line items, basically a written-up plan.
@freezed
abstract class Deliverable with _$Deliverable {
  const Deliverable._();

  const factory Deliverable({
    required String id,
    required String serviceRequestId, // (#) the job this answers
    required String title,
    String? note, // (#) optional intro message from the expert
    @Default(<DeliverableSection>[]) List<DeliverableSection> sections, // (#) the body, grouped under headings
    required DateTime createdAt,
  }) = _Deliverable;

  factory Deliverable.fromJson(Map<String, dynamic> json) =>
      _$DeliverableFromJson(json);
}

// (#) One headed block inside a deliverable, a title plus its list of items
@freezed
abstract class DeliverableSection with _$DeliverableSection {
  const DeliverableSection._();

  const factory DeliverableSection({
    required String heading,
    @Default(<DeliverableItem>[]) List<DeliverableItem> items,
  }) = _DeliverableSection;

  factory DeliverableSection.fromJson(Map<String, dynamic> json) =>
      _$DeliverableSectionFromJson(json);

  // (#) convenience builder: split pasted text into one item per non-blank line
  static DeliverableSection fromLines(String heading, String lines) =>
      DeliverableSection(
        heading: heading,
        items: [
          for (final line in lines.split('\n'))
            if (line.trim().isNotEmpty) DeliverableItem(label: line.trim()),
        ],
      );
}

// (#) A single line in a section, reuses the workout-segment label/detail/sub shape
@freezed
abstract class DeliverableItem with _$DeliverableItem {
  const factory DeliverableItem({
    required String label, // (#) main text of the line
    String? detail, // (#) right-hand detail like sets or reps
    String? sub, // (#) smaller note under the label
  }) = _DeliverableItem;

  factory DeliverableItem.fromJson(Map<String, dynamic> json) =>
      _$DeliverableItemFromJson(json);
}
