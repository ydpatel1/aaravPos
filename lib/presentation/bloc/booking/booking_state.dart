part of 'booking_bloc.dart';

enum BookingStatus { initial, loading, success, failure }

class BookingState extends Equatable {
  const BookingState({
    this.status = BookingStatus.initial,
    this.bookingId,
    this.errorMessage,
  });

  final BookingStatus status;
  final String? bookingId;
  final String? errorMessage;

  BookingState copyWith({
    BookingStatus? status,
    String? bookingId,
    String? errorMessage,
  }) {
    return BookingState(
      status: status ?? this.status,
      bookingId: bookingId ?? this.bookingId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, bookingId, errorMessage];
}
