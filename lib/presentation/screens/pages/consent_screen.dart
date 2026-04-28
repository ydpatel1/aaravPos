import 'dart:convert';

import 'package:aaravpos/presentation/bloc/booking/booking_bloc.dart';
import 'package:aaravpos/presentation/bloc/consent/consent_bloc.dart';
import 'package:aaravpos/presentation/bloc/session/session_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:signature/signature.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/extensions/context_extension.dart';
import '../../../../core/utils/extensions/space_extension.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/kiosk_bottom_bar.dart';
import '../../../../shared/widgets/platform_glass_card.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-open dialog if consent is already determined to be needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final status = context.read<ConsentBloc>().state.status;
      if (status == ConsentStatus.needsSign) {
        _openConsentDialog();
      } else if (status == ConsentStatus.skipped) {
        context.read<BookingBloc>().submitBooking();
      }
    });
  }

  Future<void> _openConsentDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<ConsentBloc>(),
        child: const _ConsentDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionBloc>().state;

    return Scaffold(
      appBar: const CommonAppBar(title: 'Review & Confirm'),
      bottomNavigationBar: BlocConsumer<BookingBloc, BookingState>(
        listener: (context, bookingState) {
          if (bookingState.status == BookingStatus.success) {
            context.go(AppRoutes.success);
          }
        },
        builder: (context, bookingState) {
          return BlocConsumer<ConsentBloc, ConsentState>(
            listener: (context, consentState) {
              if (consentState.status == ConsentStatus.skipped) {
                // No consent needed → submit booking directly
                context.read<BookingBloc>().submitBooking();
              } else if (consentState.status == ConsentStatus.signed) {
                // Consent signed → submit booking
                context.read<BookingBloc>().submitBooking();
              } else if (consentState.status == ConsentStatus.needsSign) {
                _openConsentDialog();
              }
            },
            builder: (context, consentState) {
              final isLoading =
                  bookingState.status == BookingStatus.loading ||
                  consentState.status == ConsentStatus.checking ||
                  consentState.status == ConsentStatus.signing;

              return KioskBottomBar(
                total: 'Total: ${session.formattedTotal}',
                subtitle: '${session.selectedServices.length} Service Selected',
                secondaryLabel: 'Cancel',
                onSecondary: () => context.pop(),
                primaryLabel: isLoading ? 'Please wait...' : 'Sign Consent',
                onPrimary: isLoading ? null : _openConsentDialog,
                primaryEnabled: !isLoading,
              );
            },
          );
        },
      ),
      body: BlocBuilder<ConsentBloc, ConsentState>(
        builder: (context, consentState) {
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
                  16.vs,
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
                  _summaryRow(
                    Icons.calendar_today,
                    'Date',
                    session.selectedDate?.toIso8601String().split('T').first ??
                        '-',
                  ),
                  8.vs,
                  _summaryRow(
                    Icons.access_time,
                    'Time',
                    session.selectedSlot?.startTime ?? '-',
                  ),
                  8.vs,
                  _summaryRow(
                    Icons.person_outline,
                    'Customer',
                    session.selectedCustomer ?? '-',
                  ),
                  if (consentState.status == ConsentStatus.error) ...[
                    16.vs,
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x1FE12242),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x66E12242)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Color(0xFFE12242),
                            size: 18,
                          ),
                          8.hs,
                          Expanded(
                            child: Text(
                              consentState.errorMessage ?? 'An error occurred',
                              style: const TextStyle(
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

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF737373)),
        8.hs,
        Text(label, style: const TextStyle(color: Color(0xFF737373))),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Consent Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _ConsentDialog extends StatefulWidget {
  const _ConsentDialog();

  @override
  State<_ConsentDialog> createState() => _ConsentDialogState();
}

class _ConsentDialogState extends State<_ConsentDialog> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  final TextEditingController _typedNameController = TextEditingController();

  bool _emailMe = false;
  bool _checkboxAgreed = false;
  bool _hasSignature = false;

  @override
  void initState() {
    super.initState();
    _signatureController.addListener(() {
      final hasPoints = _signatureController.isNotEmpty;
      if (hasPoints != _hasSignature) {
        setState(() => _hasSignature = hasPoints);
      }
    });
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _typedNameController.dispose();
    super.dispose();
  }

  bool get _canConfirm {
    final type = context.read<ConsentBloc>().state.signatureType;
    if (type == 'CHECKBOX_ONLY') return _checkboxAgreed;
    if (type == 'TYPED_NAME') {
      return _typedNameController.text.trim().isNotEmpty;
    }
    return _hasSignature;
  }

  Future<void> _confirm() async {
    final type = context.read<ConsentBloc>().state.signatureType;

    if (type == 'SIGNATURE_IMAGE') {
      final bytes = await _signatureController.toPngBytes();
      if (bytes == null || !mounted) return;
      final base64Str = 'data:image/png;base64,${base64Encode(bytes)}';
      context.read<ConsentBloc>().add(
        ConsentSignRequested(signatureType: type, imageUrl: base64Str),
      );
    } else if (type == 'TYPED_NAME') {
      context.read<ConsentBloc>().add(
        ConsentSignRequested(
          signatureType: type,
          typedName: _typedNameController.text.trim(),
        ),
      );
    } else {
      context.read<ConsentBloc>().add(
        const ConsentSignRequested(signatureType: 'CHECKBOX_ONLY'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return BlocConsumer<ConsentBloc, ConsentState>(
      listener: (context, state) {
        if (state.status == ConsentStatus.signed) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, consentState) {
        final type = consentState.signatureType;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(isMobile ? 12 : 40),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 640,
            ),
            child: PlatformGlassCard(
              radius: 24,
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      'Consent Required',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    12.vs,

                    // Scrollable consent text
                    if (consentState.consentText.isNotEmpty) ...[
                      Container(
                        height: isMobile ? 140 : 180,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: SingleChildScrollView(
                          child: Text(
                            consentState.consentText,
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ),
                      ),
                      16.vs,
                    ],

                    // Signature section
                    if (type == 'SIGNATURE_IMAGE') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Sign Here',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              _signatureController.clear();
                              setState(() => _hasSignature = false);
                            },
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Clear'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFE12242),
                            ),
                          ),
                        ],
                      ),
                      6.vs,
                      Container(
                        height: isMobile ? 180 : 220,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _hasSignature
                                ? const Color(0xFFE12242)
                                : const Color(0xFFD7D7DA),
                            width: _hasSignature ? 2 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Stack(
                            children: [
                              Signature(
                                controller: _signatureController,
                                backgroundColor: Colors.white,
                              ),
                              if (!_hasSignature)
                                const Center(
                                  child: Text(
                                    'Draw your signature here',
                                    style: TextStyle(
                                      color: Color(0xFFB0B0B0),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ] else if (type == 'TYPED_NAME') ...[
                      const Text(
                        'Type your full name',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      8.vs,
                      TextField(
                        controller: _typedNameController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Full name',
                          hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE12242),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ] else ...[
                      // CHECKBOX_ONLY
                      CheckboxListTile(
                        value: _checkboxAgreed,
                        contentPadding: EdgeInsets.zero,
                        activeColor: const Color(0xFFE12242),
                        title: const Text(
                          'I have read and agree to the consent form',
                          style: TextStyle(fontSize: 15),
                        ),
                        onChanged: (v) =>
                            setState(() => _checkboxAgreed = v ?? false),
                      ),
                    ],

                    8.vs,

                    // Email me
                    CheckboxListTile(
                      value: _emailMe,
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFFE12242),
                      title: const Text(
                        'Email me a copy of the signed consent',
                      ),
                      onChanged: (v) => setState(() => _emailMe = v ?? false),
                    ),

                    // Inline error
                    if (consentState.errorMessage != null) ...[
                      4.vs,
                      Text(
                        consentState.errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFE12242),
                          fontSize: 13,
                        ),
                      ),
                    ],

                    12.vs,

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed:
                              consentState.status == ConsentStatus.signing
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        12.hs,
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE12242),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFBDBDBD),
                          ),
                          onPressed:
                              (_canConfirm &&
                                  consentState.status != ConsentStatus.signing)
                              ? _confirm
                              : null,
                          child: consentState.status == ConsentStatus.signing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Confirm Signature'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
