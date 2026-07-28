class UserPreferencesModel {
  final bool emailNotificationsEnabled;
  final bool marketingEnabled;

  const UserPreferencesModel({
    required this.emailNotificationsEnabled,
    required this.marketingEnabled,
  });

  factory UserPreferencesModel.fromJson(Map<String, dynamic> json) =>
      UserPreferencesModel(
        emailNotificationsEnabled:
            json['emailNotificationsEnabled'] as bool? ?? true,
        marketingEnabled: json['marketingEnabled'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
    'emailNotificationsEnabled': emailNotificationsEnabled,
    'marketingEnabled': marketingEnabled,
  };
}
