import 'package:aaravpos/core/storage/secure_storage.dart';
import 'package:aaravpos/domain/repo/booking_repository.dart';
import 'package:aaravpos/presentation/bloc/session/session_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'booking_event.dart';
part 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  BookingBloc(this._repository, this._secureStorage)
    : super(const BookingState()) {
    on<BookingSubmitted>(_onBookingSubmitted);
  }

  final BookingRepository _repository;
  final SecureStorage _secureStorage;

  Future<void> _onBookingSubmitted(
    BookingSubmitted event,
    Emitter<BookingState> emit,
  ) async {
    emit(state.copyWith(status: BookingStatus.loading, errorMessage: null));
    try {
      final session = event.session as SessionState;

      // Step 1: POST appointment / appointment/checkin
      final appointmentId = await _repository.submitBooking(
        session: session,
        firstName: event.firstName,
        lastName: event.lastName,
        email: event.email,
        phone: event.phone,
      );

      // Step 2: If consent was signed, POST consent/customer-sign with appointmentId
      if (event.consentFormId != null &&
          event.consentFormId!.isNotEmpty &&
          event.signatureType != null) {
        final tenantId = await _secureStorage.getTenantId() ?? '';
        final outletId = await _secureStorage.getOutletId() ?? '';
        final staffId = session.selectedStaff?.id ?? '';
        final customerId = session.selectedCustomerId ?? '';
        final serviceIds = session.selectedServices.map((s) => s.id).toList();

        await _repository.signConsentAfterBooking(
          tenantId: tenantId,
          appointmentId: appointmentId,
          customerId: customerId,
          serviceIds: serviceIds,
          outletId: outletId,
          consentFormId: event.consentFormId!,
          staffId: staffId,
          signatureType: event.signatureType!,
          imageUrl: event.imageUrl,
          typedName: event.typedName,
          isChecked: event.isChecked,
        );
      }

      emit(
        state.copyWith(status: BookingStatus.success, bookingId: appointmentId),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BookingStatus.failure,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  void submitBooking({
    required SessionState session,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    String? consentFormId,
    String? signatureType,
    String? imageUrl,
    String? typedName,
    bool isChecked = false,
  }) => add(
    BookingSubmitted(
      session: session,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      consentFormId: consentFormId,
      signatureType: signatureType,
      imageUrl: imageUrl,
      typedName: typedName,
      isChecked: isChecked,
    ),
  );
}
