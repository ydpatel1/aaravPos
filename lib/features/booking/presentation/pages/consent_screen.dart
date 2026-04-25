import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:signature/signature.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/extensions/context_extension.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/kiosk_bottom_bar.dart';
import '../../../../shared/widgets/platform_glass_card.dart';
import '../blocs/booking_bloc.dart';
import '../blocs/consent_bloc.dart';
import '../cubit/session_cubit.dart';
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
    final customerName = context.read<SessionCubit>().state.selectedCustomer ?? '';
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
                  decoration: BoxDecoration(color: const Color(0xFFF7F7F8), borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.all(14),
                  child: const SingleChildScrollView(
                    child: Text(
                      'By receiving services at this barbershop, I voluntarily choose barbering and grooming services.\n\nI understand that services may involve clippers, razors, scissors, and heated tools.\n\nI confirm that I have disclosed relevant skin or medical conditions that may affect service.',
                      style: TextStyle(fontSize: 16, height: 1.4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Sign Here', style: TextStyle(fontWeight: FontWeight.w700)),
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
                    OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _controller.isEmpty
                          ? null
                          : () {
                              Navigator.pop(context);
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
          child: SizedBox(width: isMobile ? context.width : 960, child: dialogBody),
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
      body: const SizedBox.expand(),
    );
  }
}
