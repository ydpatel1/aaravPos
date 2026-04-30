import 'package:equatable/equatable.dart';

class SlotItem extends Equatable {
  const SlotItem({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.available,
    this.isBooked = false,
    this.startUtc,
  });

  final String id;
  final String startTime; // e.g., "13:30"
  final String endTime;   // e.g., "13:45" — from API end_time field
  final bool available;
  final bool isBooked;
  final String? startUtc;

  factory SlotItem.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String? ?? '';
    final isBooked = json['isBooked'] as bool? ?? false;

    return SlotItem(
      id: json['id'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      available: status == 'AVAILABLE' && !isBooked,
      isBooked: isBooked,
      startUtc: json['startUtc'] as String?,
    );
  }

  /// Parse startTime to DateTime for comparison
  /// Assumes startTime is in "HH:mm" format
  DateTime? toDateTime(DateTime date) {
    try {
      final parts = startTime.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return DateTime(date.year, date.month, date.day, hour, minute);
      }
    } catch (e) {
      // If parsing fails, return null
    }
    return null;
  }

  @override
  List<Object?> get props => [id, startTime, endTime, available, isBooked, startUtc];
}
