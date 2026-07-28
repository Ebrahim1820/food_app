class AdminStats {
  final int totalPartners;
  final int totalCustomers;
  final int totalOffers;
  final int totalOrders;
  final int pendingOrders;
  final int cancelledOrders;

  const AdminStats({
    required this.totalPartners,
    required this.totalCustomers,
    required this.totalOffers,
    required this.totalOrders,
    required this.pendingOrders,
    required this.cancelledOrders,
  });

  static const empty = AdminStats(
    totalPartners: 0,
    totalCustomers: 0,
    totalOffers: 0,
    totalOrders: 0,
    pendingOrders: 0,
    cancelledOrders: 0,
  );

  int get activeOrders =>
      (totalOrders - pendingOrders - cancelledOrders).clamp(0, totalOrders);

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
    totalPartners: json['totalPartners'] as int? ?? 0,
    totalCustomers: json['totalCustomers'] as int? ?? 0,
    totalOffers: json['totalOffers'] as int? ?? 0,
    totalOrders: json['totalOrders'] as int? ?? 0,
    pendingOrders: json['pendingOrders'] as int? ?? 0,
    cancelledOrders: json['cancelledOrders'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'totalPartners': totalPartners,
    'totalCustomers': totalCustomers,
    'totalOffers': totalOffers,
    'totalOrders': totalOrders,
    'pendingOrders': pendingOrders,
    'cancelledOrders': cancelledOrders,
  };
}
