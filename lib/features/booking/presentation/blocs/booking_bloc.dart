import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/booking_repository.dart';

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

class BookingBloc extends Cubit<BookingState> {
  BookingBloc(this._repository) : super(const BookingState());

  final BookingRepository _repository;

  Future<void> submitBooking() async {
    emit(state.copyWith(status: BookingStatus.loading, errorMessage: null));
    try {
      final bookingId = await _repository.submitBooking();
      emit(state.copyWith(status: BookingStatus.success, bookingId: bookingId));
    } catch (_) {
      emit(state.copyWith(status: BookingStatus.failure, errorMessage: 'Booking failed'));
    }
  }
}
