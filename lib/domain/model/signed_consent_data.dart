/// Data collected from the consent dialog for one service.
/// Stored in ConsentBloc.state.signedConsents until the appointment is created,
/// then each entry is POSTed to POST concent/customer-sign.
class SignedConsentData {
  const SignedConsentData({
    required this.serviceId,
    required this.consentFormId,
    required this.signatureType,
    this.imageUrl,
    this.typedName,
    this.isChecked = false,
    required this.signedAt,
  });

  final String serviceId;
  final String consentFormId;

  /// 'SIGNATURE_IMAGE' | 'TYPED_NAME' | 'CHECKBOX_ONLY'
  final String signatureType;

  /// Base64 PNG data URI — only for SIGNATURE_IMAGE
  final String? imageUrl;

  /// Typed name text — only for TYPED_NAME
  final String? typedName;

  /// Checkbox state — only for CHECKBOX_ONLY
  final bool isChecked;

  final DateTime signedAt;
}
