part of 'booking_bloc.dart';

enum BookingStatus { initial, loading, success, failure }

class BookingState extends Equatable {
  const BookingState({
    this.status = BookingStatus.initial,
    this.bookingId,
    this.customerId,
    this.appointmentDetails,
    this.errorMessage,
  });

  final BookingStatus status;
  final String? bookingId;
  final String? customerId;

  /// Raw appointment details map passed to the confirmation screen.
  final Map<String, dynamic>? appointmentDetails;

  final String? errorMessage;

  BookingState copyWith({
    BookingStatus? status,
    String? bookingId,
    String? customerId,
    Map<String, dynamic>? appointmentDetails,
    String? errorMessage,
  }) {
    return BookingState(
      status: status ?? this.status,
      bookingId: bookingId ?? this.bookingId,
      customerId: customerId ?? this.customerId,
      appointmentDetails: appointmentDetails ?? this.appointmentDetails,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, bookingId, customerId, appointmentDetails, errorMessage];
}
