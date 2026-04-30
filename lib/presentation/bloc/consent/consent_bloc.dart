import 'package:aaravpos/core/storage/secure_storage.dart';
import 'package:aaravpos/domain/model/service_item.dart';
import 'package:aaravpos/domain/repo/booking_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'consent_event.dart';
part 'consent_state.dart';

class ConsentBloc extends Bloc<ConsentEvent, ConsentState> {
  ConsentBloc(this._repository, SecureStorage _) : super(const ConsentState()) {
    on<ConsentCheckRequested>(_onCheckRequested);
    on<ConsentSignRequested>(_onSignRequested);
    on<ConsentReset>(_onReset);
  }

  final BookingRepository _repository;

  Future<void> _onCheckRequested(
    ConsentCheckRequested event,
    Emitter<ConsentState> emit,
  ) async {
    emit(state.copyWith(status: ConsentStatus.checking, errorMessage: null));

    try {
      // Find services that require consent (consentFormId may be null — still check)
      final consentServices = event.services
          .where((s) => s.consentRequired)
          .toList();

      if (consentServices.isEmpty) {
        debugPrint('✅ ConsentBloc: No services require consent → skipping');
        emit(state.copyWith(status: ConsentStatus.skipped));
        return;
      }

      // Use first service that has a consentFormId, or fall back to first consent service
      final primary = consentServices.firstWhere(
        (s) => s.consentFormId != null && s.consentFormId!.isNotEmpty,
        orElse: () => consentServices.first,
      );

      if (primary.consentFormId == null || primary.consentFormId!.isEmpty) {
        // consentRequired=true but no consentFormId from service list API.
        // Try calling the check API with just the serviceId — the server resolves the form.
        debugPrint(
          '⚠️ ConsentBloc: consentRequired but no consentFormId — calling check API with serviceId only',
        );
        try {
          final result = await _repository.checkConsentStatus(
            customerId: event.customerId,
            consentFormId: primary.id, // use serviceId as fallback key
            serviceId: primary.id,
          );
          debugPrint(
            '📋 ConsentBloc (fallback): needsSignature=${result.needsSignature}, freq=${result.signingFrequency}',
          );
          if (!result.requiresDialog) {
            emit(state.copyWith(status: ConsentStatus.skipped));
            return;
          }
          emit(
            state.copyWith(
              status: ConsentStatus.needsSign,
              consentHeading: result.consentHeading,
              consentText: result.consentText.isNotEmpty
                  ? result.consentText
                  : 'Please confirm your consent to proceed with this service.',
              consentFormId: result.consentFormId.isNotEmpty
                  ? result.consentFormId
                  : primary.id,
              signatureType: result.signatureType,
              pendingServiceIds: consentServices.map((s) => s.id).toList(),
            ),
          );
        } catch (_) {
          // API failed — show generic checkbox consent as last resort
          debugPrint(
            '⚠️ ConsentBloc: check API failed, showing generic checkbox dialog',
          );
          emit(
            state.copyWith(
              status: ConsentStatus.needsSign,
              consentHeading: '',
              consentText:
                  'Please confirm your consent to proceed with this service.',
              consentFormId: '',
              signatureType: 'CHECKBOX_ONLY',
              pendingServiceIds: consentServices.map((s) => s.id).toList(),
            ),
          );
        }
        return;
      }

      debugPrint(
        '🔍 ConsentBloc: Checking consent for service ${primary.id}, form ${primary.consentFormId}',
      );
      final result = await _repository.checkConsentStatus(
        customerId: event.customerId,
        consentFormId: primary.consentFormId!,
        serviceId: primary.id,
      );

      debugPrint(
        '📋 ConsentBloc: needsSignature=${result.needsSignature}, signingFrequency=${result.signingFrequency}',
      );

      if (!result.requiresDialog) {
        // ONCE_PER_CUSTOMER and already signed → skip
        debugPrint(
          '✅ ConsentBloc: Already signed (ONCE_PER_CUSTOMER) → skipping',
        );
        emit(state.copyWith(status: ConsentStatus.skipped));
        return;
      }

      debugPrint('📝 ConsentBloc: Consent required → showing dialog');
      emit(
        state.copyWith(
          status: ConsentStatus.needsSign,
          consentHeading: result.consentHeading,
          consentText: result.consentText,
          consentFormId: result.consentFormId.isNotEmpty
              ? result.consentFormId
              : primary.consentFormId!,
          signatureType: result.signatureType,
          pendingServiceIds: consentServices.map((s) => s.id).toList(),
        ),
      );
    } catch (e) {
      debugPrint('❌ ConsentBloc: Error checking consent: $e');
      emit(
        state.copyWith(
          status: ConsentStatus.error,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onSignRequested(
    ConsentSignRequested event,
    Emitter<ConsentState> emit,
  ) async {
    // Store the signed data in state — actual POST consent/customer-sign
    // is called by BookingBloc AFTER the appointment is created (needs appointmentId).
    emit(
      state.copyWith(
        status: ConsentStatus.signed,
        signedImageUrl: event.imageUrl,
        signedTypedName: event.typedName,
        isChecked: event.isChecked,
      ),
    );
  }

  void _onReset(ConsentReset event, Emitter<ConsentState> emit) {
    emit(const ConsentState());
  }
}
