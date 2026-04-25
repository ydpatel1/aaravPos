import 'package:aaravpos/domain/model/service_item.dart';
import 'package:aaravpos/domain/model/slot_item.dart';
import 'package:aaravpos/domain/model/staff_member.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


part 'session_event.dart';
part 'session_state.dart';

class SessionBloc extends Bloc<SessionEvent, SessionState> {
  SessionBloc() : super(const SessionState()) {
    on<SessionModeChanged>(_onModeChanged);
    on<SessionServiceToggled>(_onServiceToggled);
    on<SessionStaffChanged>(_onStaffChanged);
    on<SessionDateChanged>(_onDateChanged);
    on<SessionSlotChanged>(_onSlotChanged);
    on<SessionCustomerChanged>(_onCustomerChanged);
    on<SessionResetRequested>(_onResetRequested);
  }

  void _onModeChanged(SessionModeChanged event, Emitter<SessionState> emit) {
    emit(state.copyWith(mode: event.mode));
  }

  void _onServiceToggled(SessionServiceToggled event, Emitter<SessionState> emit) {
    final services = List<ServiceItem>.from(state.selectedServices);
    if (services.contains(event.service)) {
      services.remove(event.service);
    } else {
      services.add(event.service);
    }
    emit(state.copyWith(selectedServices: services));
  }

  void _onStaffChanged(SessionStaffChanged event, Emitter<SessionState> emit) {
    emit(state.copyWith(selectedStaff: event.staff));
  }

  void _onDateChanged(SessionDateChanged event, Emitter<SessionState> emit) {
    emit(state.copyWith(selectedDate: event.date));
  }

  void _onSlotChanged(SessionSlotChanged event, Emitter<SessionState> emit) {
    emit(state.copyWith(selectedSlot: event.slot));
  }

  void _onCustomerChanged(SessionCustomerChanged event, Emitter<SessionState> emit) {
    emit(state.copyWith(selectedCustomer: event.customer));
  }

  void _onResetRequested(SessionResetRequested event, Emitter<SessionState> emit) {
    emit(const SessionState());
  }

  // Compatibility helpers
  void setMode(BookingMode mode) => add(SessionModeChanged(mode));
  void toggleService(ServiceItem service) => add(SessionServiceToggled(service));
  void setStaff(StaffMember staff) => add(SessionStaffChanged(staff));
  void setDate(DateTime date) => add(SessionDateChanged(date));
  void setSlot(SlotItem slot) => add(SessionSlotChanged(slot));
  void setCustomer(String customer) => add(SessionCustomerChanged(customer));
  void reset() => add(const SessionResetRequested());
}
