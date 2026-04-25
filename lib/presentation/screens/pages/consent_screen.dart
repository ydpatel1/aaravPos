import 'package:aaravpos/presentation/bloc/booking/booking_bloc.dart';
import 'package:aaravpos/presentation/bloc/consent/consent_bloc.dart';
import 'package:aaravpos/presentation/bloc/session/session_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:signature/signature.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/extensions/context_extension.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/kiosk_bottom_bar.dart';
import '../../../../shared/widgets/platform_glass_card.dart';
import '../widgets/signature_pad.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  final SignatureController _controller = SignatureController();
  bool _emailMe = false;

  @override
  void initState() {
    super.initState();
    final customerName =
        context.read<SessionBloc>().state.selectedCustomer ?? '';
    context.read<ConsentBloc>().checkConsent(customerName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openConsentModal() async {
    final isMobile = context.isMobile;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        final dialogBody = PlatformGlassCard(
          radius: 24,
          padding: EdgeInsets.all(isMobile ? 14 : 22),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Barbershop Services Consent & Acknowledgment Agreement',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  height: isMobile ? 180 : 220,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: const SingleChildScrollView(
                    child: Text(
                      'By receiving services at this barbershop, I voluntarily choose barbering and grooming services.\n\nI understand that services may involve clippers, razors, scissors, and heated tools.\n\nI confirm that I have disclosed relevant skin or medical conditions that may affect service.',
                      style: TextStyle(fontSize: 16, height: 1.4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sign Here',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SignaturePad(controller: _controller),
                const SizedBox(height: 10),
                CheckboxListTile(
                  value: _emailMe,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Email me'),
                  onChanged: (value) {
                    setState(() {
                      _emailMe = value ?? false;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _controller.isEmpty
                          ? null
                          : () {
                              context.pop();
                              context.read<BookingBloc>().submitBooking();
                            },
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(isMobile ? 12 : 40),
          child: SizedBox(
            width: isMobile ? context.width : 960,
            child: dialogBody,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'Review & Confirm'),
      bottomNavigationBar: BlocConsumer<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state.status == BookingStatus.success) {
            context.go(AppRoutes.success);
          }
        },
        builder: (context, bookingState) {
          final isLoading = bookingState.status == BookingStatus.loading;
          return KioskBottomBar(
            total: 'Total : \$215.00',
            subtitle: '2 Service Selected',
            secondaryLabel: 'Cancel',
            onSecondary: () => context.pop(),
            primaryLabel: isLoading ? 'Signing...' : 'Sign Consent',
            onPrimary: isLoading ? null : _openConsentModal,
            primaryEnabled: !isLoading,
          );
        },
      ),
      body: BlocBuilder<ConsentBloc, ConsentState>(
        builder: (context, consentState) {
          final session = context.watch<SessionBloc>().state;
          return Padding(
            padding: EdgeInsets.all(context.isMobile ? 16 : 24),
            child: PlatformGlassCard(
              radius: 24,
              padding: const EdgeInsets.all(20),
              child: ListView(
                children: [
                  const Text(
                    'Booking Summary',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
                  ),
                  const SizedBox(height: 16),
                  ...session.selectedServices.map(
                    (service) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${service.durationMin} min',
                                  style: const TextStyle(
                                    color: Color(0xFF737373),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\$${service.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 28),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Date',
                          style: TextStyle(color: Color(0xFF737373)),
                        ),
                      ),
                      Text(
                        session.selectedDate
                                ?.toIso8601String()
                                .split('T')
                                .first ??
                            '-',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Time',
                          style: TextStyle(color: Color(0xFF737373)),
                        ),
                      ),
                      Text(session.selectedSlot?.time ?? '-'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Customer',
                          style: TextStyle(color: Color(0xFF737373)),
                        ),
                      ),
                      Text(session.selectedCustomer ?? '-'),
                    ],
                  ),
                  if (consentState.isConsentRequired) ...[
                    const Divider(height: 28),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x1FE12242),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x66E12242)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFFE12242),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'One or more services require consent. You will be asked to sign before confirming.',
                              style: TextStyle(
                                color: Color(0xFFE12242),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
