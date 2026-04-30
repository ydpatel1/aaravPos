/// Result from GET concent/check/{customerId}/{consentFormId}?serviceId={serviceId}
///
/// Per spec §5.3:
///   needsSignature: false → customer has NOT signed before → MUST sign (mandatory)
///   needsSignature: true  → customer already signed → optional re-sign
class ConsentCheckResult {
  const ConsentCheckResult({
    required this.serviceId,
    required this.needsSignature,
    required this.signingFrequency,
    required this.consentFormId,
    required this.consentHeading,
    required this.consentText,
    required this.signatureType,
    this.hasPreviousSignature = false,
    this.signatureExists = false,
    this.consentInstanceExists = false,
    this.isNewCustomerEntry = false,
  });

  final String serviceId;

  /// false = has NOT signed before → must sign (mandatory)
  /// true  = already signed → optional re-sign
  final bool needsSignature;

  final String signingFrequency; // "ONCE_PER_CUSTOMER" | "EVERY_VISIT"
  final String consentFormId;
  final String consentHeading; // from consentTemplate.heading
  final String consentText;
  final String signatureType; // "SIGNATURE_IMAGE" | "CHECKBOX_ONLY" | "TYPED_NAME"
  final bool hasPreviousSignature;
  final bool signatureExists;
  final bool consentInstanceExists;

  /// Synthetic flag — true when this entry was created locally for a new/unregistered customer.
  final bool isNewCustomerEntry;

  /// True means we must show the consent dialog.
  ///
  /// ONCE_PER_CUSTOMER: show dialog only if NOT yet signed (needsSignature == false).
  ///   needsSignature=false → hasn't signed → show dialog (mandatory)
  ///   needsSignature=true  → already signed → skip (optional, don't force)
  ///
  /// EVERY_VISIT: always show dialog regardless of needsSignature.
  bool get requiresDialog {
    if (signingFrequency == 'ONCE_PER_CUSTOMER') {
      // needsSignature=true means already signed → skip
      return !needsSignature;
    }
    // EVERY_VISIT → always show
    return true;
  }

  /// True when this is a mandatory unsigned consent (blocks Continue button).
  bool get isMandatoryUnsigned =>
      isNewCustomerEntry && signingFrequency == 'ONCE_PER_CUSTOMER';

  factory ConsentCheckResult.fromJson(
    Map<String, dynamic> json, {
    String serviceId = '',
  }) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return ConsentCheckResult(
      serviceId: serviceId,
      needsSignature: data['needsSignature'] as bool? ?? false,
      signingFrequency: data['signingFrequency'] as String? ?? 'EVERY_VISIT',
      consentFormId: data['consentFormId'] as String? ?? '',
      consentHeading: data['consentHeading'] as String? ?? '',
      consentText: data['consentText'] as String? ?? '',
      signatureType: data['signatureType'] as String? ?? 'SIGNATURE_IMAGE',
      hasPreviousSignature: data['hasPreviousSignature'] as bool? ?? false,
      signatureExists: data['signatureExists'] as bool? ?? false,
      consentInstanceExists: data['consentInstanceExists'] as bool? ?? false,
    );
  }

  /// Creates a synthetic entry for a new/unregistered customer.
  factory ConsentCheckResult.forNewCustomer({
    required String serviceId,
    required String consentFormId,
    required String signingFrequency,
    required String signatureType,
    String consentHeading = '',
    String consentText = '',
  }) {
    return ConsentCheckResult(
      serviceId: serviceId,
      // New customer hasn't signed → needsSignature = false (must sign)
      needsSignature: false,
      signingFrequency: signingFrequency,
      consentFormId: consentFormId,
      consentHeading: consentHeading,
      signatureType: signatureType,
      consentText: consentText,
      isNewCustomerEntry: true,
    );
  }
}
