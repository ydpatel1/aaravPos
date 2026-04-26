part of 'slot_bloc.dart';

abstract class SlotEvent extends Equatable {
  const SlotEvent();

  @override
  List<Object?> get props => [];
}

class SlotsFetched extends SlotEvent {
  const SlotsFetched({required this.staffId, required this.selectedDate});

  final String staffId;
  final DateTime selectedDate;

  @override
  List<Object?> get props => [staffId, selectedDate];
}
