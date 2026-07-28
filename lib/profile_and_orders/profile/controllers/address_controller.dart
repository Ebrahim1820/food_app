import 'package:food_app/controllers/auth_controller.dart';
import 'package:food_app/models/address_model.dart';
import 'package:food_app/services/address_service.dart';
import 'package:food_app/profile_and_orders/profile/constants/customer_profile_strings.dart';
import 'package:food_app/strings/error_strings.dart';
import 'package:food_app/utils/app_logger.dart';
import 'package:food_app/widgets/common/app_snackbar.dart';
import 'package:get/get.dart';

/// Holds the logged-in user's saved addresses and the one currently selected
/// for an order.
///
/// Reactive state for the UI (`Obx`):
/// - [addresses]       : addresses belonging to the current user only
/// - [selectedAddress] : the address chosen for checkout (null if none)
/// - [isLoading]       : true while fetching
/// - [errorMessage]    : last fetch error (null on success)
class AddressController extends GetxController {
  AddressController(this._service);

  final AddressService _service;
  static const _tag = 'AddressController';

  // --- Reactive state -------------------------------------------------------

  final addresses = <AddressModel>[].obs;
  final selectedAddress = Rxn<AddressModel>();
  final isLoading = false.obs;
  final errorMessage = RxnString();

  /// Pickup vs delivery for the order currently being placed. Defaults to
  /// pickup (false) — this is a pickup-first marketplace. Checkout resets
  /// this to false every time it's opened; see [resetDeliveryMode].
  final isDelivery = false.obs;

  bool get isEmpty => addresses.isEmpty && !isLoading.value;

  /// Toggles pickup vs delivery. Turning delivery OFF clears the selected
  /// address rather than just hiding the picker — the server derives the
  /// real deliveryFee from whether `deliveryAddress` is present in the
  /// request, so a hidden-but-still-selected address would silently charge
  /// the fee again. Turning it ON pre-selects the default address (if any)
  /// for convenience, matching how the address list already auto-selects a
  /// default on load.
  void setDelivery(bool value) {
    isDelivery.value = value;
    if (!value) {
      selectedAddress.value = null;
    } else if (selectedAddress.value == null && addresses.isNotEmpty) {
      selectedAddress.value =
          addresses.firstWhereOrNull((a) => a.isPrimary) ?? addresses.first;
    }
  }

  /// Called when the checkout screen opens so every new order starts in
  /// pickup mode regardless of what the last order used.
  void resetDeliveryMode() {
    isDelivery.value = false;
    selectedAddress.value = null;
  }

  // --- Lifecycle ------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    fetchAddresses();
  }

  // --- Read -----------------------------------------------------------------

  /// Loads only the addresses that belong to the currently logged-in user.
  Future<void> fetchAddresses() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final userId = Get.find<AuthController>().userId;
      if (userId.isEmpty) {
        AppLogger.warning(_tag, 'Cannot fetch addresses: userId is empty');
        addresses.value = [];
        return;
      }
      final userIri = '/api/users/$userId';
      final raw = await _service.getAddresses(userIri: userIri);
      // Guard against stale DB state where multiple rows have isPrimary=true.
      final result = _normalizePrimaries(raw);
      addresses.value = result;
      _reconcileSelection(result);
      AppLogger.info(_tag, 'Loaded ${result.length} address(es) for $userIri');
    } catch (e, st) {
      errorMessage.value = 'Could not load addresses';
      AppLogger.error(_tag, 'fetchAddresses failed', error: e, stackTrace: st);
    } finally {
      isLoading.value = false;
    }
  }

  // --- Write ----------------------------------------------------------------

  /// Creates a new address for the current user and refreshes the list.
  Future<void> createAddress(Map<String, dynamic> fields) async {
    final userId = Get.find<AuthController>().userId;
    final data = {...fields, 'user': '/api/users/$userId'};
    AppLogger.info(_tag, 'Creating address for user $userId');
    try {
      await _service.createAddress(data);
      await fetchAddresses();
      AppSnackbar.success(
        CustomerProfileStrings.addresses,
        CustomerProfileStrings.addressSaved,
      );
    } catch (e, st) {
      AppLogger.error(_tag, 'createAddress failed', error: e, stackTrace: st);
      AppSnackbar.error(ErrorStrings.title, CustomerProfileStrings.addressSaveError);
    }
  }

  /// Updates an existing address by id and refreshes the list.
  Future<void> updateAddress(String id, Map<String, dynamic> fields) async {
    AppLogger.info(_tag, 'Updating address $id');
    try {
      await _service.updateAddress(int.parse(id), fields);
      await fetchAddresses();
      AppSnackbar.success(
        CustomerProfileStrings.addresses,
        CustomerProfileStrings.addressUpdated,
      );
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'updateAddress($id) failed',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.error(ErrorStrings.title, CustomerProfileStrings.addressUpdateError);
    }
  }

  /// Deletes an address by id with an optimistic local removal.
  Future<void> deleteAddress(String id) async {
    final removed = addresses.firstWhereOrNull((a) => a.id == id);
    final idx = removed != null ? addresses.indexOf(removed) : -1;

    // Optimistic remove.
    if (removed != null) {
      addresses.removeAt(idx);
      _reconcileSelection(addresses);
    }

    AppLogger.info(_tag, 'Deleting address $id');
    try {
      await _service.deleteAddress(int.parse(id));
      AppSnackbar.success(
        CustomerProfileStrings.addresses,
        CustomerProfileStrings.addressDeleted,
      );
    } catch (e, st) {
      // Rollback.
      if (removed != null) {
        addresses.insert(idx, removed);
        _reconcileSelection(addresses);
      }
      AppLogger.error(
        _tag,
        'deleteAddress($id) failed',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.error(ErrorStrings.title, CustomerProfileStrings.addressDeleteError);
    }
  }

  // --- Selection ------------------------------------------------------------

  void selectAddress(AddressModel address) {
    selectedAddress.value = address;
  }

  // Incremented on every setDefault call so earlier in-flight calls abandon
  // their fetchAddresses/pinPrimary steps when superseded by a newer tap.
  int _setDefaultGen = 0;

  /// PATCHes `isPrimary: true` on [id], updates local state optimistically,
  /// and moves the delivery selection to the new default address.
  Future<void> setDefault(String id) async {
    AppLogger.info(_tag, 'Setting address $id as default');

    final gen = ++_setDefaultGen;

    // Capture the current primary before the optimistic update so we can
    // explicitly clear it on the server (backend listener is not reliable).
    final prevPrimaryId = addresses
        .firstWhereOrNull((a) => a.isPrimary && a.id != id)
        ?.id;

    // Optimistic: flip radio AND move the green delivery-selection border.
    void pinPrimary() {
      addresses.value = addresses
          .map((a) => a.copyWith(isPrimary: a.id == id))
          .toList();
      final primary = addresses.firstWhereOrNull((a) => a.id == id);
      if (primary != null) selectedAddress.value = primary;
    }

    pinPrimary();

    try {
      // Explicitly clear the old primary first so the DB is always consistent,
      // regardless of whether the backend listener fires correctly.
      if (prevPrimaryId != null) {
        await _service.updateAddress(int.parse(prevPrimaryId), {
          'isPrimary': false,
        });
      }
      if (gen != _setDefaultGen) return;
      await _service.updateAddress(int.parse(id), {'isPrimary': true});
      if (gen != _setDefaultGen) return;
      await fetchAddresses();
      if (gen != _setDefaultGen) return;
      pinPrimary();
      AppSnackbar.success(
        CustomerProfileStrings.addresses,
        CustomerProfileStrings.addressUpdated,
      );
    } catch (e, st) {
      AppLogger.error(_tag, 'setDefault($id) failed', error: e, stackTrace: st);
      if (gen != _setDefaultGen) return;
      await fetchAddresses();
      AppSnackbar.error(
        ErrorStrings.title,
        CustomerProfileStrings.addressSetDefaultError,
      );
    }
  }

  // --- Helpers --------------------------------------------------------------

  /// Ensures at most one address has [isPrimary] == true.
  /// Guards against stale DB rows where multiple were marked primary before
  /// the backend listener was in place.
  List<AddressModel> _normalizePrimaries(List<AddressModel> list) {
    bool seen = false;
    return list.map((a) {
      if (!a.isPrimary) return a;
      if (!seen) {
        seen = true;
        return a;
      }
      return a.copyWith(isPrimary: false);
    }).toList();
  }

  void _reconcileSelection(List<AddressModel> result) {
    if (result.isEmpty) {
      selectedAddress.value = null;
      return;
    }
    final current = selectedAddress.value;
    final stillExists =
        current != null && result.any((a) => a.id == current.id);
    if (stillExists) return;
    // Prefer the backend-flagged primary; fall back to first in list.
    selectedAddress.value =
        result.firstWhereOrNull((a) => a.isPrimary) ?? result.first;
  }
}
