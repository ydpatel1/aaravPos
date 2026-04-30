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

  // (reserved for future resubmit flow)

  Future<void> _onBookingSubmitted(
    BookingSubmitted event,
    Emitter<BookingState> emit,
  ) async {
    emit(state.copyWith(status: BookingStatus.loading, errorMessage: null));
    try {
      final session = event.session as SessionState;

      // Step 1: POST appointment or appointment/checkin (spec §8)
      final result = await _repository.submitBooking(
        session: session,
        firstName: event.firstName,
        lastName: event.lastName,
        email: event.email,
        phone: event.phone,
        signedConsents: event.signedConsents,
      );

      final appointmentId = result['appointmentId'] as String? ?? '';
      final customerId =
          result['customerId'] as String? ??
          session.selectedCustomerId ??
          '';

      debugPrint('✅ BookingBloc: Appointment created id=$appointmentId');

      // Step 2: POST concent/customer-sign for each signed consent (spec §9)
      if (event.signedConsents.isNotEmpty) {
        final tenantId = await _secureStorage.getTenantId() ?? '';
        final outletId = await _secureStorage.getOutletId() ?? '';
        final staffId = session.selectedStaff?.id ?? '';

        final failedServiceId = await _submitConsentSignatures(
          tenantId: tenantId,
          appointmentId: appointmentId,
          customerId: customerId,
          outletId: outletId,
          staffId: staffId,
          signedConsents: event.signedConsents,
        );

        if (failedServiceId != null) {
          // Consent submission failed — stay on screen (spec §9 failure handling)
          emit(state.copyWith(
            status: BookingStatus.failure,
            bookingId: appointmentId,
            customerId: customerId,
            errorMessage: 'Consent submission failed. Please re-sign.',
          ));
          return;
        }
      }

      // Build appointment details for confirmation screen (spec §11)
      final appointmentDetails = _buildAppointmentDetails(
        result: result,
        session: session,
        firstName: event.firstName,
        lastName: event.lastName,
      );

      emit(state.copyWith(
        status: BookingStatus.success,
        bookingId: appointmentId,
        customerId: customerId,
        appointmentDetails: appointmentDetails,
      ));
    } catch (e) {
      debugPrint('❌ BookingBloc: Booking failed: $e');
      emit(state.copyWith(
        status: BookingStatus.failure,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  /// Submits consent signatures for all signed consents.
  /// Returns the serviceId of the first failure, or null if all succeeded.
  Future<String?> _submitConsentSignatures({
    required String tenantId,
    required String appointmentId,
    required String customerId,
    required String outletId,
    required String staffId,
    required List<SignedConsentData> signedConsents,
  }) async {
    for (final consent in signedConsents) {
      try {
        await _repository.signConsentAfterBooking(
          tenantId: tenantId,
          appointmentId: appointmentId,
          customerId: customerId,
          serviceIds: [consent.serviceId],
          outletId: outletId,
          consentFormId: consent.consentFormId,
          staffId: staffId,
          signatureType: _mapMethodToSignatureType(consent.method),
          imageUrl: consent.method == 'DRAW_SIGNATURE' ? consent.payload : null,
          typedName: consent.method == 'TYPED_NAME' ? consent.payload : null,
          isChecked: consent.method == 'CHECKBOX_ONLY',
        );
        debugPrint('✅ BookingBloc: Consent signed for service ${consent.serviceId}');
      } catch (e) {
        debugPrint('❌ BookingBloc: Consent sign failed for ${consent.serviceId}: $e');
        return consent.serviceId;
      }
    }
    return null;
  }

  /// Maps dialog method name to API signatureType value.
  String _mapMethodToSignatureType(String method) {
    switch (method) {
      case 'DRAW_SIGNATURE':
        return 'SIGNATURE_IMAGE';
      case 'TYPED_NAME':
        return 'TYPED_NAME';
      case 'CHECKBOX_ONLY':
        return 'CHECKBOX_ONLY';
      default:
        return method;
    }
  }

  Map<String, dynamic> _buildAppointmentDetails({
    required Map<String, dynamic> result,
    required SessionState session,
    required String firstName,
    required String lastName,
  }) {
    return {
      'apiResponse': result,
      'date': session.selectedDate != null
          ? '${session.selectedDate!.year}-'
              '${session.selectedDate!.month.toString().padLeft(2, '0')}-'
              '${session.selectedDate!.day.toString().padLeft(2, '0')}'
          : '',
      'startTime': session.selectedSlot?.startTime ?? '',
      'services': session.selectedServices
          .map((s) => {
                'name': s.name,
                'duration': '${s.durationMin} min',
                'price': s.price,
              })
          .toList(),
      'staffName': session.selectedStaff?.fullName ?? '',
      'customerName': '$firstName $lastName'.trim(),
      'isCheckIn': session.isCheckIn,
    };
  }
}
