/// Holds the data collected from the consent dialog for a single service.
class SignedConsentData {
  const SignedConsentData({
    required this.serviceId,
    required this.consentFormId,
    required this.method,
    required this.payload,
    required this.signedAt,
  });

  final String serviceId;
  final String consentFormId;

  /// 'TYPED_NAME' | 'CHECKBOX_ONLY' | 'DRAW_SIGNATURE'
  final String method;

  /// Typed name text / "true" for checkbox / base64 PNG data URI for draw
  final String payload;

  final DateTime signedAt;
}
