import 'package:core/core.dart';
import 'package:food_app/widgets/common/app_snackbar.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens Google Maps at a specific latitude/longitude via an external URL.
///
/// Shows an [AppSnackbar] and logs a warning on any failure — never throws.
class MapHelper {
  static const _tag = 'MapHelper';

  static Future<void> openMap({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    try {
      final validCoords =
          !latitude.isNaN &&
          !longitude.isNaN &&
          latitude >= -90 &&
          latitude <= 90 &&
          longitude >= -180 &&
          longitude <= 180;

      if (!validCoords) {
        AppLogger.warning(_tag, 'Invalid coordinates ($latitude, $longitude)');
        AppSnackbar.error(
          'mapHelper_errorTitle'.tr,
          'mapHelper_invalidCoordinates'.tr,
        );
        return;
      }

      final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      );

      if (!await canLaunchUrl(uri)) {
        AppLogger.warning(_tag, 'Cannot launch Google Maps URL');
        return;
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        AppLogger.warning(_tag, 'launchUrl returned false for $uri');
      }
    } catch (e, st) {
      AppLogger.error(_tag, 'openMap failed', error: e, stackTrace: st);
      AppSnackbar.error(
        'mapHelper_errorTitle'.tr,
        'mapHelper_couldNotOpenMaps'.tr,
      );
    }
  }
}
