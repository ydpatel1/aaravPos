import 'package:equatable/equatable.dart';

class SlotItem extends Equatable {
  const SlotItem({
    required this.id,
    required this.startTime,
    required this.available,
  });

  final String id;
  final String startTime;
  final bool available;

  factory SlotItem.fromJson(Map<String, dynamic> json) {
    return SlotItem(
      id: json['id'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      available: json['available'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, startTime, available];
}
