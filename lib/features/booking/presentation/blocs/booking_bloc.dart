import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/booking_repository.dart';

part 'booking_event.dart';
part 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  BookingBloc(this._repository) : super(const BookingState()) {
    on<BookingSubmitted>(_onBookingSubmitted);
  }

  final BookingRepository _repository;

  Future<void> _onBookingSubmitted(
    BookingSubmitted event,
    Emitter<BookingState> emit,
  ) async {
    emit(state.copyWith(status: BookingStatus.loading, errorMessage: null));
    try {
      final bookingId = await _repository.submitBooking();
      emit(state.copyWith(status: BookingStatus.success, bookingId: bookingId));
    } catch (_) {
      emit(
        state.copyWith(
          status: BookingStatus.failure,
          errorMessage: 'Booking failed',
        ),
      );
    }
  }

  Future<void> submitBooking() async => add(const BookingSubmitted());
}
