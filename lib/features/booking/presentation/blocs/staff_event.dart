part of 'staff_bloc.dart';

abstract class StaffEvent extends Equatable {
  const StaffEvent();

  @override
  List<Object?> get props => [];
}

class StaffFetched extends StaffEvent {
  const StaffFetched();
}
