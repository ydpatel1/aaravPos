part of 'consent_bloc.dart';

enum ConsentStatus {
  initial,
  checking, // calling GET consent/check
  skipped, // no consent needed → go straight to booking
  needsSign, // show dialog
  signing, // calling POST consent/customer-sign
  signed, // success → proceed to booking
  error,
}

class ConsentState extends Equatable {
  const ConsentState({
    this.status = ConsentStatus.initial,
    this.consentText = '',
    this.consentFormId = '',
    this.signatureType = 'SIGNATURE_IMAGE',
    this.pendingServiceIds = const [],
    this.errorMessage,
  });

  final ConsentStatus status;
  final String consentText;
  final String consentFormId;
  final String
  signatureType; // "SIGNATURE_IMAGE" | "CHECKBOX_ONLY" | "TYPED_NAME"
  final List<String> pendingServiceIds;
  final String? errorMessage;

  ConsentState copyWith({
    ConsentStatus? status,
    String? consentText,
    String? consentFormId,
    String? signatureType,
    List<String>? pendingServiceIds,
    String? errorMessage,
  }) {
    return ConsentState(
      status: status ?? this.status,
      consentText: consentText ?? this.consentText,
      consentFormId: consentFormId ?? this.consentFormId,
      signatureType: signatureType ?? this.signatureType,
      pendingServiceIds: pendingServiceIds ?? this.pendingServiceIds,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    consentText,
    consentFormId,
    signatureType,
    pendingServiceIds,
    errorMessage,
  ];
}
