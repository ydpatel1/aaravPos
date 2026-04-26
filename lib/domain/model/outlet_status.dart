class OutletStatus {
  const OutletStatus({
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
  });

  final bool isOpen;
  final String openTime;
  final String closeTime;

  factory OutletStatus.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final isOpen = data['isOpen'] as bool? ?? false;
    final openTime = data['openTime'] as String? ?? '';
    final closeTime = data['closeTime'] as String? ?? '';

    return OutletStatus(
      isOpen: isOpen,
      openTime: openTime,
      closeTime: closeTime,
    );
  }
}
