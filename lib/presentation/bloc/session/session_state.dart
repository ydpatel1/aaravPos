part of 'session_bloc.dart';

enum BookingMode { appointment, checkIn }

class SessionState extends Equatable {
  const SessionState({
    this.mode = BookingMode.appointment,
    this.isCheckIn = false,
    this.isOutletOpen = false,
    this.outletOpenTime = '',
    this.selectedServices = const <ServiceItem>[],
    this.selectedStaff,
    this.selectedDate,
    this.selectedSlot,
    this.selectedSlotIds = const <String>[],
    this.selectedStartTime,
    this.selectedEndTime,
    this.selectedCustomer,
    this.selectedCustomerId,
  });

  final BookingMode mode;
  final bool isCheckIn;
  final bool isOutletOpen;

  /// Raw openTime from the API — used to show "Opens at HH:mm" when closed.
  final String outletOpenTime;
  final List<ServiceItem> selectedServices;
  final StaffMember? selectedStaff;
  final DateTime? selectedDate;

  /// The first (start) slot — used for display only.
  final SlotItem? selectedSlot;

  /// All slot IDs in the selected range — sent to the booking API.
  final List<String> selectedSlotIds;

  /// ISO8601 start datetime from the first slot.
  final String? selectedStartTime;

  /// ISO8601 end datetime from the last slot's endTime field.
  final String? selectedEndTime;

  final String? selectedCustomer;
  final String? selectedCustomerId;

  // ── Computed helpers ────────────────────────────────────────────────────────

  /// Total duration of all selected services in minutes.
  int get totalDuration =>
      selectedServices.fold(0, (sum, s) => sum + s.durationMin);

  /// Number of 15-min slots needed to cover all services.
  int get slotsNeeded => (totalDuration / 15).ceil().clamp(1, 999);

  double get totalPrice =>
      selectedServices.fold(0.0, (sum, s) => sum + s.price);

  String get formattedTotal => '\$${totalPrice.toStringAsFixed(2)}';

  SessionState copyWith({
    BookingMode? mode,
    bool? isCheckIn,
    bool? isOutletOpen,
    String? outletOpenTime,
    List<ServiceItem>? selectedServices,
    StaffMember? selectedStaff,
    DateTime? selectedDate,
    SlotItem? selectedSlot,
    List<String>? selectedSlotIds,
    String? selectedStartTime,
    String? selectedEndTime,
    String? selectedCustomer,
    String? selectedCustomerId,
    bool clearStaff = false,
    bool clearDate = false,
    bool clearSlot = false,
    bool clearCustomer = false,
    bool clearServices = false,
  }) {
    return SessionState(
      mode: mode ?? this.mode,
      isCheckIn: isCheckIn ?? this.isCheckIn,
      isOutletOpen: isOutletOpen ?? this.isOutletOpen,
      outletOpenTime: outletOpenTime ?? this.outletOpenTime,
      selectedServices: clearServices
          ? const []
          : selectedServices ?? this.selectedServices,
      selectedStaff: clearStaff ? null : selectedStaff ?? this.selectedStaff,
      selectedDate: clearDate ? null : selectedDate ?? this.selectedDate,
      selectedSlot: clearSlot ? null : selectedSlot ?? this.selectedSlot,
      selectedSlotIds:
          clearSlot ? const [] : selectedSlotIds ?? this.selectedSlotIds,
      selectedStartTime:
          clearSlot ? null : selectedStartTime ?? this.selectedStartTime,
      selectedEndTime:
          clearSlot ? null : selectedEndTime ?? this.selectedEndTime,
      selectedCustomer: clearCustomer
          ? null
          : selectedCustomer ?? this.selectedCustomer,
      selectedCustomerId: clearCustomer
          ? null
          : selectedCustomerId ?? this.selectedCustomerId,
    );
  }

  @override
  List<Object?> get props => [
    mode,
    isCheckIn,
    isOutletOpen,
    outletOpenTime,
    selectedServices,
    selectedStaff,
    selectedDate,
    selectedSlot,
    selectedSlotIds,
    selectedStartTime,
    selectedEndTime,
    selectedCustomer,
    selectedCustomerId,
  ];
}
