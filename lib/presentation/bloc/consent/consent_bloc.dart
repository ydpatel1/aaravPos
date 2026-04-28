import 'package:aaravpos/core/storage/secure_storage.dart';
import 'package:aaravpos/domain/model/service_item.dart';
import 'package:aaravpos/domain/repo/booking_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'consent_event.dart';
part 'consent_state.dart';

class ConsentBloc extends Bloc<ConsentEvent, ConsentState> {
  ConsentBloc(this._repository, this._secureStorage)
    : super(const ConsentState()) {
    on<ConsentCheckRequested>(_onCheckRequested);
    on<ConsentSignRequested>(_onSignRequested);
    on<ConsentReset>(_onReset);
  }

  final BookingRepository _repository;
  final SecureStorage _secureStorage;

  // Stored during check so sign can reuse them
  String _customerId = '';
  String _staffId = '';
  String _outletId = '';
  String _tenantId = '';

  Future<void> _onCheckRequested(
    ConsentCheckRequested event,
    Emitter<ConsentState> emit,
  ) async {
    emit(state.copyWith(status: ConsentStatus.checking, errorMessage: null));

    try {
      _customerId = event.customerId;
      _staffId = await _secureStorage.getUserId() ?? '';
      _outletId = await _secureStorage.getOutletId() ?? '';
      _tenantId = await _secureStorage.getTenantId() ?? '';

      // Find first service that requires consent
      final consentServices = event.services
          .where((s) => s.consentRequired && s.consentFormId != null)
          .toList();

      if (consentServices.isEmpty) {
        // No consent needed at all → skip
        emit(state.copyWith(status: ConsentStatus.skipped));
        return;
      }

      final primary = consentServices.first;
      final result = await _repository.checkConsentStatus(
        customerId: event.customerId,
        consentFormId: primary.consentFormId!,
        serviceId: primary.id,
      );

      if (!result.requiresDialog) {
        // ONCE_PER_CUSTOMER and already signed → skip
        emit(state.copyWith(status: ConsentStatus.skipped));
        return;
      }

      emit(
        state.copyWith(
          status: ConsentStatus.needsSign,
          consentText: result.consentText,
          consentFormId: result.consentFormId.isNotEmpty
              ? result.consentFormId
              : primary.consentFormId!,
          signatureType: result.signatureType,
          pendingServiceIds: consentServices.map((s) => s.id).toList(),
        ),
      );
    } catch (e) {
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
    emit(state.copyWith(status: ConsentStatus.signing, errorMessage: null));
    try {
      await _repository.signConsent(
        customerId: _customerId,
        consentFormId: state.consentFormId,
        serviceIds: state.pendingServiceIds,
        staffId: _staffId,
        outletId: _outletId,
        tenantId: _tenantId,
        signatureType: event.signatureType,
        imageUrl: event.imageUrl,
        typedName: event.typedName,
      );
      emit(state.copyWith(status: ConsentStatus.signed));
    } catch (e) {
      emit(
        state.copyWith(
          status: ConsentStatus.needsSign, // keep dialog open
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  void _onReset(ConsentReset event, Emitter<ConsentState> emit) {
    emit(const ConsentState());
  }
}
