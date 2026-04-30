import 'package:aaravpos/core/storage/secure_storage.dart';
import 'package:aaravpos/domain/model/signed_consent_data.dart';
import 'package:aaravpos/domain/repo/booking_repository.dart';
import 'package:aaravpos/presentation/bloc/session/session_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
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

      // ── Step 1: POST appointment or appointment/checkin ───────────────────
      final appointmentId = await _repository.submitBooking(
        session: session,
        firstName: event.firstName,
        lastName: event.lastName,
        email: event.email,
        phone: event.phone,
      );

      debugPrint('✅ BookingBloc: Appointment created — id=$appointmentId');

      // ── Step 2: POST concent/customer-sign for each signed service ────────
      if (event.signedConsents.isNotEmpty) {
        final tenantId = await _secureStorage.getTenantId() ?? '';
        final outletId = await _secureStorage.getOutletId() ?? '';
        final staffId = session.selectedStaff?.id ?? '';
        final customerId = session.selectedCustomerId ?? '';

        for (final entry in event.signedConsents.entries) {
          final signed = entry.value;
          debugPrint(
            '📝 BookingBloc: Signing consent for service ${signed.serviceId} '
            '(type=${signed.signatureType})',
          );
          try {
            await _repository.signConsentAfterBooking(
              tenantId: tenantId,
              appointmentId: appointmentId,
              customerId: customerId,
              serviceIds: [signed.serviceId],
              outletId: outletId,
              consentFormId: signed.consentFormId,
              staffId: staffId,
              signatureType: signed.signatureType,
              imageUrl: signed.imageUrl,
              typedName: signed.typedName,
              isChecked: signed.isChecked,
            );
            debugPrint(
              '✅ BookingBloc: Consent signed for service ${signed.serviceId}',
            );
          } catch (e) {
            // Non-fatal — appointment already created, log and continue
            debugPrint(
              '⚠️ BookingBloc: Consent sign failed for ${signed.serviceId}: $e',
            );
          }
        }
      }

      emit(state.copyWith(
        status: BookingStatus.success,
        bookingId: appointmentId,
      ));
    } catch (e) {
      debugPrint('❌ BookingBloc: Booking failed: $e');
      emit(state.copyWith(
        status: BookingStatus.failure,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}
