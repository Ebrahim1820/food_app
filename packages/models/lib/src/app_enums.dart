// lib/enums/app_enums.dart
//
// Single source of truth for ALL enums in the app.
// Never define enums in model, controller, or screen files — add them here.

import 'package:get/get.dart';

// ── Product Discovery ─────────────────────────────────────────────────────────

/// Sorting options shown on the customer-facing product listing.
///
/// Used by the home screen's sort chip row and API query params.
enum ProductSort {
  /// Show the most recently published offers first.
  newest,

  /// Sort offers by deal price (ascending).
  price,

  /// Sort offers by popularity / remaining quantity.
  popular,
}

/// Publication status of a product offer (as returned by the API).
///
/// Used for status badges and visibility toggles.
enum ProductStatus {
  /// Offer is live and available for booking.
  active,

  /// Offer's pickup window has passed.
  expired,

  /// Offer has been temporarily reserved.
  reserved,
}

// ── Offer Discovery ─────────────────────────────────────────────────────────

/// Sorting options shown on the customer-facing offer listing.
///
/// Used by the home screen's sort chip row and API query params.
enum OfferSort {
  /// Show the most recently published offers first.
  newest,

  /// Sort offers by deal price (ascending).
  price,

  /// Sort offers by popularity / remaining quantity.
  popular,
}

/// Publication status of a food offer (as returned by the API).
///
/// Used for status badges and visibility toggles.
enum OfferStatus {
  /// Offer is live and available for booking.
  active,

  /// Offer's pickup window has passed.
  expired,

  /// Offer has been temporarily reserved.
  reserved,
}

// ── User / Auth ──────────────────────────────────────────────────────────────

/// Role assigned to the authenticated user.
///
/// Drives navigation (business dashboard vs. customer home) and access control.
enum UserRole {
  /// Regular customer browsing and booking offers.
  customer,

  /// Business owner managing their surplus offers.
  business,

  /// System administrator with unrestricted access.
  admin,
}

// ── Order Lifecycle ──────────────────────────────────────────────────────────

/// High-level lifecycle status of an order.
///
/// Used for order-tracking UI and status indicators.
/// See also [OrderStatusEnums] for the full API-level status enum.
enum OrderStatus {
  /// Order placed but not yet accepted by the business.
  pending,

  /// Business has accepted the order.
  confirmed,

  /// Order picked up / delivered successfully.
  delivered,

  /// Order was cancelled by either party.
  cancelled,
}

// ── Business Orders Filter (BusinessOrdersScreen) ───────────────────────────

/// Sort direction for the business partner's order list.
///
/// Controls whether the most-recent or longest-waiting orders appear first.
enum OrderSortOrder {
  /// Show the most recently placed orders first (default).
  newest,

  /// Show the oldest, longest-waiting orders first.
  /// Useful for prioritising orders that have been waiting the longest.
  oldest,
}

/// Date-range filter for the business partner's order list.
///
/// Narrows the visible orders based on their creation timestamp.
enum OrderDateFilter {
  /// Show all orders regardless of when they were placed (default).
  all,

  /// Show only orders placed today.
  today,

  /// Show orders placed within the last 7 days.
  thisWeek,
}

// ── Analytics Dashboard (BusinessAnalyticsScreen) ────────────────────────────

/// Time range shown on the analytics dashboard.
///
/// Drives which dataset the [BusinessAnalyticsController] returns.
enum AnalyticsPeriod {
  /// Statistics for the current day only.
  today,

  /// Statistics for the last 7 days.
  week,

  /// Statistics for the current calendar month.
  month,

  /// Statistics for the previous full calendar month.
  lastMonth,

  /// Statistics for the last 3 full calendar months combined.
  lastThreeMonths;

  /// Chip label shown in [BusinessAnalyticsScreen].
  String get label => switch (this) {
    AnalyticsPeriod.today => 'analyticsPeriod_today'.tr,
    AnalyticsPeriod.week => 'analyticsPeriod_week'.tr,
    AnalyticsPeriod.month => 'analyticsPeriod_month'.tr,
    AnalyticsPeriod.lastMonth => 'analyticsPeriod_lastMonth'.tr,
    AnalyticsPeriod.lastThreeMonths => 'analyticsPeriod_lastThreeMonths'.tr,
  };
}

// ── Favourites Filter (FavoritesScreen) ──────────────────────────────────────

/// Sort options for the customer-facing favourites list.
enum FavoritesSort {
  alphabetical,
  priceLowHigh,
  priceHighLow;

  String get label => switch (this) {
    FavoritesSort.alphabetical => 'A → Z',
    FavoritesSort.priceLowHigh => 'Price ↑',
    FavoritesSort.priceHighLow => 'Price ↓',
  };
}

// ── Customer Order Filters (OrderListScreen) ─────────────────────────────────

/// Sort options for the customer-facing order history list.
enum CustomerOrderSort {
  newest,
  oldest,
  priceHighLow,
  priceLowHigh;

  String get label => switch (this) {
    CustomerOrderSort.newest => 'Newest',
    CustomerOrderSort.oldest => 'Oldest',
    CustomerOrderSort.priceHighLow => 'Price ↓',
    CustomerOrderSort.priceLowHigh => 'Price ↑',
  };
}

/// Status filter for the customer-facing order history list.
enum CustomerOrderStatusFilter {
  all,
  pending,
  confirmed,
  completed,
  cancelled;

  String? get apiValue => switch (this) {
    CustomerOrderStatusFilter.all => null,
    CustomerOrderStatusFilter.pending => 'pending',
    CustomerOrderStatusFilter.confirmed => 'confirmed',
    CustomerOrderStatusFilter.completed => 'completed',
    CustomerOrderStatusFilter.cancelled => 'cancelled',
  };

  String get label => switch (this) {
    CustomerOrderStatusFilter.all => 'custOrderStatus_all'.tr,
    CustomerOrderStatusFilter.pending => 'custOrderStatus_pending'.tr,
    CustomerOrderStatusFilter.confirmed => 'custOrderStatus_confirmed'.tr,
    CustomerOrderStatusFilter.completed => 'custOrderStatus_completed'.tr,
    CustomerOrderStatusFilter.cancelled => 'custOrderStatus_cancelled'.tr,
  };
}

// ── Business Menu Filter (BusinessMenuScreen) ────────────────────────────────

/// Sort direction for the business partner's own offer list.
enum OfferSortOrder {
  /// Show the most recently created offers first (default).
  newest,

  /// Show the oldest offers first.
  oldest,
}

/// Status filter for the business partner's own offer list.
///
/// Narrows the menu list to offers in a specific publication state.
enum OfferStatusFilter {
  /// Show all offers regardless of status (default).
  all,

  /// Show only offers that are currently live and bookable.
  active,

  /// Show only offers whose pickup window has passed.
  expired,

  /// Show only offers with no remaining quantity.
  soldOut,

  /// Show only offers that were manually cancelled.
  cancelled;

  /// The exact status string stored by the API, or [null] for [all]
  /// (caller should skip filtering when null).
  String? get apiValue => switch (this) {
    OfferStatusFilter.all => null,
    OfferStatusFilter.active => 'active',
    OfferStatusFilter.expired => 'expired',
    OfferStatusFilter.soldOut => 'sold_out',
    OfferStatusFilter.cancelled => 'cancelled',
  };

  /// Human-readable chip label shown in [BusinessMenuScreen].
  String get label => switch (this) {
    OfferStatusFilter.all => 'offerStatus_all'.tr,
    OfferStatusFilter.active => 'offerStatus_active'.tr,
    OfferStatusFilter.expired => 'offerStatus_expired'.tr,
    OfferStatusFilter.soldOut => 'offerStatus_soldOut'.tr,
    OfferStatusFilter.cancelled => 'offerStatus_cancelled'.tr,
  };
}

// ── Done-Tab Status Filter (BusinessOrdersScreen) ────────────────────────────

/// Status filter for the "Done" tab in the business orders screen.
///
/// Narrows the Done list to successful or cancelled orders.
enum DoneOrderFilter {
  /// Show all done orders (default).
  all,

  /// Show only successfully delivered/completed orders.
  completed,

  /// Show only cancelled orders.
  cancelled;

  /// Returns true when [status] matches this filter.
  bool matches(String status) => switch (this) {
    DoneOrderFilter.all => true,
    DoneOrderFilter.completed => status == 'delivered' || status == 'completed',
    DoneOrderFilter.cancelled => status == 'cancelled',
  };

  /// Chip label shown in the Done tab filter bar.
  String get label => switch (this) {
    DoneOrderFilter.all => 'doneFilter_all'.tr,
    DoneOrderFilter.completed => 'doneFilter_completed'.tr,
    DoneOrderFilter.cancelled => 'doneFilter_cancelled'.tr,
  };
}

// ── Business Order History Filters ───────────────────────────────────────────

/// Date preset selector for the business order history screen.
enum HistoryDatePreset {
  today,
  yesterday,
  last7Days,
  last30Days,
  custom;

  String get label => switch (this) {
    HistoryDatePreset.today => 'historyPreset_today'.tr,
    HistoryDatePreset.yesterday => 'historyPreset_yesterday'.tr,
    HistoryDatePreset.last7Days => 'historyPreset_last7'.tr,
    HistoryDatePreset.last30Days => 'historyPreset_last30'.tr,
    HistoryDatePreset.custom => 'historyPreset_custom'.tr,
  };

  /// Returns [from, to) bounds for the preset, or null for [custom].
  (DateTime, DateTime)? get range {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final tomorrowMidnight = todayMidnight.add(const Duration(days: 1));
    return switch (this) {
      HistoryDatePreset.today => (todayMidnight, tomorrowMidnight),
      HistoryDatePreset.yesterday => (
        todayMidnight.subtract(const Duration(days: 1)),
        todayMidnight,
      ),
      HistoryDatePreset.last7Days => (
        todayMidnight.subtract(const Duration(days: 7)),
        tomorrowMidnight,
      ),
      HistoryDatePreset.last30Days => (
        todayMidnight.subtract(const Duration(days: 30)),
        tomorrowMidnight,
      ),
      HistoryDatePreset.custom => null,
    };
  }
}

/// Status filter for the business order history screen (client-side only).
enum HistoryStatusFilter {
  all,
  completed,
  cancelled;

  bool matches(String status) => switch (this) {
    HistoryStatusFilter.all => true,
    HistoryStatusFilter.completed =>
      status == 'completed' || status == 'delivered',
    HistoryStatusFilter.cancelled => status == 'cancelled',
  };

  String get label => switch (this) {
    HistoryStatusFilter.all => 'historyStatus_all'.tr,
    HistoryStatusFilter.completed => 'historyStatus_completed'.tr,
    HistoryStatusFilter.cancelled => 'historyStatus_cancelled'.tr,
  };
}

// ── Business Order Bucket (BusinessOrdersScreen tabs) ────────────────────────

/// Which tab an order appears in on the business partner's orders screen.
enum OrderBucket {
  /// Newly placed orders awaiting acceptance.
  incoming,

  /// Accepted orders being prepared.
  active,

  /// Completed or cancelled orders.
  done,
}

// ── Order Lifecycle Status (API-level, business + customer) ──────────────────

/// Full set of lifecycle statuses returned by the backend.
///
/// Use [value] when sending to the API and [label] for human-readable display.
/// [fromValue] maps an API string back to the enum safely.
/// [next] / [previous] express the linear progression through the lifecycle.
enum OrderStatusEnums {
  pending,
  confirmed,
  readyForPickup,
  completed,
  cancelled;

  /// The exact string the API stores (snake_case).
  String get value => switch (this) {
    OrderStatusEnums.pending => 'pending',
    OrderStatusEnums.confirmed => 'confirmed',
    OrderStatusEnums.readyForPickup => 'ready_for_pickup',
    OrderStatusEnums.completed => 'completed',
    OrderStatusEnums.cancelled => 'cancelled',
  };

  /// Friendly UI label.
  String get label => switch (this) {
    OrderStatusEnums.pending => 'Waiting for confirmation',
    OrderStatusEnums.confirmed => 'Confirmed',
    OrderStatusEnums.readyForPickup => 'Ready for pickup',
    OrderStatusEnums.completed => 'Delivered',
    OrderStatusEnums.cancelled => 'Cancelled',
  };

  /// Parses a backend status string; falls back to [pending] for unknown values.
  static OrderStatusEnums fromValue(String s) => OrderStatusEnums.values
      .firstWhere((e) => e.value == s, orElse: () => OrderStatusEnums.pending);

  /// The next status in the lifecycle, or null if this is a terminal state.
  OrderStatusEnums? get next => switch (this) {
    OrderStatusEnums.pending => OrderStatusEnums.confirmed,
    OrderStatusEnums.confirmed => OrderStatusEnums.readyForPickup,
    OrderStatusEnums.readyForPickup => OrderStatusEnums.completed,
    _ => null,
  };

  /// The previous status in the lifecycle, or null if there isn't one.
  OrderStatusEnums? get previous => switch (this) {
    OrderStatusEnums.readyForPickup => OrderStatusEnums.confirmed,
    OrderStatusEnums.confirmed => OrderStatusEnums.pending,
    _ => null,
  };
}

// ── Payment ──────────────────────────────────────────────────────────────────

/// Iranian bank/PSP gateways available for online checkout.
///
/// International card networks (Visa/Mastercard) are unusable here,
/// so "pay online" always means a redirect through one of these
/// domestic interbank gateways — never an in-app card-number field, which is
/// not how any of these PSPs integrate (PAN capture stays on the bank's own
/// page). [enabledProviders] is the subset actually wired up to a real API;
/// the rest render as "coming soon" in [enabled] tiles are meant to expand
/// this same list, not restructure the surrounding UI.
enum PspProvider {
  asanPardakht,
  samanSep,
  behpardakhtMellat,
  parsianPec,
  sadad,
  pasargadPep;

  String get displayName => switch (this) {
    PspProvider.asanPardakht => 'Asan Pardakht',
    PspProvider.samanSep => 'Saman (SEP)',
    PspProvider.behpardakhtMellat => 'Behpardakht Mellat',
    PspProvider.parsianPec => 'Parsian (PEC)',
    PspProvider.sadad => 'Sadad',
    PspProvider.pasargadPep => 'Pasargad (PEP)',
  };

  /// The PSPs actually integrated today. Move a provider into this set once
  /// its real API is wired up — no other code needs to change.
  static const enabledProviders = {
    PspProvider.samanSep,
    PspProvider.behpardakhtMellat,
  };

  bool get isEnabled => enabledProviders.contains(this);
}
