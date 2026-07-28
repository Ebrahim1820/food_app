import 'package:food_app/controllers/food_controllers/food_business_controllers/business_partner_controller.dart';
import 'package:food_app/enums/app_enums.dart';
import 'package:food_app/profile_and_orders/orders/models/order_model.dart';
import 'package:food_app/profile_and_orders/orders/models/order_model_ui.dart';
import 'package:food_app/profile_and_orders/orders/services/order_service.dart';
import 'package:food_app/utils/app_logger.dart';
import 'package:get/get.dart';

class BusinessOrderHistoryController extends GetxController {
  BusinessOrderHistoryController(this._service);

  final OrderService _service;
  static const _tag = 'BusinessOrderHistoryController';
  static const int _pageSize = 20;

  final preset = HistoryDatePreset.today.obs;
  final dateFrom = Rxn<DateTime>();
  final dateTo = Rxn<DateTime>();
  final statusFilter = HistoryStatusFilter.all.obs;
  final searchQuery = ''.obs;

  final orders = <OrderModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = false.obs;
  final totalItems = 0.obs;
  final errorMessage = ''.obs;

  int _nextPage = 1;

  double get totalRevenue => orders
      .where((o) => o.status != 'cancelled')
      .fold(0.0, (sum, o) => sum + o.totalPriceValue);

  int get completedCount => orders
      .where((o) => o.status == 'completed' || o.status == 'delivered')
      .length;

  int get cancelledCount => orders.where((o) => o.status == 'cancelled').length;

  List<OrderModel> get filteredOrders {
    final q = searchQuery.value.trim().toLowerCase();
    final filter = statusFilter.value;
    return orders.where((o) {
      if (!filter.matches(o.status)) return false;
      if (q.isEmpty) return true;
      final name = '${o.user?.firstName ?? ''} ${o.user?.lastName ?? ''}'
          .toLowerCase();
      return name.contains(q) || o.id.toLowerCase().contains(q);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    selectPreset(HistoryDatePreset.today);
  }

  void selectPreset(HistoryDatePreset p) {
    preset.value = p;
    final range = p.range;
    if (range != null) {
      dateFrom.value = range.$1;
      dateTo.value = range.$2;
    }
    refresh();
  }

  void setCustomRange(DateTime from, DateTime to) {
    preset.value = HistoryDatePreset.custom;
    dateFrom.value = from;
    dateTo.value = to;
    refresh();
  }

  @override
  void refresh() {
    _nextPage = 1;
    orders.clear();
    errorMessage.value = '';
    isLoading.value = true;
    _loadPage().whenComplete(() => isLoading.value = false);
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isLoadingMore.value) return;
    isLoadingMore.value = true;
    await _loadPage();
    isLoadingMore.value = false;
  }

  Future<void> _loadPage() async {
    final from = dateFrom.value;
    final to = dateTo.value;
    if (from == null || to == null) return;

    final bpCtrl = Get.find<BusinessPartnerController>();
    final partnerIri = bpCtrl.partner.value?.iri;
    if (partnerIri == null) {
      errorMessage.value = 'Partner not loaded';
      return;
    }

    try {
      final result = await _service.getOrderHistory(
        businessPartnerIri: partnerIri,
        dateFrom: from,
        dateTo: to,
        page: _nextPage,
        itemsPerPage: _pageSize,
      );
      orders.addAll(result.orders);
      totalItems.value = result.total;
      hasMore.value = result.hasNext;
      _nextPage++;
    } catch (e, st) {
      AppLogger.error(
        _tag,
        'Failed to load history page',
        error: e,
        stackTrace: st,
      );
      errorMessage.value = 'orderHistory_errorTitle'.tr;
    }
  }
}
