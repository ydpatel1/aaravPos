import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/booking_repository.dart';

part 'consent_event.dart';
part 'consent_state.dart';

class ConsentBloc extends Bloc<ConsentEvent, ConsentState> {
  ConsentBloc(this._repository) : super(const ConsentState()) {
    on<ConsentCheckRequested>(_onConsentCheckRequested);
  }

  final BookingRepository _repository;

  Future<void> _onConsentCheckRequested(
    ConsentCheckRequested event,
    Emitter<ConsentState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final isRequired = await _repository.checkConsent(event.customerName);
      emit(state.copyWith(isLoading: false, isConsentRequired: isRequired));
    } catch (_) {
      emit(
        state.copyWith(isLoading: false, errorMessage: 'Consent check failed'),
      );
    }
  }

  Future<void> checkConsent(String customerName) async =>
      add(ConsentCheckRequested(customerName));
}
