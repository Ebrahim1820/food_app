/// One market tile on the Dashboard screen (or a live entry in the
/// registration screen's business-market dropdown).
class DashboardMarket {
  final String key;
  final String label;
  final bool enabled;
  final bool businessRegistrationEnabled;
  final List<String> heroImages;

  const DashboardMarket({
    required this.key,
    required this.label,
    required this.enabled,
    required this.businessRegistrationEnabled,
    required this.heroImages,
  });

  factory DashboardMarket.fromJson(Map<String, dynamic> json) {
    return DashboardMarket(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? false,
      businessRegistrationEnabled:
          json['businessRegistrationEnabled'] as bool? ?? false,
      heroImages:
          (json['heroImages'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    'enabled': enabled,
    'businessRegistrationEnabled': businessRegistrationEnabled,
    'heroImages': heroImages,
  };
}

/// A "coming soon" market — display-only, no backing code yet.
class DashboardComingSoonEntry {
  final String key;
  final String label;

  const DashboardComingSoonEntry({required this.key, required this.label});

  factory DashboardComingSoonEntry.fromJson(Map<String, dynamic> json) {
    return DashboardComingSoonEntry(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'key': key, 'label': label};
}

/// GET /dashboard response — the market tiles the Dashboard screen and the
/// registration business-market dropdown are both built from.
class DashboardModel {
  final List<DashboardMarket> markets;
  final List<DashboardComingSoonEntry> comingSoon;

  const DashboardModel({required this.markets, required this.comingSoon});

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      markets:
          (json['markets'] as List<dynamic>?)
              ?.map((e) => DashboardMarket.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      comingSoon:
          (json['comingSoon'] as List<dynamic>?)
              ?.map(
                (e) => DashboardComingSoonEntry.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'markets': markets.map((m) => m.toJson()).toList(),
    'comingSoon': comingSoon.map((c) => c.toJson()).toList(),
  };
}
