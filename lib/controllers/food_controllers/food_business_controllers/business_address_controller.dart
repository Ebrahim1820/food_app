import 'package:food_app/controllers/food_controllers/food_business_controllers/business_partner_controller.dart';
import 'package:models/models.dart';
import 'package:profile/profile.dart';
import 'package:i18n/i18n.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:get/get.dart';

/// Manages the business partner's saved locations (pickup/store addresses).
///
/// The first address in [addresses] is treated as the primary location that
/// customers see on food offer listings — the backend has no isPrimary flag,
/// so order matters.
class BusinessAddressController extends GetxController {
  BusinessAddressController(this._service);

  final AddressService _service;
  static const _tag = 'BusinessAddressController';

  // --- Reactive state -------------------------------------------------------

  final addresses = <AddressModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  bool get isEmpty => addresses.isEmpty && !isLoading.value;

  // --- Lifecycle ------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    fetchAddresses();
  }

  // --- Read -----------------------------------------------------------------

  /// Loads all locations for the currently active business partner.
  Future<void> fetchAddresses() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final bpCtrl = Get.find<BusinessPartnerController>();
      if (bpCtrl.partnerId == 0) await bpCtrl.fetchMyPartner();
      final partnerId = bpCtrl.partnerId;

      if (partnerId == 0) {
        AppLogger.warning(_tag, 'Cannot fetch locations: partnerId is 0');
        addresses.value = [];
        return;
      }

      final partnerIri = '/api/business-partners/$partnerId';
      final result = await _service.getAddresses(
        businessPartnerIri: partnerIri,
      );
      addresses.value = result;
      AppLogger.info(
        _tag,
        'Loaded ${result.length} location(s) for $partnerIri',
      );
    } catch (e, st) {
      errorMessage.value = 'Could not load locations';
      AppLogger.error(_tag, 'fetchAddresses failed', error: e, stackTrace: st);
    } finally {
      isLoading.value = false;
    }
  }

  // --- Write ----------------------------------------------------------------

  /// Creates a new location for the business partner and refreshes the list.
  Future<void> createAddress(Map<String, dynamic> fields) async {
    // The backend now infers the owning business from the logged-in owner's
    // token — it no longer accepts a client-supplied businessPartner IRI.
    // `forBusiness: true` is the signal that this is a pickup/store address
    // rather than a personal delivery address.
    final data = {...fields, 'forBusiness': true};
    AppLogger.info(_tag, 'Creating business location');
    try {
      await _service.createAddress(data);
      await fetchAddresses();
      AppSnackbar.success('bizAddr_appBarTitle'.tr, 'bizAddr_locationSaved'.tr);
    } catch (e, st) {
      AppLogger.error(_tag, 'createAddress failed', error: e, stackTrace: st);
      AppSnackbar.error(ErrorStrings.title, 'bizAddr_saveError'.tr);
    }
  }

  /// Updates an existing location by id and refreshes the list.
  Future<void> updateAddress(String id, Map<String, dynamic> fields) async {
    AppLogger.info(_tag, 'Updating location $id');
    try {
      await _service.updateAddress(int.parse(id), fields);
      await fetchAddresses();
      AppSnackbar.success(
        'bizAddr_appBarTitle'.tr,
        'bizAddr_locationUpdated'.tr,
      );
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'updateAddress($id) failed',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.error(ErrorStrings.title, 'bizAddr_updateError'.tr);
    }
  }

  int _setPrimaryGen = 0;

  /// PATCHes `isPrimary: true` on [id] with optimistic local update.
  Future<void> setPrimary(String id) async {
    AppLogger.info(_tag, 'Setting address $id as primary');

    final gen = ++_setPrimaryGen;

    final prevPrimaryId = addresses
        .firstWhereOrNull((a) => a.isPrimary && a.id != id)
        ?.id;

    void pinPrimary() => addresses.value = addresses
        .map((a) => a.copyWith(isPrimary: a.id == id))
        .toList();

    pinPrimary();

    try {
      if (prevPrimaryId != null) {
        await _service.updateAddress(int.parse(prevPrimaryId), {
          'isPrimary': false,
        });
      }
      if (gen != _setPrimaryGen) return;
      await _service.updateAddress(int.parse(id), {'isPrimary': true});
      if (gen != _setPrimaryGen) return;
      await fetchAddresses();
      if (gen != _setPrimaryGen) return;
      pinPrimary();
      AppSnackbar.success(
        'bizAddr_appBarTitle'.tr,
        'bizAddr_setPrimarySuccess'.tr,
      );
    } catch (e, st) {
      AppLogger.error(_tag, 'setPrimary($id) failed', error: e, stackTrace: st);
      if (gen != _setPrimaryGen) return;
      await fetchAddresses();
      AppSnackbar.error(ErrorStrings.title, 'bizAddr_setPrimaryError'.tr);
    }
  }

  /// Deletes a location by id with an optimistic local removal.
  Future<void> deleteAddress(String id) async {
    final removed = addresses.firstWhereOrNull((a) => a.id == id);
    final idx = removed != null ? addresses.indexOf(removed) : -1;

    if (removed != null) addresses.removeAt(idx);

    AppLogger.info(_tag, 'Deleting location $id');
    try {
      await _service.deleteAddress(int.parse(id));
      AppSnackbar.success(
        'bizAddr_appBarTitle'.tr,
        'bizAddr_locationDeleted'.tr,
      );
    } catch (e, st) {
      if (removed != null) addresses.insert(idx, removed);
      AppLogger.error(
        _tag,
        'deleteAddress($id) failed',
        error: e,
        stackTrace: st,
      );
      AppSnackbar.error(ErrorStrings.title, 'bizAddr_deleteError'.tr);
    }
  }
}
