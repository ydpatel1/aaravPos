class ConsentCheckResult {
  const ConsentCheckResult({
    required this.needsSignature,
    required this.signingFrequency,
    required this.consentFormId,
    required this.consentHeading,
    required this.consentText,
    required this.signatureType,
  });

  final bool needsSignature;
  final String signingFrequency; // "ONCE_PER_CUSTOMER" | "EVERY_TIME"
  final String consentFormId;
  final String consentHeading; // from consentTemplate.heading
  final String consentText;
  final String
  signatureType; // "SIGNATURE_IMAGE" | "CHECKBOX_ONLY" | "TYPED_NAME"

  /// True means we must show the consent dialog.
  /// Only skip if ONCE_PER_CUSTOMER AND customer has already signed (needsSignature == false).
  /// For EVERY_TIME, always show the dialog regardless of needsSignature.
  bool get requiresDialog {
    if (signingFrequency == 'ONCE_PER_CUSTOMER' && !needsSignature) {
      return false; // Already signed once — skip
    }
    return true; // EVERY_TIME always shows, or ONCE_PER_CUSTOMER not yet signed
  }

  factory ConsentCheckResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return ConsentCheckResult(
      needsSignature: data['needsSignature'] as bool? ?? true,
      signingFrequency: data['signingFrequency'] as String? ?? 'EVERY_TIME',
      consentFormId: data['consentFormId'] as String? ?? '',
      consentHeading: data['consentHeading'] as String? ?? '',
      consentText: data['consentText'] as String? ?? '',
      signatureType: data['signatureType'] as String? ?? 'SIGNATURE_IMAGE',
    );
  }
}
