import 'package:geolocator/geolocator.dart';

class DistanceHelper {
  static double? calculateDistanceKm(
    double? userLat,
    double? userLng,
    String? bizLat,
    String? bizLng,
  ) {
    final uLat = userLat;
    final uLng = userLng;

    final bLat = double.tryParse(bizLat ?? '');
    final bLng = double.tryParse(bizLng ?? '');

    if (uLat == null || uLng == null || bLat == null || bLng == null) {
      return null;
    }

    return Geolocator.distanceBetween(uLat, uLng, bLat, bLng) / 1000;
  }
}
