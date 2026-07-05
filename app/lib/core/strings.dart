/// Null-safe blank checks shared by the input-validating controls/gateways.
extension BlankString on String? {
  /// Null, empty, or whitespace-only.
  bool get isBlank => this == null || this!.trim().isEmpty;

  bool get isNotBlank => !isBlank;
}
