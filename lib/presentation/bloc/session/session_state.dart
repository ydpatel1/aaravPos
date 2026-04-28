part of 'session_bloc.dart';

enum BookingMode { appointment, checkIn }

class SessionState extends Equatable {
  const SessionState({
    this.mode = BookingMode.appointment,
    this.isCheckIn = false,
    this.isOutletOpen = false,
    this.selectedServices = const <ServiceItem>[],
    this.selectedStaff,
    this.selectedDate,
    this.selectedSlot,
    this.selectedCustomer,
    this.selectedCustomerId,
  });

  final BookingMode mode;
  final bool isCheckIn;

  /// Reflects isOpen from outlet/status API.
  /// When false, the Check-In button on HomeScreen is disabled.
  final bool isOutletOpen;

  final List<ServiceItem> selectedServices;
  final StaffMember? selectedStaff;
  final DateTime? selectedDate;
  final SlotItem? selectedSlot;
  final String? selectedCustomer; // display name
  final String? selectedCustomerId; // actual UUID for API calls

  SessionState copyWith({
    BookingMode? mode,
    bool? isCheckIn,
    bool? isOutletOpen,
    List<ServiceItem>? selectedServices,
    StaffMember? selectedStaff,
    DateTime? selectedDate,
    SlotItem? selectedSlot,
    String? selectedCustomer,
    String? selectedCustomerId,
    bool clearStaff = false,
    bool clearDate = false,
    bool clearSlot = false,
    bool clearCustomer = false,
  }) {
    return SessionState(
      mode: mode ?? this.mode,
      isCheckIn: isCheckIn ?? this.isCheckIn,
      isOutletOpen: isOutletOpen ?? this.isOutletOpen,
      selectedServices: selectedServices ?? this.selectedServices,
      selectedStaff: clearStaff ? null : selectedStaff ?? this.selectedStaff,
      selectedDate: clearDate ? null : selectedDate ?? this.selectedDate,
      selectedSlot: clearSlot ? null : selectedSlot ?? this.selectedSlot,
      selectedCustomer: clearCustomer
          ? null
          : selectedCustomer ?? this.selectedCustomer,
      selectedCustomerId: clearCustomer
          ? null
          : selectedCustomerId ?? this.selectedCustomerId,
    );
  }

  /// Calculate total price from selected services
  double get totalPrice {
    return selectedServices.fold(0.0, (sum, service) => sum + service.price);
  }

  /// Formatted total price string
  String get formattedTotal {
    return '\$${totalPrice.toStringAsFixed(2)}';
  }

  @override
  List<Object?> get props => [
    mode,
    isOutletOpen,
    selectedServices,
    selectedStaff,
    selectedDate,
    selectedSlot,
    selectedCustomer,
    selectedCustomerId,
  ];
}
