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
    this.consentHeading = '',
    this.consentText = '',
    this.consentFormId = '',
    this.signatureType = 'SIGNATURE_IMAGE',
    this.pendingServiceIds = const [],
    this.errorMessage,
    this.signedImageUrl,
    this.signedTypedName,
    this.isChecked = false,
  });

  final ConsentStatus status;
  final String consentHeading; // from service.consentTemplate.heading
  final String consentText;
  final String consentFormId;
  final String signatureType;
  final List<String> pendingServiceIds;
  final String? errorMessage;
  // Stored after user signs — passed to BookingBloc
  final String? signedImageUrl;
  final String? signedTypedName;
  final bool isChecked;

  ConsentState copyWith({
    ConsentStatus? status,
    String? consentHeading,
    String? consentText,
    String? consentFormId,
    String? signatureType,
    List<String>? pendingServiceIds,
    String? errorMessage,
    String? signedImageUrl,
    String? signedTypedName,
    bool? isChecked,
  }) {
    return ConsentState(
      status: status ?? this.status,
      consentHeading: consentHeading ?? this.consentHeading,
      consentText: consentText ?? this.consentText,
      consentFormId: consentFormId ?? this.consentFormId,
      signatureType: signatureType ?? this.signatureType,
      pendingServiceIds: pendingServiceIds ?? this.pendingServiceIds,
      errorMessage: errorMessage,
      signedImageUrl: signedImageUrl ?? this.signedImageUrl,
      signedTypedName: signedTypedName ?? this.signedTypedName,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  @override
  List<Object?> get props => [
    status,
    consentHeading,
    consentText,
    consentFormId,
    signatureType,
    pendingServiceIds,
    errorMessage,
    signedImageUrl,
    signedTypedName,
    isChecked,
  ];
}
