/// Mirrors BusinessPartnerNotificationPreferences PHP entity.
/// Defaults match the server-side entity defaults.
class BpNotifPrefsModel {
  final bool notifyNewOrder;
  final bool notifyOrderReady;
  final bool notifyOrderCancelled;
  final bool notifyNewReview;
  final bool notifyReviewReply;
  final bool notifyPromotions;
  final bool notifyGrowthTips;
  final bool notifyMaintenanceAlerts;
  final bool notifyAppUpdates;

  const BpNotifPrefsModel({
    required this.notifyNewOrder,
    required this.notifyOrderReady,
    required this.notifyOrderCancelled,
    required this.notifyNewReview,
    required this.notifyReviewReply,
    required this.notifyPromotions,
    required this.notifyGrowthTips,
    required this.notifyMaintenanceAlerts,
    required this.notifyAppUpdates,
  });

  factory BpNotifPrefsModel.fromJson(Map<String, dynamic> json) =>
      BpNotifPrefsModel(
        notifyNewOrder: json['notifyNewOrder'] as bool? ?? true,
        notifyOrderReady: json['notifyOrderReady'] as bool? ?? true,
        notifyOrderCancelled: json['notifyOrderCancelled'] as bool? ?? true,
        notifyNewReview: json['notifyNewReview'] as bool? ?? true,
        notifyReviewReply: json['notifyReviewReply'] as bool? ?? false,
        notifyPromotions: json['notifyPromotions'] as bool? ?? false,
        notifyGrowthTips: json['notifyGrowthTips'] as bool? ?? true,
        notifyMaintenanceAlerts:
            json['notifyMaintenanceAlerts'] as bool? ?? true,
        notifyAppUpdates: json['notifyAppUpdates'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
    'notifyNewOrder': notifyNewOrder,
    'notifyOrderReady': notifyOrderReady,
    'notifyOrderCancelled': notifyOrderCancelled,
    'notifyNewReview': notifyNewReview,
    'notifyReviewReply': notifyReviewReply,
    'notifyPromotions': notifyPromotions,
    'notifyGrowthTips': notifyGrowthTips,
    'notifyMaintenanceAlerts': notifyMaintenanceAlerts,
    'notifyAppUpdates': notifyAppUpdates,
  };
}
