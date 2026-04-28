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

    final apiIsOpen = data['isOpen'] as bool? ?? false;
    final openTime = data['openTime'] as String? ?? '';
    final closeTime = data['closeTime'] as String? ?? '';

    // Both must be true: API says open AND current time is within range
    final isOpen = apiIsOpen && _isWithinTimeRange(openTime, closeTime);

    return OutletStatus(
      isOpen: isOpen,
      openTime: openTime,
      closeTime: closeTime,
    );
  }

  /// Returns true only if current time is between [openTime] and [closeTime].
  /// Expects full datetime strings: "2026-04-28 07:00:00"
  static bool _isWithinTimeRange(String openTime, String closeTime) {
    try {
      if (openTime.isEmpty || closeTime.isEmpty) return false;

      final open = DateTime.parse(openTime.replaceFirst(' ', 'T'));
      final close = DateTime.parse(closeTime.replaceFirst(' ', 'T'));
      final now = DateTime.now();

      return now.isAfter(open) && now.isBefore(close);
    } catch (_) {
      return false;
    }
  }
}
