import 'package:aaravpos/domain/model/consent_check_result.dart';
import 'package:aaravpos/domain/model/service_item.dart';
import 'package:aaravpos/domain/model/signed_consent_data.dart';
import 'package:aaravpos/domain/repo/booking_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'consent_event.dart';
part 'consent_state.dart';

class ConsentBloc extends Bloc<ConsentEvent, ConsentState> {
  ConsentBloc(this._repository) : super(const ConsentState()) {
    on<ConsentCheckRequested>(_onCheckRequested);
    on<ConsentSigned>(_onConsentSigned);
    on<ConsentReset>(_onReset);
  }

  final BookingRepository _repository;

  Future<void> _onCheckRequested(
    ConsentCheckRequested event,
    Emitter<ConsentState> emit,
  ) async {
    emit(state.copyWith(status: ConsentStatus.checking, errorMessage: null));

    // Filter services that qualify for consent per spec §5.1:
    // requiresConsent == true AND consentFormId != null AND consentRule != null
    final consentServices = event.services
        .where((s) => s.needsConsentDialog)
        .toList();

    if (consentServices.isEmpty) {
      debugPrint('✅ ConsentBloc: No services require consent → skipping');
      emit(state.copyWith(status: ConsentStatus.skipped));
      return;
    }

    if (event.isNewCustomer) {
      // New / unregistered customer — evaluate locally (spec §5.2.C)
      _evaluateConsentForNewCustomer(consentServices, emit);
      return;
    }

    // Existing customer — process each service
    final results = <ConsentCheckResult>[];

    for (final service in consentServices) {
      final rule = service.consentRule!;
      final freq = rule.signingFrequency;

      if (freq == 'EVERY_VISIT') {
        // Spec §5.2.A: EVERY_VISIT + MULTIPLE + KIOSK → no API call, always sign
        debugPrint(
          '📋 ConsentBloc: EVERY_VISIT service ${service.id} → needsSignature=true (no API)',
        );
        results.add(
          ConsentCheckResult(
            serviceId: service.id,
            needsSignature: true, // already signed (optional re-sign per spec)
            signingFrequency: freq,
            consentFormId: service.consentFormId!,
            consentHeading: '',
            consentText: '',
            signatureType: rule.kioskMethod ?? 'CHECKBOX_ONLY',
          ),
        );
      } else {
        // ONCE_PER_CUSTOMER → call API (spec §5.2.B)
        try {
          debugPrint(
            '🔍 ConsentBloc: Checking ONCE_PER_CUSTOMER consent for service ${service.id}',
          );
          final result = await _repository.checkConsentStatus(
            customerId: event.customerId,
            consentFormId: service.consentFormId!,
            serviceId: service.id,
          );
          // Attach serviceId since the API response doesn't include it
          results.add(
            ConsentCheckResult(
              serviceId: service.id,
              needsSignature: result.needsSignature,
              signingFrequency: result.signingFrequency.isNotEmpty
                  ? result.signingFrequency
                  : freq,
              consentFormId: result.consentFormId.isNotEmpty
                  ? result.consentFormId
                  : service.consentFormId!,
              consentHeading: result.consentHeading,
              consentText: result.consentText,
              signatureType: result.signatureType.isNotEmpty
                  ? result.signatureType
                  : (rule.kioskMethod ?? 'CHECKBOX_ONLY'),
              hasPreviousSignature: result.hasPreviousSignature,
              signatureExists: result.signatureExists,
              consentInstanceExists: result.consentInstanceExists,
            ),
          );
          debugPrint(
            '📋 ConsentBloc: service ${service.id} needsSignature=${result.needsSignature}',
          );
        } catch (e) {
          // API error → safe fallback: treat as must-sign (needsSignature=false)
          debugPrint(
            '⚠️ ConsentBloc: consent check failed for ${service.id}, defaulting to must-sign: $e',
          );
          results.add(
            ConsentCheckResult(
              serviceId: service.id,
              needsSignature: false, // safe fallback → must sign
              signingFrequency: freq,
              consentFormId: service.consentFormId!,
              consentHeading: '',
              consentText: '',
              signatureType: rule.kioskMethod ?? 'CHECKBOX_ONLY',
            ),
          );
        }
      }
    }

    final newState = state.copyWith(
      status: ConsentStatus.needsSign,
      consentResults: results,
      signedConsents: const [],
    );

    if (!newState.showSignConsentButton) {
      // All consents are already signed (ONCE_PER_CUSTOMER, needsSignature=true)
      debugPrint('✅ ConsentBloc: All consents already signed → skipping');
      emit(state.copyWith(status: ConsentStatus.skipped, consentResults: results));
    } else {
      emit(newState);
    }
  }

  /// Spec §5.2.C — new/unregistered customer, no API call possible.
  void _evaluateConsentForNewCustomer(
    List<ServiceItem> consentServices,
    Emitter<ConsentState> emit,
  ) {
    final results = <ConsentCheckResult>[];

    for (final service in consentServices) {
      final rule = service.consentRule!;
      final freq = rule.signingFrequency;
      final method = rule.kioskMethod ?? 'CHECKBOX_ONLY';

      // Both EVERY_VISIT and ONCE_PER_CUSTOMER → needsSignature = true, isNewCustomerEntry = true
      debugPrint(
        '📋 ConsentBloc: New customer, service ${service.id}, freq=$freq → needsSignature=true',
      );
      results.add(
        ConsentCheckResult.forNewCustomer(
          serviceId: service.id,
          consentFormId: service.consentFormId!,
          signingFrequency: freq,
          signatureType: method,
        ),
      );
    }

    emit(state.copyWith(
      status: ConsentStatus.needsSign,
      consentResults: results,
      signedConsents: const [],
    ));
  }

  void _onConsentSigned(
    ConsentSigned event,
    Emitter<ConsentState> emit,
  ) {
    final updated = List<SignedConsentData>.from(state.signedConsents)
      ..removeWhere((s) => s.serviceId == event.data.serviceId)
      ..add(event.data);

    final newState = state.copyWith(
      signedConsents: updated,
    );

    // If no more consents to sign → transition to signed
    if (!newState.showSignConsentButton) {
      emit(newState.copyWith(status: ConsentStatus.signed));
    } else {
      emit(newState);
    }
  }

  void _onReset(ConsentReset event, Emitter<ConsentState> emit) {
    emit(const ConsentState());
  }
}
