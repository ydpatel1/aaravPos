import 'dart:async';

import 'package:aaravpos/core/utils/extensions/space_extension.dart';
import 'package:aaravpos/presentation/bloc/booking/booking_bloc.dart';
import 'package:aaravpos/presentation/bloc/consent/consent_bloc.dart';
import 'package:aaravpos/presentation/bloc/session/session_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/extensions/context_extension.dart';
import '../../../../shared/widgets/kiosk_bottom_bar.dart';
import '../../../../shared/widgets/platform_glass_card.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-navigate to home after 5 seconds
    Timer(const Duration(seconds: 5), () {
      if (mounted) _goHome();
    });
  }

  void _goHome() {
    context.read<SessionBloc>().reset();
    context.read<ConsentBloc>().add(const ConsentReset());
    context.go(AppRoutes.home);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _formatTime(String? isoOrHHmm) {
    if (isoOrHHmm == null || isoOrHHmm.isEmpty) return '-';
    try {
      // Try ISO8601 first
      if (isoOrHHmm.contains('T')) {
        final dt = DateTime.parse(isoOrHHmm);
        return DateFormat('hh:mm a').format(dt);
      }
      // HH:mm format
      final parts = isoOrHHmm.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final dt = DateTime(2000, 1, 1, h, m);
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return isoOrHHmm;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionBloc>().state;
    final bookingState = context.watch<BookingBloc>().state;
    final isMobile = context.isMobile;
    final isCheckIn = session.isCheckIn;

    final title = isCheckIn ? 'Check-In Confirmed' : 'Appointment Confirmed';
    final staffLabel = isCheckIn ? 'Your Check-In with' : 'Your Appointment with';

    final startFmt = _formatTime(session.selectedStartTime ?? session.selectedSlot?.startTime);
    final endFmt = _formatTime(session.selectedEndTime);
    final timeRange = (endFmt == '-') ? startFmt : '$startFmt - $endFmt';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF1A1A1A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: _goHome,
        ),
      ),
      backgroundColor: const Color(0xFFF7F7F8),
      bottomNavigationBar: KioskBottomBar(
        total: 'Total: ${session.formattedTotal}',
        subtitle: '${session.selectedServices.length} Service Selected',
        primaryLabel: 'Done',
        primaryEnabled: true,
        onPrimary: _goHome,
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: PlatformGlassCard(
              radius: 20,
              border: Border.all(color: Colors.red, width: 2),
              padding: const EdgeInsets.all(20),
              child: ListView(
                shrinkWrap: true,
                children: [
                  // ── Date & Time ─────────────────────────────────────────
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    text: _formatDate(session.selectedDate),
                  ),
                  8.vs,
                  _InfoRow(
                    icon: Icons.access_time_outlined,
                    text: timeRange,
                  ),

                  const Divider(height: 28),

                  // ── Staff & Customer ────────────────────────────────────
                  Text(
                    staffLabel,
                    style: const TextStyle(
                      color: Color(0xFF737373),
                      fontSize: 13,
                    ),
                  ),
                  4.vs,
                  Text(
                    session.selectedStaff?.fullName ?? '-',
                    style: const TextStyle(
                      color: Color(0xFFE12242),
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                  8.vs,
                  Text(
                    'Customer: ${session.selectedCustomer ?? '-'}',
                    style: const TextStyle(
                      color: Color(0xFF737373),
                      fontSize: 14,
                    ),
                  ),

                  const Divider(height: 28),

                  // ── Services ────────────────────────────────────────────
                  const Text(
                    'Service Selected',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  12.vs,

                  ...session.selectedServices.map(
                    (service) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          4.vs,
                          Row(
                            children: [
                              Text(
                                '${service.durationMin} min',
                                style: const TextStyle(
                                  color: Color(0xFF737373),
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '\$${service.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 20),

                  // ── Subtotal ────────────────────────────────────────────
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Subtotal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        session.formattedTotal,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFE12242),
                        ),
                      ),
                    ],
                  ),

                  // Booking ID (small, grey, at bottom)
                  if (bookingState.bookingId != null) ...[
                    12.vs,
                    Text(
                      'Booking ID: ${bookingState.bookingId}',
                      style: const TextStyle(
                        color: Color(0xFFB0B0B0),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Small helper widget ───────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF737373)),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
        ),
      ],
    );
  }
}
