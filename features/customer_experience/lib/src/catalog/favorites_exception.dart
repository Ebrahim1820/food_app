/// Thrown when a favorites API call fails. Wrapping `DioException` here keeps
/// Dio-specific types out of the controller/UI layer.
class FavoritesException implements Exception {
  FavoritesException(this.message);
  final String message;

  @override
  String toString() => 'FavoritesException: $message';
}
