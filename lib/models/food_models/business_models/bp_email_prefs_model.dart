/// Mirrors BusinessPartnerEmailPreferences PHP entity.
/// Defaults match the server-side entity defaults.
class BpEmailPrefsModel {
  final bool emailDailySummary;
  final bool emailWeeklyReport;
  final bool emailMonthlyReport;
  final bool emailOrderConfirmation;
  final bool emailRefundAlert;
  final bool emailNewReview;
  final bool emailLowRatingAlert;

  const BpEmailPrefsModel({
    required this.emailDailySummary,
    required this.emailWeeklyReport,
    required this.emailMonthlyReport,
    required this.emailOrderConfirmation,
    required this.emailRefundAlert,
    required this.emailNewReview,
    required this.emailLowRatingAlert,
  });

  factory BpEmailPrefsModel.fromJson(Map<String, dynamic> json) =>
      BpEmailPrefsModel(
        emailDailySummary: json['emailDailySummary'] as bool? ?? true,
        emailWeeklyReport: json['emailWeeklyReport'] as bool? ?? true,
        emailMonthlyReport: json['emailMonthlyReport'] as bool? ?? false,
        emailOrderConfirmation:
            json['emailOrderConfirmation'] as bool? ?? false,
        emailRefundAlert: json['emailRefundAlert'] as bool? ?? true,
        emailNewReview: json['emailNewReview'] as bool? ?? true,
        emailLowRatingAlert: json['emailLowRatingAlert'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
    'emailDailySummary': emailDailySummary,
    'emailWeeklyReport': emailWeeklyReport,
    'emailMonthlyReport': emailMonthlyReport,
    'emailOrderConfirmation': emailOrderConfirmation,
    'emailRefundAlert': emailRefundAlert,
    'emailNewReview': emailNewReview,
    'emailLowRatingAlert': emailLowRatingAlert,
  };
}
