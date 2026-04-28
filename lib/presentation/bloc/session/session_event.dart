part of 'session_bloc.dart';

abstract class SessionEvent extends Equatable {
  const SessionEvent();

  @override
  List<Object?> get props => [];
}

class SessionModeChanged extends SessionEvent {
  const SessionModeChanged(this.mode);

  final BookingMode mode;

  @override
  List<Object?> get props => [mode];
}

class SessionServiceToggled extends SessionEvent {
  const SessionServiceToggled(this.service);

  final ServiceItem service;

  @override
  List<Object?> get props => [service];
}

class SessionStaffChanged extends SessionEvent {
  const SessionStaffChanged(this.staff);

  final StaffMember staff;

  @override
  List<Object?> get props => [staff];
}

class SessionDateChanged extends SessionEvent {
  const SessionDateChanged(this.date);

  final DateTime date;

  @override
  List<Object?> get props => [date];
}

class SessionSlotChanged extends SessionEvent {
  const SessionSlotChanged(this.slot);

  final SlotItem slot;

  @override
  List<Object?> get props => [slot];
}

class SessionCustomerChanged extends SessionEvent {
  const SessionCustomerChanged(this.customer, {this.customerId});

  final String customer;
  final String? customerId;

  @override
  List<Object?> get props => [customer, customerId];
}

class SessionResetRequested extends SessionEvent {
  const SessionResetRequested();
}

class SessionOutletStatusLoaded extends SessionEvent {
  const SessionOutletStatusLoaded({required this.isOpen});

  final bool isOpen;

  @override
  List<Object?> get props => [isOpen];
}
