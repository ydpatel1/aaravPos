import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/service_item.dart';
import '../../domain/slot_item.dart';
import '../../domain/staff_member.dart';

enum BookingMode { appointment, checkIn }

class SessionState extends Equatable {
  const SessionState({
    this.mode = BookingMode.appointment,
    this.selectedServices = const <ServiceItem>[],
    this.selectedStaff,
    this.selectedDate,
    this.selectedSlot,
    this.selectedCustomer,
  });

  final BookingMode mode;
  final List<ServiceItem> selectedServices;
  final StaffMember? selectedStaff;
  final DateTime? selectedDate;
  final SlotItem? selectedSlot;
  final String? selectedCustomer;

  SessionState copyWith({
    BookingMode? mode,
    List<ServiceItem>? selectedServices,
    StaffMember? selectedStaff,
    DateTime? selectedDate,
    SlotItem? selectedSlot,
    String? selectedCustomer,
    bool clearStaff = false,
    bool clearDate = false,
    bool clearSlot = false,
    bool clearCustomer = false,
  }) {
    return SessionState(
      mode: mode ?? this.mode,
      selectedServices: selectedServices ?? this.selectedServices,
      selectedStaff: clearStaff ? null : selectedStaff ?? this.selectedStaff,
      selectedDate: clearDate ? null : selectedDate ?? this.selectedDate,
      selectedSlot: clearSlot ? null : selectedSlot ?? this.selectedSlot,
      selectedCustomer: clearCustomer ? null : selectedCustomer ?? this.selectedCustomer,
    );
  }

  @override
  List<Object?> get props => [
        mode,
        selectedServices,
        selectedStaff,
        selectedDate,
        selectedSlot,
        selectedCustomer,
      ];
}

class SessionCubit extends Cubit<SessionState> {
  SessionCubit() : super(const SessionState());

  void setMode(BookingMode mode) => emit(state.copyWith(mode: mode));

  void toggleService(ServiceItem service) {
    final services = List<ServiceItem>.from(state.selectedServices);
    if (services.contains(service)) {
      services.remove(service);
    } else {
      services.add(service);
    }
    emit(state.copyWith(selectedServices: services));
  }

  void setStaff(StaffMember staff) => emit(state.copyWith(selectedStaff: staff));

  void setDate(DateTime date) => emit(state.copyWith(selectedDate: date));

  void setSlot(SlotItem slot) => emit(state.copyWith(selectedSlot: slot));

  void setCustomer(String customer) => emit(state.copyWith(selectedCustomer: customer));

  void reset() => emit(const SessionState());
}
