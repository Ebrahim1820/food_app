import 'package:food_app/services/location_service.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

/// Gets and holds the user's current location (latitude/longitude).
///
/// Other controllers (like the food offers "Near Me" filter) read
/// [userLat] and [userLng] from here.
class LocationController extends GetxController {
  // ───────────────────────── STATE ─────────────────────────
  // All state is reactive (.obs) so the UI can use Obx() everywhere.

  /// User's latitude, or null if we don't have it yet.
  final Rxn<double> userLat = Rxn<double>();

  /// User's longitude, or null if we don't have it yet.
  final Rxn<double> userLng = Rxn<double>();

  /// True while we're fetching the location (show a spinner).
  final isLoading = false.obs;

  /// Error text to show the user. Empty means "no error".
  final errorMessage = ''.obs;

  /// Quick check: do we actually have a location?
  bool get hasLocation => userLat.value != null && userLng.value != null;

  @override
  void onInit() {
    super.onInit();
    loadUserLocation(); // Fetch the location as soon as the app starts.
  }

  // ───────────────────────── ACTIONS ─────────────────────────

  /// Fetches the user's location and saves it.
  /// Sets [errorMessage] instead of crashing if something goes wrong.
  Future<void> loadUserLocation() async {
    // Start loading and clear any old error.
    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Ask the location service where the user is.
      final position = await LocationService.getCurrentPosition();
      userLat.value = position.latitude;
      userLng.value = position.longitude;
    } on LocationServiceDisabledException {
      // The phone's location (GPS) is turned off.
      errorMessage.value = "Location services are disabled";
    } on PermissionDeniedException {
      // The user said "no" to the location permission.
      errorMessage.value = "Location permission denied";
    } catch (e) {
      // Any other unexpected problem.
      errorMessage.value = "Something went wrong: $e";
    } finally {
      // Always stop the spinner, success or fail.
      isLoading.value = false;
    }
  }

  /// Lets a "Try again" button in the UI re-attempt the fetch.
  Future<void> retryLocation() => loadUserLocation();
}
