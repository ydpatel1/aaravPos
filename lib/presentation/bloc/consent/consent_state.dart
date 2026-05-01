part of 'consent_bloc.dart';

enum ConsentStatus {
  initial,
  checking,  // running decision tree / calling GET concent/check
  needsSign, // at least one service needs the dialog shown
  skipped,   // no consent needed at all → go straight to booking
  signed,    // user completed the dialog → proceed to booking
  error,
}

/// Holds the resolved consent requirement for a single service.
class ServiceConsentInfo {
  const ServiceConsentInfo({
    required this.service,
    required this.isMandatory,
  });

  final ServiceItem service;

  /// true  → customer has NOT signed before (or EVERY_VISIT / new customer)
  ///          → "Sign Consent" blocks Continue until signed
  /// false → customer already signed (ONCE_PER_CUSTOMER, needsSignature=true from API)
  ///          → "Sign Consent" shown as optional, Continue NOT blocked
  final bool isMandatory;
}

class ConsentState extends Equatable {
  const ConsentState({
    this.status = ConsentStatus.initial,
    this.serviceConsents = const [],
    this.signedConsents = const {},
    this.errorMessage,
    this.signedImageUrl,
    this.signedTypedName,
    this.isChecked = false,
  });

  final ConsentStatus status;

  /// One entry per service that requires consent, populated after check.
  final List<ServiceConsentInfo> serviceConsents;

  /// Per-service signed data map — key = serviceId.
  /// Populated as user signs each dialog. Passed to BookingBloc after booking.
  final Map<String, SignedConsentData> signedConsents;

  final String? errorMessage;

  // ── Last signed data (used by ConsentDialog to read current values) ───────
  final String? signedImageUrl;
  final String? signedTypedName;
  final bool isChecked;

  // ── Convenience getters ───────────────────────────────────────────────────

  /// The first service that still needs the dialog shown.
  /// Mandatory ones first, then optional.
  ServiceConsentInfo? get nextToSign {
    final mandatory = serviceConsents.where((s) => s.isMandatory).toList();
    if (mandatory.isNotEmpty) return mandatory.first;
    final optional = serviceConsents.where((s) => !s.isMandatory).toList();
    if (optional.isNotEmpty) return optional.first;
    return null;
  }

  /// True when any mandatory consent is still unsigned → blocks Continue.
  bool get hasMandatoryUnsigned =>
      serviceConsents.any((s) => s.isMandatory);

  /// True when the "Sign Consent" button should be shown instead of "Continue".
  bool get showSignConsentButton => serviceConsents.isNotEmpty;

  // ── Convenience accessors for the dialog (reads from nextToSign) ──────────

  String get consentHeading =>
      nextToSign?.service.consentDialogTitle ?? 'Consent Form Title';

  String get consentText =>
      nextToSign?.service.consentDialogBody ?? '';

  String get signatureType =>
      nextToSign?.service.kioskSigningMethod ?? 'CHECKBOX_ONLY';

  String get consentFormId =>
      nextToSign?.service.consentFormId ?? '';

  ConsentState copyWith({
    ConsentStatus? status,
    List<ServiceConsentInfo>? serviceConsents,
    Map<String, SignedConsentData>? signedConsents,
    String? errorMessage,
    String? signedImageUrl,
    String? signedTypedName,
    bool? isChecked,
  }) {
    return ConsentState(
      status: status ?? this.status,
      serviceConsents: serviceConsents ?? this.serviceConsents,
      signedConsents: signedConsents ?? this.signedConsents,
      errorMessage: errorMessage,
      signedImageUrl: signedImageUrl ?? this.signedImageUrl,
      signedTypedName: signedTypedName ?? this.signedTypedName,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  @override
  List<Object?> get props => [
    status,
    serviceConsents,
    signedConsents,
    errorMessage,
    signedImageUrl,
    signedTypedName,
    isChecked,
  ];
}
