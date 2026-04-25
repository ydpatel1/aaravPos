import 'package:equatable/equatable.dart';

class SlotItem extends Equatable {
  const SlotItem({required this.time, required this.period});

  final String time;
  final String period;

  @override
  List<Object?> get props => [time, period];
}
