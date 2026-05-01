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
    on<ConsentSignRequested>(_onSignRequested);
    on<ConsentReset>(_onReset);
  }

  final BookingRepository _repository;

  // ── Decision tree (spec §5) ───────────────────────────────────────────────

  Future<void> _onCheckRequested(
    ConsentCheckRequested event,
    Emitter<ConsentState> emit,
  ) async {
    emit(state.copyWith(status: ConsentStatus.checking, errorMessage: null));

    // Only services that fully qualify for consent (spec §5.1):
    // requiresConsent == true AND consentFormId != null AND consentRule != null
    final consentServices = event.services
        .where((s) => s.needsConsentDialog)
        .toList();

    if (consentServices.isEmpty) {
      debugPrint('✅ ConsentBloc: No services require consent → skipping');
      emit(state.copyWith(status: ConsentStatus.skipped));
      return;
    }

    final results = <ServiceConsentInfo>[];

    for (final service in consentServices) {
      final freq = service.signingFrequency;

      if (freq == 'EVERY_VISIT') {
        // ── Branch A: EVERY_VISIT ─────────────────────────────────────────
        // No API call. Always mandatory — must sign on every visit.
        debugPrint(
          '📋 ConsentBloc: EVERY_VISIT → mandatory (no API call) [${service.id}]',
        );
        results.add(ServiceConsentInfo(service: service, isMandatory: true));
      } else {
        // ── Branch B/C: ONCE_PER_CUSTOMER ─────────────────────────────────
        if (event.isNewCustomer || event.customerId.isEmpty) {
          // Branch C: new / unregistered customer — no customerId to check.
          // Always mandatory (first time signing).
          debugPrint(
            '📋 ConsentBloc: ONCE_PER_CUSTOMER + new customer → mandatory [${service.id}]',
          );
          results.add(ServiceConsentInfo(service: service, isMandatory: true));
        } else {
          // Branch B: existing customer — call GET concent/check to find out
          // if they have already signed before.
          try {
            debugPrint(
              '🔍 ConsentBloc: ONCE_PER_CUSTOMER → calling concent/check [${service.id}]',
            );
            final result = await _repository.checkConsentStatus(
              customerId: event.customerId,
              consentFormId: service.consentFormId!,
              serviceId: service.id,
            );

            // needsSignature: false → has NOT signed before → mandatory
            // needsSignature: true  → already signed → optional re-sign
            final isMandatory = !result.needsSignature;
            debugPrint(
              '📋 ConsentBloc: needsSignature=${result.needsSignature} → '
              '${isMandatory ? "mandatory" : "optional"} [${service.id}]',
            );
            results.add(
              ServiceConsentInfo(service: service, isMandatory: isMandatory),
            );
          } catch (e) {
            // API error → safe fallback: treat as mandatory (must sign)
            debugPrint(
              '⚠️ ConsentBloc: concent/check failed → defaulting to mandatory [${service.id}]: $e',
            );
            results.add(
              ServiceConsentInfo(service: service, isMandatory: true),
            );
          }
        }
      }
    }

    debugPrint(
      '📝 ConsentBloc: ${results.length} service(s) need consent '
      '(${results.where((r) => r.isMandatory).length} mandatory)',
    );

    emit(state.copyWith(
      status: ConsentStatus.needsSign,
      serviceConsents: results,
      signedConsents: const {},
    ));
  }

  // ── User confirmed the dialog ─────────────────────────────────────────────

  Future<void> _onSignRequested(
    ConsentSignRequested event,
    Emitter<ConsentState> emit,
  ) async {
    final next = state.nextToSign;
    if (next == null) return;

    // Build per-service signed data entry
    final data = SignedConsentData(
      serviceId: next.service.id,
      consentFormId: next.service.consentFormId ?? '',
      signatureType: event.signatureType,
      imageUrl: event.imageUrl,
      typedName: event.typedName,
      isChecked: event.isChecked,
      signedAt: DateTime.now(),
    );

    // Add to the map
    final updatedMap = Map<String, SignedConsentData>.from(state.signedConsents)
      ..[data.serviceId] = data;

    // Remove this service from the pending list
    final remaining = state.serviceConsents
        .where((s) => s.service.id != next.service.id)
        .toList();

    final allSigned = remaining.isEmpty;

    debugPrint(
      '✅ ConsentBloc: Signed ${data.serviceId} — '
      '${updatedMap.length}/${state.serviceConsents.length} done'
      '${allSigned ? " → all signed" : ""}',
    );

    emit(state.copyWith(
      status: allSigned ? ConsentStatus.signed : ConsentStatus.needsSign,
      serviceConsents: remaining,
      signedConsents: updatedMap,
      signedImageUrl: event.imageUrl,
      signedTypedName: event.typedName,
      isChecked: event.isChecked,
    ));
  }

  void _onReset(ConsentReset event, Emitter<ConsentState> emit) {
    emit(const ConsentState());
  }
}
