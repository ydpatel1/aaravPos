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

    final openTime = data['openTime'] as String? ?? '';
    final closeTime = data['closeTime'] as String? ?? '';

    // Open purely based on whether current time-of-day falls within the window.
    // The API's isOpen flag and date portion of the timestamps are ignored.
    final isOpen = _isWithinTimeRange(openTime, closeTime);

    return OutletStatus(
      isOpen: isOpen,
      openTime: openTime,
      closeTime: closeTime,
    );
  }

  /// Returns true only if the current time-of-day is between [openTime] and [closeTime].
  /// Ignores the date portion — only HH:mm:ss is compared.
  /// Supports overnight ranges (e.g. 22:00 → 02:00).
  /// Expects strings like "2026-04-28 07:00:00" or "07:00:00" or "07:00".
  static bool _isWithinTimeRange(String openTime, String closeTime) {
    try {
      if (openTime.isEmpty || closeTime.isEmpty) return false;

      // Extract time portion only — take the last segment after a space or use as-is
      final openPart = openTime.contains(' ')
          ? openTime.split(' ').last
          : openTime;
      final closePart = closeTime.contains(' ')
          ? closeTime.split(' ').last
          : closeTime;

      // Parse HH:mm or HH:mm:ss into minutes-since-midnight
      int toMinutes(String t) {
        final parts = t.split(':');
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        return h * 60 + m;
      }

      final openMin = toMinutes(openPart);
      final closeMin = toMinutes(closePart);
      final now = DateTime.now();
      final nowMin = now.hour * 60 + now.minute;

      if (openMin <= closeMin) {
        // Normal range: e.g. 08:00 → 20:00
        return nowMin >= openMin && nowMin < closeMin;
      } else {
        // Overnight range: e.g. 22:00 → 02:00
        return nowMin >= openMin || nowMin < closeMin;
      }
    } catch (_) {
      return false;
    }
  }

  /// Formats a raw API time string (e.g. "2026-04-28 07:00:00" or "07:00:00")
  /// into a display string like "07:00". Returns empty string on failure.
  static String formatDisplayTime(String rawTime) {
    try {
      if (rawTime.isEmpty) return '';
      final timePart = rawTime.contains(' ')
          ? rawTime.split(' ').last
          : rawTime;
      final parts = timePart.split(':');
      final h = int.parse(parts[0]).toString().padLeft(2, '0');
      final m = int.parse(parts[1]).toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }
}
