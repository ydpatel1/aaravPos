part of 'consent_bloc.dart';

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
