// lib/controllers/business_partner_controller.dart
//
// Single source of truth for the logged-in business partner's identity.
//
// Lifecycle:
//   1. LoginController calls fetchMyPartner() right after a successful login.
//   2. AuthGate calls fetchMyPartner() on app restart if a token is already stored.
//   3. Any screen that needs the partnerId or businessName reads from here.
//
// This replaces every hardcoded `businessPartnerId: 1` in the app.

import 'package:food_app/controllers/auth_controller.dart';
import 'package:food_app/models/business_partner_model.dart';
import 'package:food_app/models/food_models/business_models/team_member_model.dart';
import 'package:food_app/screens/auth/keycloak_auth_service.dart';
import 'package:food_app/services/food_services/business_services/business_partner_service.dart';
import 'package:food_app/services/data_cache_service.dart';
import 'package:get/get.dart';

class BusinessPartnerController extends GetxController {
  BusinessPartnerController(this._service);

  final BusinessPartnerService _service;

  // ── State ─────────────────────────────────────────────────────────────────

  /// The fetched business partner. Null until fetchMyPartner() completes.
  final Rx<BusinessPartnerModel?> partner = Rx(null);
  final isLoading = false.obs;

  /// True while the open/closed PATCH request is in-flight.
  final isTogglingStatus = false.obs;

  /// True while the cash-payment PATCH request is in-flight.
  final isTogglingCash = false.obs;

  /// True while the close-business POST request is in-flight.
  final isClosingBusiness = false.obs;

  /// True while the deliveryFee PATCH request is in-flight.
  final isSavingDeliveryFee = false.obs;

  /// The current user's API IRI (e.g. "/api/users/abc-123"), set from the
  /// /users/me response. Used for avatar uploads without needing a separate
  /// /users/me call or relying on the Keycloak sub claim.
  final currentUserIri = RxnString();

  /// Whether the signed-in user has verified their email address.
  /// Defaults to true so no false-positive banner is shown before the first fetch.
  final isEmailVerified = true.obs;

  /// Set when the last fetch failed — cleared on the next successful fetch.
  final RxnString fetchError = RxnString();

  /// True while the UI is showing cached data from the previous session.
  /// Cleared as soon as a fresh API response arrives.
  final isFromCache = false.obs;

  static const _cacheKey = 'business_partner';

  // ── Convenient accessors ──────────────────────────────────────────────────

  /// Integer partner ID ready to pass to screens and API calls.
  /// Returns 0 while the partner hasn't been loaded yet.
  int get partnerId => partner.value?.numericId ?? 0;

  /// Business name for display in the dashboard header.
  String get partnerName => partner.value?.businessName ?? '';

  bool get isLoaded => partner.value != null;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Fetches the business partner linked to the currently authenticated user.
  /// Called once after login and once on app restart (from AuthGate).
  ///
  /// Cache behaviour:
  ///   1. If a cached profile exists, show it immediately (isFromCache = true).
  ///   2. Fetch fresh from the API in the background.
  ///   3. On success: update data, save to cache, clear isFromCache.
  ///   4. On error + cache exists: keep showing cached data (fetchError is set
  ///      so the UI can show the stale banner with a retry option).
  ///   5. On error + no cache: show the error/retry state.
  Future<void> fetchMyPartner() async {
    // Step 1 — show cached data immediately so the screen isn't blank.
    // Guard against a partner with an empty id: BusinessPartnerModel.iri
    // is built as '/api/business-partners/$id', so an empty id produces the
    // malformed IRI '/api/business-partners/' — every avatar/API call keyed
    // off it then silently targets nothing. Treating it as "no cache" here
    // forces the fresh fetch below to be the source of truth instead of
    // showing a half-broken identity.
    final cached = DataCacheService.load(
      _cacheKey,
      (json) => BusinessPartnerModel.fromJson(json as Map<String, dynamic>),
    );
    if (cached != null && cached.id.isNotEmpty && partner.value == null) {
      partner.value = cached;
      isFromCache.value = true;
    }

    isLoading.value =
        partner.value == null; // only show spinner if nothing to show yet
    fetchError.value = null;

    try {
      // Step 2 — fetch fresh from API.
      final (fetchedPartner, userIri, verified) = await _service
          .fetchMyPartner();

      // Step 3 — update state and persist to cache. Same empty-id guard as
      // above — never adopt or cache a partner the backend sent back without
      // a usable id, and surface it as an error instead of silently leaving
      // stale/broken data on screen.
      if (fetchedPartner != null && fetchedPartner.id.isNotEmpty) {
        partner.value = fetchedPartner;
        await DataCacheService.save(_cacheKey, fetchedPartner.toJson());
      } else if (fetchedPartner != null) {
        fetchError.value =
            'Business partner profile is missing an id — please contact support.';
      }
      isEmailVerified.value = verified;
      isFromCache.value = false;
      Get.find<AuthController>().setEmailVerified(verified);

      if (userIri != null && userIri.isNotEmpty) {
        currentUserIri.value = userIri;
      } else {
        final sub = Get.find<AuthController>().userId;
        if (sub.isNotEmpty) currentUserIri.value = '/api/users/$sub';
      }
    } catch (e) {
      // Step 4/5 — on error, keep cached data visible but signal the problem.
      fetchError.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// POST /business_partners/{id}/assign-member
  /// Throws on network / validation error so callers can show an error message.
  Future<void> assignMember({
    required String email,
    required String role,
    required List<String> permissions,
  }) async {
    if (partnerId == 0) await fetchMyPartner();
    if (partnerId == 0) {
      throw Exception('Could not load business partner. Please try again.');
    }
    return _service.manageMember(
      partnerId: partnerId,
      email: email,
      action: 'assign',
    );
  }

  Future<List<TeamMemberModel>> fetchMembers() async {
    if (partner.value == null) await fetchMyPartner();
    return _service.fetchMembers(partner.value?.userIris ?? const []);
  }

  Future<void> removeMember({required String email}) async {
    if (partnerId == 0) await fetchMyPartner();
    if (partnerId == 0) {
      throw Exception('Could not load business partner. Please try again.');
    }
    return _service.manageMember(
      partnerId: partnerId,
      email: email,
      action: 'remove',
    );
  }

  /// PATCHes [isActive] on the backend, then updates the local model so the
  /// UI reflects the new status without a full re-fetch.
  ///
  /// Returns true on success, false on network/server error. The caller can
  /// read [fetchError] for a human-readable error message on failure.
  Future<bool> setIsOpen(bool isOpen) async {
    if (partnerId == 0) return false;

    isTogglingStatus.value = true;
    fetchError.value = null;

    // Optimistically update the local model so the UI feels instant.
    // This will be rolled back if the API call fails.
    final previous = partner.value;
    partner.value = previous?.copyWith(isActive: isOpen);

    try {
      await _service.updateIsActive(partnerId, isActive: isOpen);
      return true;
    } catch (e) {
      // Rollback the optimistic update so the UI shows the real server state.
      partner.value = previous;
      fetchError.value = e.toString();
      return false;
    } finally {
      isTogglingStatus.value = false;
    }
  }

  /// PATCHes [acceptsCashPayment] on the backend with an optimistic update.
  Future<bool> setAcceptsCashPayment(bool value) async {
    if (partnerId == 0) return false;

    isTogglingCash.value = true;
    fetchError.value = null;

    final previous = partner.value;
    partner.value = previous?.copyWith(acceptsCashPayment: value);

    try {
      await _service.updateAcceptsCashPayment(partnerId, value: value);
      return true;
    } catch (e) {
      partner.value = previous;
      fetchError.value = e.toString();
      return false;
    } finally {
      isTogglingCash.value = false;
    }
  }

  /// Permanently closes the business (owner only). This strips business
  /// roles from everyone linked, including this user, so the Keycloak realm
  /// roles baked into the current JWT go stale the instant the backend call
  /// succeeds — a fresh token is forced immediately after so
  /// [AuthController.roles] reflects plain ROLE_USER without a full
  /// re-login, then the local partner state is cleared.
  ///
  /// Returns true on success, false on error (see [fetchError]).
  Future<bool> closeBusiness(String reason) async {
    if (partnerId == 0) return false;

    isClosingBusiness.value = true;
    fetchError.value = null;

    try {
      await _service.closeBusiness(partnerId, reason: reason);
      final newToken = await Get.find<KeycloakAuthService>()
          .forceRefreshToken();
      if (newToken != null) {
        await Get.find<AuthController>().setToken(newToken);
      }
      clear();
      return true;
    } catch (e) {
      fetchError.value = e.toString();
      return false;
    } finally {
      isClosingBusiness.value = false;
    }
  }

  /// PATCHes [deliveryFee] on the backend with an optimistic update.
  Future<bool> setDeliveryFee(String deliveryFee) async {
    if (partnerId == 0) return false;

    isSavingDeliveryFee.value = true;
    fetchError.value = null;

    final previous = partner.value;
    partner.value = previous?.copyWith(deliveryFee: deliveryFee);

    try {
      await _service.updateDeliveryFee(partnerId, deliveryFee: deliveryFee);
      return true;
    } catch (e) {
      partner.value = previous;
      fetchError.value = e.toString();
      return false;
    } finally {
      isSavingDeliveryFee.value = false;
    }
  }

  /// Clears the stored partner — called on logout so the next login
  /// starts fresh instead of showing stale data.
  void clear() {
    partner.value = null;
    fetchError.value = null;
    isFromCache.value = false;
    DataCacheService.remove(_cacheKey);
  }
}
