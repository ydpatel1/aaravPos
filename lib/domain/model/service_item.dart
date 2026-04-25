import 'package:equatable/equatable.dart';

class ServiceItem extends Equatable {
  const ServiceItem({
    required this.id,
    required this.name,
    required this.category,
    required this.durationMin,
    required this.price,
    this.consentRequired = false,
  });

  final String id;
  final String name;
  final String category;
  final int durationMin;
  final double price;
  final bool consentRequired;

  @override
  List<Object?> get props => [id, name, category, durationMin, price, consentRequired];
}
