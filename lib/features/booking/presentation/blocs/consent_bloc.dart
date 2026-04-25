import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/booking_repository.dart';

class ConsentState extends Equatable {
  const ConsentState({
    this.isLoading = false,
    this.isConsentRequired = true,
    this.errorMessage,
  });

  final bool isLoading;
  final bool isConsentRequired;
  final String? errorMessage;

  ConsentState copyWith({
    bool? isLoading,
    bool? isConsentRequired,
    String? errorMessage,
  }) {
    return ConsentState(
      isLoading: isLoading ?? this.isLoading,
      isConsentRequired: isConsentRequired ?? this.isConsentRequired,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, isConsentRequired, errorMessage];
}

class ConsentBloc extends Cubit<ConsentState> {
  ConsentBloc(this._repository) : super(const ConsentState());

  final BookingRepository _repository;

  Future<void> checkConsent(String customerName) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final isRequired = await _repository.checkConsent(customerName);
      emit(state.copyWith(isLoading: false, isConsentRequired: isRequired));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: 'Consent check failed'));
    }
  }
}
