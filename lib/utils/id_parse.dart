/// Utility class for extracting numeric IDs from API Platform IRIs.
///
/// API responses often return identifiers in the format:
/// `/api/resource/123` instead of a raw integer.
/// This helper safely extracts the last segment and converts it to an int.
///
/// If the value is null, invalid, or cannot be parsed, it returns 0 as a fallback.
class IdParser {
  static int fromIri(dynamic value) {
    if (value == null) return 0;

    final str = value.toString();
    return int.tryParse(str.split('/').last) ?? 0;
  }
}
