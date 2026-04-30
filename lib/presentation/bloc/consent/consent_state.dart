part of 'consent_bloc.dart';

enum ConsentStatus {
  initial,
  checking,   // calling GET concent/check
  skipped,    // no consent needed → go straight to booking
  needsSign,  // show consent dialog
  signed,     // user completed consent dialog → proceed to booking
  error,
}

class ConsentState extends Equatable {
  const ConsentState({
    this.status = ConsentStatus.initial,
    this.consentResults = const [],
    this.signedConsents = const [],
    this.errorMessage,
  });

  final ConsentStatus status;

  /// One entry per service that requires consent.
  /// Populated after consent check API calls (or local evaluation for new customers).
  final List<ConsentCheckResult> consentResults;

  /// Consents that the user has signed in this session.
  final List<SignedConsentData> signedConsents;

  final String? errorMessage;

  // ── Computed flags (spec §5.4) ──────────────────────────────────────────────

  /// Services that MUST be signed (needsSignature == false, not yet signed in session).
  List<ConsentCheckResult> get unsignedMandatory {
    final signedIds = signedConsents.map((s) => s.serviceId).toSet();
    return consentResults
        .where((r) => !r.needsSignature && !signedIds.contains(r.serviceId))
        .toList();
  }

  /// Services that are optional re-signs (needsSignature == true, not yet signed in session).
  List<ConsentCheckResult> get unsignedOptional {
    final signedIds = signedConsents.map((s) => s.serviceId).toSet();
    return consentResults
        .where((r) => r.needsSignature && !signedIds.contains(r.serviceId))
        .toList();
  }

  /// True when any mandatory consent is not yet signed.
  bool get hasUnsignedMandatory => unsignedMandatory.isNotEmpty;

  /// True when any optional consent is not yet signed.
  bool get hasOptionalConsent => unsignedOptional.isNotEmpty;

  /// Show "Sign Consent" button instead of "Continue".
  bool get showSignConsentButton =>
      hasUnsignedMandatory || hasOptionalConsent;

  /// Disables the Continue button — new customer with unsigned ONCE_PER_CUSTOMER consent.
  bool get hasPendingMandatoryConsent {
    final signedIds = signedConsents.map((s) => s.serviceId).toSet();
    return consentResults.any(
      (r) =>
          r.isNewCustomerEntry &&
          r.signingFrequency == 'ONCE_PER_CUSTOMER' &&
          !signedIds.contains(r.serviceId),
    );
  }

  /// Next service needing consent dialog — mandatory first, then optional.
  ConsentCheckResult? get nextConsentToSign {
    if (unsignedMandatory.isNotEmpty) return unsignedMandatory.first;
    if (unsignedOptional.isNotEmpty) return unsignedOptional.first;
    return null;
  }

  ConsentState copyWith({
    ConsentStatus? status,
    List<ConsentCheckResult>? consentResults,
    List<SignedConsentData>? signedConsents,
    String? errorMessage,
  }) {
    return ConsentState(
      status: status ?? this.status,
      consentResults: consentResults ?? this.consentResults,
      signedConsents: signedConsents ?? this.signedConsents,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    consentResults,
    signedConsents,
    errorMessage,
  ];
}
