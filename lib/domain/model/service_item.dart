import 'package:equatable/equatable.dart';

/// Represents a single channel rule inside a consent rule.
class ConsentChannelRule extends Equatable {
  const ConsentChannelRule({
    required this.channel,
    required this.method,
  });

  /// e.g. 'KIOSK', 'POS', 'ONLINE'
  final String channel;

  /// e.g. 'TYPED_NAME', 'CHECKBOX_ONLY', 'DRAW_SIGNATURE'
  final String method;

  factory ConsentChannelRule.fromJson(Map<String, dynamic> json) {
    return ConsentChannelRule(
      channel: json['channel'] as String? ?? '',
      method: json['method'] as String? ?? 'CHECKBOX_ONLY',
    );
  }

  @override
  List<Object?> get props => [channel, method];
}

/// Represents the consent rule attached to a service.
class ConsentRule extends Equatable {
  const ConsentRule({
    required this.signingFrequency,
    required this.enforcementMode,
    this.channelRules = const [],
  });

  /// 'ONCE_PER_CUSTOMER' | 'EVERY_VISIT'
  final String signingFrequency;

  /// 'FIXED' | 'MULTIPLE'
  final String enforcementMode;

  final List<ConsentChannelRule> channelRules;

  factory ConsentRule.fromJson(Map<String, dynamic> json) {
    final rawChannels = json['channelRules'] as List<dynamic>? ?? [];
    return ConsentRule(
      signingFrequency: json['signingFrequency'] as String? ?? 'EVERY_VISIT',
      enforcementMode: json['enforcementMode'] as String? ?? 'FIXED',
      channelRules: rawChannels
          .whereType<Map<String, dynamic>>()
          .map(ConsentChannelRule.fromJson)
          .toList(),
    );
  }

  /// Returns the signing method for the KIOSK channel, or null if not found.
  String? get kioskMethod {
    final idx = channelRules.indexWhere((r) => r.channel == 'KIOSK');
    if (idx == -1) return null;
    return channelRules[idx].method;
  }

  @override
  List<Object?> get props => [signingFrequency, enforcementMode, channelRules];
}

class ServiceItem extends Equatable {
  const ServiceItem({
    required this.id,
    required this.name,
    required this.category,
    required this.categoryId,
    required this.durationMin,
    required this.price,
    this.priceMode = 'FIXED',
    this.minPrice = 0.0,
    this.maxPrice = 0.0,
    this.consentRequired = false,
    this.consentFormId,
    this.consentRule,
    this.signingFrequency,
  });

  final String id;
  final String name;
  final String category;
  final String categoryId;
  final int durationMin;

  /// Display price — for FIXED this is the fixed price,
  /// for RANGE this is min_price (used as starting price).
  final double price;

  final String priceMode; // 'FIXED' | 'RANGE'
  final double minPrice;
  final double maxPrice;
  final bool consentRequired;
  final String? consentFormId;

  /// Full consent rule with signing frequency, enforcement mode, channel rules.
  final ConsentRule? consentRule;

  /// Convenience shortcut — mirrors consentRule.signingFrequency.
  final String? signingFrequency;

  /// Human-readable price string e.g. "$50" or "$35 – $57"
  String get displayPrice {
    if (priceMode == 'RANGE') {
      return '\$${minPrice.toStringAsFixed(0)} – \$${maxPrice.toStringAsFixed(0)}';
    }
    return '\$${price.toStringAsFixed(0)}';
  }

  /// True when this service requires a consent dialog to be shown.
  /// Per spec §5.1: requiresConsent == true AND consentFormId != null AND consentRule != null.
  bool get needsConsentDialog =>
      consentRequired &&
      consentFormId != null &&
      consentFormId!.isNotEmpty &&
      consentRule != null;

  factory ServiceItem.fromJson(
    Map<String, dynamic> json, {
    required String categoryName,
    required String categoryId,
  }) {
    final priceMode = json['price_mode'] as String? ?? 'FIXED';
    final timeMode = json['time_mode'] as String? ?? 'FIXED';

    // Price: FIXED → "price" field; RANGE → use min_price as display price
    double price = 0.0;
    double minPrice = 0.0;
    double maxPrice = 0.0;

    if (priceMode == 'RANGE') {
      minPrice = double.tryParse(json['min_price']?.toString() ?? '') ?? 0.0;
      maxPrice = double.tryParse(json['max_price']?.toString() ?? '') ?? 0.0;
      price = minPrice;
    } else {
      price = double.tryParse(json['price']?.toString() ?? '') ?? 0.0;
    }

    // Duration: Try estimated_time first, then min_time for RANGE mode
    int duration = 0;
    if (json['estimated_time'] != null) {
      duration = (json['estimated_time'] as num?)?.toInt() ?? 0;
    } else if (timeMode == 'RANGE' && json['min_time'] != null) {
      duration = (json['min_time'] as num?)?.toInt() ?? 0;
    }

    // Parse consent rule if present
    ConsentRule? consentRule;
    final rawConsentRule = json['consentRule'] ?? json['consent_rule'];
    if (rawConsentRule is Map<String, dynamic>) {
      consentRule = ConsentRule.fromJson(rawConsentRule);
    }

    final signingFrequency =
        consentRule?.signingFrequency ??
        json['signing_frequency'] as String?;

    return ServiceItem(
      id: json['id'] as String? ?? '',
      name: (json['name'] as String? ?? '').trim(),
      category: categoryName,
      categoryId: categoryId,
      durationMin: duration,
      price: price,
      priceMode: priceMode,
      minPrice: minPrice,
      maxPrice: maxPrice,
      consentRequired: json['requires_consent'] as bool? ?? false,
      consentFormId: json['consent_form_id'] as String?,
      consentRule: consentRule,
      signingFrequency: signingFrequency,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    category,
    durationMin,
    price,
    consentRequired,
    consentFormId,
    signingFrequency,
  ];
}
