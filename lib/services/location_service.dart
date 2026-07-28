import 'package:food_app/utils/app_logger.dart';
import 'package:geolocator/geolocator.dart';

/// Provides the device's current GPS position.
///
/// Used on the home screen to sort nearby food offers and on the address screen
/// to pre-fill the user's current location. All permission checks happen here
/// so callers only have to await [getCurrentPosition].
class LocationService {
  static const _tag = 'LocationService';

  /// Returns the device's current GPS position.
  ///
  /// Requests permission from the OS if not already granted.
  /// Throws an [Exception] if location services are disabled or the user
  /// permanently denies permission — callers should catch this and show a
  /// friendly message instead of crashing.
  static Future<Position> getCurrentPosition() async {
    AppLogger.info(_tag, 'Checking location services');
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.warning(_tag, 'Location services are disabled on device');
        throw Exception(
          'Location services are disabled. Please enable them in Settings.',
        );
      }

      var permission = await Geolocator.checkPermission();
      AppLogger.info(_tag, 'Current permission: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        AppLogger.info(_tag, 'Permission after request: $permission');
      }

      if (permission == LocationPermission.deniedForever) {
        AppLogger.warning(_tag, 'Location permission permanently denied');
        throw Exception(
          'Location permission is permanently denied. Please allow it in app Settings.',
        );
      }

      AppLogger.info(_tag, 'Fetching current position (high accuracy)');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      AppLogger.info(
        _tag,
        'Position: lat=${position.latitude} lng=${position.longitude}',
      );
      return position;
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'getCurrentPosition failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
