import 'package:equatable/equatable.dart';

// ── Consent sub-models ────────────────────────────────────────────────────────

class ConsentTemplate {
  const ConsentTemplate({required this.heading, required this.consent});

  /// Dialog title — from service.consent_template.heading
  final String heading;

  /// Dialog body text — from service.consent_template.consent
  final String consent;

  factory ConsentTemplate.fromJson(Map<String, dynamic> json) {
    return ConsentTemplate(
      heading: json['heading'] as String? ?? '',
      consent: json['consent'] as String? ?? '',
    );
  }
}

class ConsentChannelRule {
  const ConsentChannelRule({required this.channel, required this.method});

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
}

class ConsentRule {
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

  /// Signing method for the KIOSK channel (what the dialog shows).
  /// Falls back to CHECKBOX_ONLY if no KIOSK rule found.
  String get kioskMethod {
    final idx = channelRules.indexWhere((r) => r.channel == 'KIOSK');
    if (idx == -1) return 'CHECKBOX_ONLY';
    return channelRules[idx].method;
  }
}

// ── ServiceItem ───────────────────────────────────────────────────────────────

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
    this.consentTemplate,
    this.consentRule,
  });

  final String id;
  final String name;
  final String category;
  final String categoryId;
  final int durationMin;

  final double price;
  final String priceMode; // 'FIXED' | 'RANGE'
  final double minPrice;
  final double maxPrice;

  final bool consentRequired;

  /// ID used in GET concent/check/{customerId}/{consentFormId}
  final String? consentFormId;

  /// Heading + body text shown in the consent dialog.
  /// Source: service.consent_template from the services API.
  final ConsentTemplate? consentTemplate;

  /// Signing frequency, enforcement mode, channel rules.
  /// Source: service.consentRule from the services API.
  final ConsentRule? consentRule;

  // ── Computed helpers ────────────────────────────────────────────────────────

  String get signingFrequency =>
      consentRule?.signingFrequency ?? 'EVERY_VISIT';

  /// Signing method for the KIOSK channel — controls which input the dialog shows.
  String get kioskSigningMethod => consentRule?.kioskMethod ?? 'CHECKBOX_ONLY';

  /// True when this service needs a consent dialog.
  /// Requires: consentRequired AND consentFormId AND consentRule all present.
  bool get needsConsentDialog =>
      consentRequired &&
      consentFormId != null &&
      consentFormId!.isNotEmpty &&
      consentRule != null;

  /// Dialog title — from consentTemplate.heading, fallback hardcoded.
  String get consentDialogTitle =>
      (consentTemplate?.heading.isNotEmpty == true)
          ? consentTemplate!.heading
          : 'Consent Form Title';

  /// Dialog body — from consentTemplate.consent, fallback hardcoded.
  String get consentDialogBody =>
      (consentTemplate?.consent.isNotEmpty == true)
          ? consentTemplate!.consent
          : 'I confirm that I have read and understood the details of the service '
              'being provided. I voluntarily agree to receive the service and '
              'acknowledge that the outlet has explained the process, benefits, '
              'and any possible risks involved.\n\n'
              'I understand that results may vary and I release the outlet and its '
              'staff from any responsibility arising from unforeseen reactions or '
              'outcomes. I also confirm that the information provided by me is '
              'accurate to the best of my knowledge.\n\n'
              'By signing below, I provide my consent to proceed with the service.';

  /// Human-readable price string e.g. "\$50" or "\$35 – \$57"
  String get displayPrice {
    if (priceMode == 'RANGE') {
      return '\$${minPrice.toStringAsFixed(0)} – \$${maxPrice.toStringAsFixed(0)}';
    }
    return '\$${price.toStringAsFixed(0)}';
  }

  // ── fromJson ────────────────────────────────────────────────────────────────

  factory ServiceItem.fromJson(
    Map<String, dynamic> json, {
    required String categoryName,
    required String categoryId,
  }) {
    final priceMode = json['price_mode'] as String? ?? 'FIXED';
    final timeMode = json['time_mode'] as String? ?? 'FIXED';

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

    int duration = 0;
    if (json['estimated_time'] != null) {
      duration = (json['estimated_time'] as num?)?.toInt() ?? 0;
    } else if (timeMode == 'RANGE' && json['min_time'] != null) {
      duration = (json['min_time'] as num?)?.toInt() ?? 0;
    }

    // Parse consent_template — keys: heading, consent
    ConsentTemplate? consentTemplate;
    final rawTemplate = json['consent_template'] ?? json['consentTemplate'];
    if (rawTemplate is Map<String, dynamic>) {
      consentTemplate = ConsentTemplate.fromJson(rawTemplate);
    }

    // Parse consentRule — keys: signingFrequency, enforcementMode, channelRules
    ConsentRule? consentRule;
    final rawRule = json['consentRule'] ?? json['consent_rule'];
    if (rawRule is Map<String, dynamic>) {
      consentRule = ConsentRule.fromJson(rawRule);
    }

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
      consentTemplate: consentTemplate,
      consentRule: consentRule,
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
  ];
}
