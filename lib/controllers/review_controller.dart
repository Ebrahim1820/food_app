import 'dart:async';

import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:food_app/controllers/auth_controller.dart';
import 'package:food_app/controllers/food_controllers/food_business_controllers/business_partner_controller.dart';
import 'package:food_app/controllers/mercure_controller.dart';
import 'package:food_app/models/review_model.dart';
import 'package:food_app/services/mercure_service.dart';
import 'package:food_app/services/review_service.dart';
import 'package:food_app/strings/error_strings.dart';
import 'package:food_app/strings/review_strings.dart';
import 'package:food_app/utils/app_logger.dart';
import 'package:food_app/widgets/common/app_snackbar.dart';
import 'package:get/get.dart';

/// Drives review submission (post-order rating) and reading a business's
/// review list — used by both the customer-facing "Ratings & Reviews" screen
/// and the business owner's Reviews dashboard tab.
class ReviewController extends GetxController {
  ReviewController(this._service);

  final ReviewService _service;
  static const _tag = 'ReviewController';
  static const _mercure = MercureService();

  // ───────────────────────── STATE ─────────────────────────

  /// Reviews loaded for whichever business is currently being viewed.
  final reviews = <ReviewModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  int _page = 1;
  String? _currentBusinessId;

  final isSubmitting = false.obs;

  /// Orders this session has confirmed the current user already reviewed —
  /// seeded in bulk by [preloadReviewedOrders] (see its docs) and topped up
  /// by [checkIfReviewedOrder]/[submit]. Reviews are per-order, not
  /// per-business: a customer rates each order/pickup separately, same as
  /// TGTG/Uber Eats.
  final _reviewedOrderIds = <String>{}.obs;

  bool hasReviewedOrder(String orderId) => _reviewedOrderIds.contains(orderId);

  /// True once [preloadReviewedOrders] has settled (success or failure) —
  /// the My Orders list uses this to decide whether it can already show a
  /// definitive "rate this order" state, or should render nothing for that
  /// row yet rather than a size that might change again once the answer
  /// arrives (a per-card version of that same race is what caused a real
  /// ListView/sliver layout crash before — see [[project_reviews_feature]]).
  final reviewedOrdersLoaded = false.obs;

  /// Fetches every order id this user has already reviewed, across all
  /// businesses, in one bulk call — call this once when the My Orders list
  /// opens (alongside `OrderController.fetchOrders()`), *before* any
  /// [OrderSummaryCard] row needs to know whether to show its "rate this
  /// order" chip. Replaces N per-card [checkIfReviewedOrder] round-trips
  /// (one per completed order on screen) with a single request, and — more
  /// importantly — means each row's footer size is correct on its very
  /// first frame instead of only being confirmed after the row is already
  /// laid out and potentially being scrolled.
  Future<void> preloadReviewedOrders() async {
    final userId = Get.find<AuthController>().userId;
    if (userId.isEmpty) {
      reviewedOrdersLoaded.value = true;
      return;
    }
    try {
      final ids = await _service.fetchReviewedOrderIds('/api/users/$userId');
      _reviewedOrderIds.addAll(ids);
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'preloadReviewedOrders failed',
        error: e,
        stackTrace: st,
      );
    } finally {
      reviewedOrdersLoaded.value = true;
    }
  }

  // ───────────────────── Real-time updates (Mercure) ─────────────────────

  StreamSubscription<SSEModel>? _mercureSub;
  Worker? _mercureTokenWorker;

  @override
  void onInit() {
    super.onInit();
    _connectMercure();
  }

  @override
  void onClose() {
    _mercureSub?.cancel();
    _mercureTokenWorker?.dispose();
    super.onClose();
  }

  /// Opens the SSE subscription to this business's private reviews topic
  /// (`business-partners/{id}/reviews`, from [MercureController]) so a new
  /// review pushes live to the business owner's Reviews tab — that tab lives
  /// inside a `IndexedStack` and never re-runs `initState`, so without this
  /// a new review was invisible until the app restarted. No-ops for
  /// customers (their Mercure credential has no `.../reviews` topic, so
  /// [MercureController.businessReviewsTopic] is just null for them).
  Future<void> _connectMercure() async {
    final mercureCtrl = Get.find<MercureController>();
    await mercureCtrl.ensureLoaded();
    _subscribeToBusinessReviews(mercureCtrl);

    _mercureTokenWorker?.dispose();
    _mercureTokenWorker = ever(mercureCtrl.tokenRx, (_) {
      _subscribeToBusinessReviews(mercureCtrl);
    });
  }

  void _subscribeToBusinessReviews(MercureController mercureCtrl) {
    final token = mercureCtrl.token;
    final topic = mercureCtrl.businessReviewsTopic;
    if (token == null || topic == null) return;

    AppLogger.info(_tag, 'Subscribing to Mercure topic: $topic');
    _mercureSub?.cancel();
    _mercureSub = _mercure.subscribeToBusinessReviews(
      topic: topic,
      token: token,
      onReview: (review) {
        AppLogger.info(
          _tag,
          'Mercure: new review ${review.id} (${review.rating}★) — refreshing',
        );
        final businessId = _currentBusinessId;
        if (businessId != null) fetchForBusiness(businessId);
        // The business's averageRating/reviewCount live on BusinessPartnerModel,
        // not here — refresh it too so the dashboard summary card and profile
        // stat update alongside the list, not just the list.
        if (Get.isRegistered<BusinessPartnerController>()) {
          Get.find<BusinessPartnerController>().fetchMyPartner();
        }
      },
    );
  }

  // ───────────────────────── READ ─────────────────────────

  Future<void> fetchForBusiness(String businessPartnerId) async {
    _currentBusinessId = businessPartnerId;
    _page = 1;
    isLoading.value = true;
    try {
      final result = await _service.fetchForBusiness(
        businessPartnerId,
        page: _page,
      );
      reviews.assignAll(result.reviews);
      hasMore.value = result.hasNext;
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'fetchForBusiness($businessPartnerId) failed',
        error: e,
        stackTrace: st,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMore() async {
    final businessId = _currentBusinessId;
    if (businessId == null || !hasMore.value || isLoadingMore.value) return;
    isLoadingMore.value = true;
    try {
      final result = await _service.fetchForBusiness(
        businessId,
        page: _page + 1,
      );
      _page++;
      reviews.addAll(result.reviews);
      hasMore.value = result.hasNext;
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'fetchMore($businessId) failed',
        error: e,
        stackTrace: st,
      );
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Checks whether the current user already reviewed [orderId] and caches
  /// the result in-memory so repeat calls (e.g. re-opening the same order
  /// detail screen) don't re-hit the network.
  Future<bool> checkIfReviewedOrder(String orderId) async {
    if (_reviewedOrderIds.contains(orderId)) return true;
    final userId = Get.find<AuthController>().userId;
    if (userId.isEmpty) return false;
    try {
      final reviewed = await _service.hasReviewedOrder(
        orderId,
        '/api/users/$userId',
      );
      if (reviewed) _reviewedOrderIds.add(orderId);
      return reviewed;
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'checkIfReviewedOrder($orderId) failed',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  // ───────────────────────── WRITE ─────────────────────────

  /// Submits a rating for [orderId] (at business [businessPartnerId]).
  /// Returns true on success (or on a 409 — which just means the user
  /// already reviewed this order, so the UI can treat it the same as "done").
  Future<bool> submit({
    required String businessPartnerId,
    required int rating,
    required String orderId,
    String? comment,
  }) async {
    isSubmitting.value = true;
    try {
      final review = await _service.submitReview(
        businessPartnerId: businessPartnerId,
        rating: rating,
        comment: comment,
        orderId: orderId,
      );
      reviews.insert(0, review);
      _reviewedOrderIds.add(orderId);
      AppSnackbar.success(
        ReviewStrings.submitSuccessTitle,
        ReviewStrings.submitSuccessBody,
        position: SnackPosition.TOP,
      );
      return true;
    } on ReviewAlreadyExistsException {
      _reviewedOrderIds.add(orderId);
      AppSnackbar.success(
        ReviewStrings.alreadyReviewedTitle,
        ReviewStrings.alreadyReviewedBody,
        position: SnackPosition.TOP,
      );
      return true;
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'submit($orderId) failed',
        error: e,
        stackTrace: st,
      );
      final detail = e.toString().replaceFirst('Exception: ', '');
      AppSnackbar.error(
        ErrorStrings.title,
        detail.isNotEmpty ? detail : ReviewStrings.submitErrorBody,
        position: SnackPosition.TOP,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}
