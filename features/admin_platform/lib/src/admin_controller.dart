import 'package:admin_platform/admin_platform.dart';
import 'package:core/core.dart';
import 'package:models/models.dart';
import 'package:customer_experience/customer_experience.dart';
import 'package:get/get.dart';

class AdminController extends GetxController {
  AdminController(this._service);

  final AdminService _service;

  // ── State ─────────────────────────────────────────────────────────────────

  final stats = Rx<AdminStats>(AdminStats.empty);
  final partners = <BusinessPartnerModel>[].obs;
  final customers = <UserModel>[].obs;
  final offers = <FoodOfferModel>[].obs;
  final orders = <OrderModel>[].obs;

  final isLoading = false.obs;
  final isStatsLoading = false.obs;
  final errorMessage = ''.obs;

  /// True while showing cached admin data from the previous session.
  final isFromCache = false.obs;

  // Total counts from API (pagination-aware)
  final totalPartners = 0.obs;
  final totalCustomers = 0.obs;
  final totalOffers = 0.obs;
  final totalOrders = 0.obs;

  // ── Search / Filter ───────────────────────────────────────────────────────

  final partnersSearch = ''.obs;
  final partnersKycFilter = 'all'.obs; // all | approved | pending | rejected

  final customersSearch = ''.obs;
  final customersRoleFilter = 'all'.obs; // all | customer | partner | admin
  final customersVerifiedFilter = 'all'.obs; // all | verified | unverified

  final offersSearch = ''.obs;
  final offersStatusFilter =
      'all'.obs; // all | active | upcoming | expired | soldout

  final ordersSearch = ''.obs;
  final ordersStatusFilter = 'all'.obs;

  // ── Computed ──────────────────────────────────────────────────────────────

  /// Number of users linked to each business partner, keyed by partner id.
  Map<String, int> get usersPerPartner {
    final map = <String, int>{};
    for (final user in customers) {
      final bpId = user.effectiveBusinessPartnerId;
      if (bpId != null) map[bpId] = (map[bpId] ?? 0) + 1;
    }
    return map;
  }

  List<BusinessPartnerModel> get filteredPartners {
    var list = partners.toList();

    final kyc = partnersKycFilter.value;
    if (kyc != 'all') {
      list = list.where((p) {
        final s = p.kycStatus.toLowerCase();
        return switch (kyc) {
          'approved' => s == 'approved' || s == 'verified',
          'pending' =>
            s == 'pending' || s == 'in_review' || s == 'under_review',
          'rejected' => s == 'rejected' || s == 'declined',
          _ => true,
        };
      }).toList();
    }

    final q = partnersSearch.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (p) =>
                p.businessName.toLowerCase().contains(q) ||
                p.city.toLowerCase().contains(q),
          )
          .toList();
    }

    return list;
  }

  List<UserModel> get filteredCustomers {
    var list = customers.toList();

    final role = customersRoleFilter.value;
    if (role != 'all') {
      list = list
          .where(
            (u) => switch (role) {
              'admin' => u.roles.any((r) => r.toUpperCase().contains('ADMIN')),
              'partner' => u.roles.any(
                (r) => r.toUpperCase().contains('BUSINESS_PARTNER'),
              ),
              'customer' => !u.roles.any(
                (r) =>
                    r.toUpperCase().contains('ADMIN') ||
                    r.toUpperCase().contains('BUSINESS_PARTNER'),
              ),
              _ => true,
            },
          )
          .toList();
    }

    final verified = customersVerifiedFilter.value;
    if (verified == 'verified') list = list.where((u) => u.isVerified).toList();
    if (verified == 'unverified')
      list = list.where((u) => !u.isVerified).toList();

    final q = customersSearch.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (u) =>
                u.firstName.toLowerCase().contains(q) ||
                u.lastName.toLowerCase().contains(q) ||
                u.email.toLowerCase().contains(q),
          )
          .toList();
    }

    return list;
  }

  List<FoodOfferModel> get filteredOffers {
    var list = offers.toList();
    final now = DateTime.now();

    final status = offersStatusFilter.value;
    if (status != 'all') {
      list = list
          .where(
            (o) => switch (status) {
              'active' =>
                o.status == 'active' &&
                    o.endTime.isAfter(now) &&
                    (o.quantityAvailable ?? 0) > 0,
              'upcoming' => o.startTime.isAfter(now),
              'expired' => o.endTime.isBefore(now),
              'soldout' =>
                (o.quantityAvailable ?? 0) == 0 && o.endTime.isAfter(now),
              _ => true,
            },
          )
          .toList();
    }

    final q = offersSearch.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (o) =>
                o.title.toLowerCase().contains(q) ||
                (o.businessPartner?.businessName.toLowerCase().contains(q) ??
                    false),
          )
          .toList();
    }

    return list;
  }

  List<OrderModel> get filteredOrders {
    var list = orders.toList();
    final status = ordersStatusFilter.value;
    if (status != 'all') {
      list = list.where((o) {
        if (status == 'active') {
          const active = {
            'confirmed',
            'preparing',
            'ready',
            'ready_for_pickup',
            'out_for_delivery',
          };
          return active.contains(o.status);
        }
        if (status == 'done') {
          return o.status == 'delivered' ||
              o.status == 'completed' ||
              o.status == 'cancelled';
        }
        return o.status == status;
      }).toList();
    }
    final q = ordersSearch.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((o) {
        if (o.id.toLowerCase().contains(q)) return true;
        final customer = '${o.user?.firstName ?? ''} ${o.user?.lastName ?? ''}'
            .toLowerCase();
        if (customer.contains(q)) return true;
        return o.businessPartner.businessName.toLowerCase().contains(q);
      }).toList();
    }
    return list;
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  static const _statsCacheKey = 'admin_stats';
  static const _partnersCacheKey = 'admin_partners';
  static const _customersCacheKey = 'admin_customers';
  static const _offersCacheKey = 'admin_offers';
  static const _ordersCacheKey = 'admin_orders';

  @override
  void onInit() {
    super.onInit();
    _loadCachedData();
    fetchAll();
  }

  // ── Cache ─────────────────────────────────────────────────────────────────

  /// Shows the last-known dashboard immediately (if any and not stale) while
  /// [fetchAll] fetches everything fresh in the background.
  void _loadCachedData() {
    final stats = DataCacheService.load(
      _statsCacheKey,
      (json) => AdminStats.fromJson(json as Map<String, dynamic>),
    );
    final partners = DataCacheService.load(
      _partnersCacheKey,
      (json) => (json as List)
          .map((e) => BusinessPartnerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    final customers = DataCacheService.load(
      _customersCacheKey,
      (json) => (json as List)
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    final offersCached = DataCacheService.load(
      _offersCacheKey,
      (json) => (json as List)
          .map((e) => FoodOfferModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    final ordersCached = DataCacheService.load(
      _ordersCacheKey,
      (json) => (json as List)
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

    if (stats == null &&
        partners == null &&
        customers == null &&
        offersCached == null &&
        ordersCached == null) {
      return;
    }

    if (stats != null) this.stats.value = stats;
    if (partners != null) this.partners.value = partners;
    if (customers != null) this.customers.value = customers;
    if (offersCached != null) offers.value = offersCached;
    if (ordersCached != null) orders.value = ordersCached;
    isFromCache.value = true;
  }

  // ── Fetch ─────────────────────────────────────────────────────────────────

  Future<void> fetchAll() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await Future.wait([
        _fetchStats(),
        _fetchPartners(),
        _fetchCustomers(),
        _fetchOffers(),
        _fetchOrders(),
      ]);
      isFromCache.value = false;
    } catch (e, st) {
      errorMessage.value = 'Failed to load admin data';
      AppLogger.error(
        'AdminController',
        'fetchAll failed',
        error: e,
        stackTrace: st,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshStats() => _fetchStats();
  Future<void> refreshPartners() => _fetchPartners();
  Future<void> refreshCustomers() => _fetchCustomers();
  Future<void> refreshOffers() => _fetchOffers();
  Future<void> refreshOrders() => _fetchOrders();

  Future<void> _fetchStats() async {
    try {
      stats.value = await _service.fetchStats();
      await DataCacheService.save(_statsCacheKey, stats.value.toJson());
    } catch (e, st) {
      AppLogger.error(
        'AdminController',
        'fetchStats failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _fetchPartners() async {
    try {
      final page = await _service.fetchPartners(limit: 50);
      partners.value = page.items;
      totalPartners.value = page.total;
      await DataCacheService.save(
        _partnersCacheKey,
        page.items.map((p) => p.toJson()).toList(),
      );
    } catch (e, st) {
      AppLogger.error(
        'AdminController',
        'fetchPartners failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _fetchCustomers() async {
    try {
      final page = await _service.fetchCustomers(limit: 100);
      customers.value = page.items;
      totalCustomers.value = page.total;
      await DataCacheService.save(
        _customersCacheKey,
        page.items.map((u) => u.toJson()).toList(),
      );
    } catch (e, st) {
      AppLogger.error(
        'AdminController',
        'fetchCustomers failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _fetchOffers() async {
    try {
      final page = await _service.fetchAllOffers(limit: 100);
      offers.value = page.items;
      totalOffers.value = page.total;
      await DataCacheService.save(
        _offersCacheKey,
        page.items.map((o) => o.toJson()).toList(),
      );
    } catch (e, st) {
      AppLogger.error(
        'AdminController',
        'fetchOffers failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _fetchOrders() async {
    try {
      final page = await _service.fetchAllOrders(limit: 100);
      orders.value = page.items;
      totalOrders.value = page.total;
      await DataCacheService.save(
        _ordersCacheKey,
        page.items.map((o) => o.toJson()).toList(),
      );
    } catch (e, st) {
      AppLogger.error(
        'AdminController',
        'fetchOrders failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  // ── Broadcast ────────────────────────────────────────────────────────────

  final isSendingBroadcast = false.obs;

  /// Sends a fire-once-now push + notification-history row to every
  /// customer. Returns the recipient count on success, null on failure (the
  /// screen shows the caught error separately).
  Future<int?> sendBroadcast({
    required String title,
    required String body,
  }) async {
    isSendingBroadcast.value = true;
    try {
      return await _service.sendBroadcast(title: title, body: body);
    } catch (e, st) {
      AppLogger.error(
        'AdminController',
        'sendBroadcast failed',
        error: e,
        stackTrace: st,
      );
      return null;
    } finally {
      isSendingBroadcast.value = false;
    }
  }
}
