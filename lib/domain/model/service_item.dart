import 'package:equatable/equatable.dart';

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

  /// Human-readable price string e.g. "$50" or "$35 – $57"
  String get displayPrice {
    if (priceMode == 'RANGE') {
      return '\$${minPrice.toStringAsFixed(0)} – \$${maxPrice.toStringAsFixed(0)}';
    }
    return '\$${price.toStringAsFixed(0)}';
  }

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
      // For FIXED mode, price can be in 'price' field
      price = double.tryParse(json['price']?.toString() ?? '') ?? 0.0;
    }

    // Duration: Try estimated_time first (from API), then min_time for RANGE mode
    int duration = 0;
    if (json['estimated_time'] != null) {
      duration = (json['estimated_time'] as num?)?.toInt() ?? 0;
    } else if (timeMode == 'RANGE' && json['min_time'] != null) {
      duration = (json['min_time'] as num?)?.toInt() ?? 0;
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
  ];
}
