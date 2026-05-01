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

  /// Per API docs:
  /// needsSignature: false = customer has NOT signed before → MUST sign (mandatory)
  /// needsSignature: true  = customer already signed → optional re-sign
  ///
  /// requiresDialog = true means we must show the consent dialog.
  /// Skip only if ONCE_PER_CUSTOMER AND needsSignature == true (already signed).
  bool get requiresDialog {
    if (signingFrequency == 'ONCE_PER_CUSTOMER' && needsSignature == true) {
      return false; // Already signed — skip dialog
    }
    return true; // Must sign
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
