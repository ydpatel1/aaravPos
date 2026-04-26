class OutletStatus {
  const OutletStatus({required this.tenantId, required this.outletId});

  final String tenantId;
  final String outletId;

  factory OutletStatus.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final tenantId =
        data['tenantId'] as String? ?? data['tenant_id'] as String?;
    final outletId =
        data['outletId'] as String? ?? data['outlet_id'] as String?;

    if (tenantId == null || outletId == null) {
      throw Exception('Invalid outlet status response.');
    }

    return OutletStatus(tenantId: tenantId, outletId: outletId);
  }
}
