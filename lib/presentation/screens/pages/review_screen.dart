
// review_screen.dart — Review & Confirm Screen
// Implements all API flows per spec: customer search, consent check, appointment creation, consent sign.
import 'dart:convert' show base64Encode;
import 'dart:ui' as ui;

import 'package:aaravpos/core/utils/extensions/space_extension.dart';
import 'package:aaravpos/domain/model/consent_check_result.dart';
import 'package:aaravpos/domain/model/customer.dart';
import 'package:aaravpos/domain/model/signed_consent_data.dart';
import 'package:aaravpos/presentation/bloc/booking/booking_bloc.dart';
import 'package:aaravpos/presentation/bloc/consent/consent_bloc.dart';
import 'package:aaravpos/presentation/bloc/customer/customer_bloc.dart';
import 'package:aaravpos/presentation/bloc/session/session_bloc.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/extensions/context_extension.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/kiosk_bottom_bar.dart';
import '../../../../shared/widgets/platform_glass_card.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _phoneController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _showSuggestions = false;
  bool _autoValidate = false;
  String? _phoneError;
  String? _firstNameError;
  String? _emailError;

  Country _selectedCountry = Country(
    phoneCode: '1',
    countryCode: 'US',
    e164Sc: 0,
    geographic: true,
    level: 1,
    name: 'United States',
    example: '2012345678',
    displayName: 'United States (US) [+1]',
    displayNameNoCountryCode: 'United States (US)',
    e164Key: '',
  );

  @override
  void dispose() {
    _phoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ── Customer selection ──────────────────────────────────────────────────────

  void _onCustomerSelected(Customer customer) {
    // Extract phone digits without country code for display
    String phone = customer.phone;
    if (phone.startsWith('+')) {
      phone = phone.substring(1);
      for (var i = 1; i <= 4; i++) {
        if (phone.length > i &&
            phone.substring(0, i) == _selectedCountry.phoneCode) {
          phone = phone.substring(i);
          break;
        }
      }
    }

    setState(() {
      _showSuggestions = false;
      _firstNameController.text = customer.firstName;
      _lastNameController.text = customer.lastName;
      _emailController.text = customer.email ?? '';
      _phoneController.text = phone;
    });

    // Store customer ID in session — consent check happens on Continue tap
    context.read<SessionBloc>().setCustomer(
      customer.fullName,
      customerId: customer.id,
    );
  }

  // ── Phone change handler ────────────────────────────────────────────────────

  void _onPhoneChanged(String value) {
    if (_autoValidate) {
      setState(() => _phoneError = _validatePhone(value));
    }

    // Show suggestions from 3+ digits with debounce
    if (value.length >= 3) {
      final searchQuery = '$value';
      context.read<CustomerBloc>().search(searchQuery);
      setState(() => _showSuggestions = true);
    } else {
      // Below 3 digits → clear everything
      _clearCustomerSelection();
    }
  }

  void _clearCustomerSelection() {
    setState(() {
      _showSuggestions = false;
    });
    context.read<CustomerBloc>().clear();
    context.read<SessionBloc>().setCustomer('', customerId: null);
    context.read<ConsentBloc>().add(const ConsentReset());
  }

  // ── Consent trigger ─────────────────────────────────────────────────────────

  void _triggerConsentCheck({required String customerId, required bool isNewCustomer}) {
    final services = context.read<SessionBloc>().state.selectedServices;
    context.read<ConsentBloc>().add(
      ConsentCheckRequested(
        customerId: customerId,
        services: services,
        isNewCustomer: isNewCustomer,
      ),
    );
  }

  // ── Validation ──────────────────────────────────────────────────────────────

  String? _validatePhone(String value) {
    final email = _emailController.text.trim();
    if (value.isEmpty && email.isEmpty) return 'Phone or email is required';
    if (value.isNotEmpty && value.length != 10) return 'Phone must be exactly 10 digits';
    return null;
  }

  String? _validateFirstName(String value) {
    if (value.trim().isEmpty) return 'First name is required';
    return null;
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) return null;
    if (!value.contains('@')) return 'Enter a valid email address';
    return null;
  }

  bool _validateForm() {
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final firstName = _firstNameController.text.trim();

    final phoneErr = _validatePhone(phone);
    final firstNameErr = _validateFirstName(firstName);
    final emailErr = _validateEmail(email);

    setState(() {
      _autoValidate = true;
      _phoneError = phoneErr;
      _firstNameError = firstNameErr;
      _emailError = emailErr;
    });

    return phoneErr == null && firstNameErr == null && emailErr == null;
  }

  // ── Consent dialog ──────────────────────────────────────────────────────────

  Future<void> _openConsentDialog(BuildContext ctx, ConsentCheckResult result) async {
    await showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: ctx.read<ConsentBloc>()),
        ],
        child: _ConsentDialog(consentResult: result),
      ),
    );
  }

  // ── Booking submission ──────────────────────────────────────────────────────

  void _handleConfirm(BuildContext ctx) {
    if (!_validateForm()) return;
    FocusScope.of(ctx).unfocus();

    final session = ctx.read<SessionBloc>().state;
    final customerId = session.selectedCustomerId ?? '';
    final isNewCustomer = customerId.isEmpty;

    // Run consent check first — ConsentBloc listener opens dialog if needed,
    // or transitions to skipped/signed which triggers booking submission.
    _triggerConsentCheck(customerId: customerId, isNewCustomer: isNewCustomer);
  }

  void _submitBooking(BuildContext ctx) {
    final consentState = ctx.read<ConsentBloc>().state;
    ctx.read<BookingBloc>().add(
      BookingSubmitted(
        session: ctx.read<SessionBloc>().state,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: '+${_selectedCountry.phoneCode}${_phoneController.text.trim()}',
        signedConsents: consentState.signedConsents,
      ),
    );
  }

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(
        borderRadius: BorderRadius.circular(16),
        backgroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 16),
        searchTextStyle: const TextStyle(fontSize: 16),
        inputDecoration: InputDecoration(
          hintText: 'Search country',
          hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD7D7DA)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD7D7DA)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE12242), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      onSelect: (Country country) => setState(() => _selectedCountry = country),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionBloc>().state;
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Review & Confirm',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, session),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: BlocBuilder<CustomerBloc, CustomerState>(
          builder: (context, customerState) {
            final leftPanel = _buildSummaryCard(context, session);
            final rightPanel = _buildContactForm(context, customerState);

            if (isMobile) {
              return SingleChildScrollView(
                child: Column(children: [leftPanel, 12.vs, rightPanel]),
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: SingleChildScrollView(child: leftPanel)),
                16.hs,
                Expanded(child: SingleChildScrollView(child: rightPanel)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Bottom bar ──────────────────────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context, SessionState session) {
    return BlocConsumer<ConsentBloc, ConsentState>(
      listener: (ctx, consentState) {
        if (consentState.status == ConsentStatus.needsSign) {
          // Open dialog for the first pending consent
          final next = consentState.nextConsentToSign;
          if (next != null) _openConsentDialog(ctx, next);
        } else if (consentState.status == ConsentStatus.skipped) {
          // No consent needed → submit booking directly
          _submitBooking(ctx);
        } else if (consentState.status == ConsentStatus.signed) {
          // All consents signed → submit booking with signed data
          _submitBooking(ctx);
        }
      },
      builder: (context, consentState) {
        return BlocConsumer<BookingBloc, BookingState>(
          listener: (ctx, bookingState) {
            if (bookingState.status == BookingStatus.success) {
              ctx.read<ConsentBloc>().add(const ConsentReset());
              ctx.read<SessionBloc>().reset();
              // Navigate to success/confirmation screen (spec §11)
              ctx.go(AppRoutes.success);
            } else if (bookingState.status == BookingStatus.failure) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(bookingState.errorMessage ?? 'Booking failed'),
                  backgroundColor: const Color(0xFFE12242),
                ),
              );
            }
          },
          builder: (context, bookingState) {
            final isCheckingConsent = consentState.status == ConsentStatus.checking;
            final isCreating = bookingState.status == BookingStatus.loading;
            final isLoading = isCheckingConsent || isCreating;

            final showSignConsent = consentState.showSignConsentButton;
            final hasPendingMandatory = consentState.hasPendingMandatoryConsent;

            String primaryLabel;
            if (isLoading) {
              primaryLabel = 'Please wait...';
            } else if (showSignConsent) {
              primaryLabel = 'Sign Consent';
            } else {
              primaryLabel = 'Continue';
            }

            // Continue disabled when loading or has pending mandatory unsigned consent
            final primaryEnabled = !isLoading &&
                !(showSignConsent == false && hasPendingMandatory);

            return KioskBottomBar(
              total: 'Total: ${session.formattedTotal}',
              subtitle: '${session.selectedServices.length} Service Selected',
              secondaryLabel: 'Cancel',
              onSecondary: () => context.go(AppRoutes.home),
              primaryLabel: primaryLabel,
              primaryEnabled: primaryEnabled,
              onPrimary: isLoading
                  ? null
                  : showSignConsent
                      ? () {
                          final next = consentState.nextConsentToSign;
                          if (next != null) _openConsentDialog(context, next);
                        }
                      : () => _handleConfirm(context),
            );
          },
        );
      },
    );
  }

  // ── Booking summary card ────────────────────────────────────────────────────

  Widget _buildSummaryCard(BuildContext context, SessionState session) {
    return PlatformGlassCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Summary',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
          ),
          16.vs,
          if (session.selectedStaff != null) ...[
            Row(
              children: [
                const Icon(Icons.store_outlined, size: 18, color: Color(0xFF737373)),
                8.hs,
                Text(
                  session.selectedStaff!.fullName,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF737373)),
                ),
              ],
            ),
            12.vs,
          ],
          ...session.selectedServices.map(
            (service) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        if (service.consentRequired)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0x1FE12242),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0x66E12242)),
                            ),
                            child: const Text(
                              'Consent Required',
                              style: TextStyle(color: Color(0xFFE12242), fontSize: 11),
                            ),
                          ),
                        4.vs,
                        Text(
                          '${service.durationMin} Minutes',
                          style: const TextStyle(color: Color(0xFF737373), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${service.price.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          12.vs,
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 18, color: Color(0xFF737373)),
              8.hs,
              Text(
                session.selectedDate != null
                    ? '${session.selectedDate!.day.toString().padLeft(2, '0')}-'
                        '${session.selectedDate!.month.toString().padLeft(2, '0')}-'
                        '${session.selectedDate!.year}'
                    : 'No date selected',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          8.vs,
          Row(
            children: [
              const Icon(Icons.access_time, size: 18, color: Color(0xFF737373)),
              8.hs,
              Text(
                session.selectedSlot?.startTime ?? 'No time selected',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Contact form card ───────────────────────────────────────────────────────

  Widget _buildContactForm(BuildContext context, CustomerState customerState) {
    return PlatformGlassCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mobile number label
          RichText(
            text: const TextSpan(
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.black),
              children: [
                TextSpan(text: 'Mobile Number '),
                TextSpan(text: '*', style: TextStyle(color: Color(0xFFE12242))),
              ],
            ),
          ),
          12.vs,
          // Country code + phone row
          Row(
            children: [
              InkWell(
                onTap: _showCountryPicker,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD7D7DA)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_selectedCountry.flagEmoji, style: const TextStyle(fontSize: 24)),
                      8.hs,
                      Text(
                        '+${_selectedCountry.phoneCode}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF737373),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              12.hs,
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: '9327516700',
                    hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                    prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF737373)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD7D7DA)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE12242), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: _onPhoneChanged,
                ),
              ),
            ],
          ),
          if (_autoValidate && _phoneError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                _phoneError!,
                style: const TextStyle(color: Color(0xFFE12242), fontSize: 12),
              ),
            ),

          // Customer dropdown (spec §4)
          if (_showSuggestions && customerState.results.isNotEmpty)
            ...customerState.results.map(
              (customer) => Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  title: Text(
                    customer.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  subtitle: Text(
                    [
                      customer.phone,
                      if (customer.email != null && customer.email!.isNotEmpty) customer.email!,
                    ].join(' · '),
                    style: const TextStyle(color: Color(0xFF737373), fontSize: 14),
                  ),
                  onTap: () => _onCustomerSelected(customer),
                ),
              ),
            ),

          16.vs,
          // First name
          RichText(
            text: const TextSpan(
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black),
              children: [
                TextSpan(text: 'First Name '),
                TextSpan(text: '*', style: TextStyle(color: Color(0xFFE12242))),
              ],
            ),
          ),
          8.vs,
          TextField(
            controller: _firstNameController,
            onChanged: (_) {
              if (_autoValidate) {
                setState(() => _firstNameError = _validateFirstName(_firstNameController.text));
              }
            },
            decoration: InputDecoration(
              hintText: 'Enter Your First Name Here',
              hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
              prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF737373)),
              errorText: _autoValidate ? _firstNameError : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD7D7DA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE12242), width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          16.vs,
          // Last name
          const Text('Last Name', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          8.vs,
          TextField(
            controller: _lastNameController,
            decoration: InputDecoration(
              hintText: 'Enter Your Last Name Here',
              hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
              prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF737373)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD7D7DA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE12242), width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          16.vs,
          // Email
          const Text('Email', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          8.vs,
          TextField(
            controller: _emailController,
            onChanged: (_) {
              if (_autoValidate) {
                setState(() => _emailError = _validateEmail(_emailController.text));
              }
            },
            decoration: InputDecoration(
              hintText: 'Enter Your Email Here',
              hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
              prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF737373)),
              errorText: _autoValidate ? _emailError : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD7D7DA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE12242), width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Consent Dialog — shown inline from ReviewScreen via showDialog
// Spec §10: barrierDismissible=false, max 900x700, background Color(0xFFF5F5F5)
// ─────────────────────────────────────────────────────────────────────────────

class _ConsentDialog extends StatefulWidget {
  const _ConsentDialog({required this.consentResult});

  final ConsentCheckResult consentResult;

  @override
  State<_ConsentDialog> createState() => _ConsentDialogState();
}

class _ConsentDialogState extends State<_ConsentDialog> {
  final TextEditingController _typedNameController = TextEditingController();

  bool _emailMe = false;
  bool _checkboxAgreed = false;

  // Draw signature state
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _hasSigned = false;

  @override
  void dispose() {
    _typedNameController.dispose();
    super.dispose();
  }

  String get _signingMethod {
    // Use signatureType from the consent check result (already resolved to KIOSK method)
    return widget.consentResult.signatureType;
  }

  bool get _canConfirm {
    switch (_signingMethod) {
      case 'CHECKBOX_ONLY':
        return _checkboxAgreed;
      case 'TYPED_NAME':
        return _typedNameController.text.trim().isNotEmpty;
      default: // DRAW_SIGNATURE / SIGNATURE_IMAGE
        return _hasSigned;
    }
  }

  Future<void> _confirm(BuildContext ctx) async {
    if (!_canConfirm) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Please complete the consent form before confirming.'),
          backgroundColor: Color(0xFFE12242),
        ),
      );
      return;
    }

    final method = _signingMethod;
    String payload;

    if (method == 'TYPED_NAME') {
      payload = _typedNameController.text.trim();
    } else if (method == 'CHECKBOX_ONLY') {
      payload = 'true';
    } else {
      // DRAW_SIGNATURE — render strokes to PNG and encode as base64
      payload = await _renderSignatureToBase64();
    }

    final signed = SignedConsentData(
      serviceId: widget.consentResult.serviceId,
      consentFormId: widget.consentResult.consentFormId,
      method: method == 'SIGNATURE_IMAGE' ? 'DRAW_SIGNATURE' : method,
      payload: payload,
      signedAt: DateTime.now(),
    );

    if (!ctx.mounted) return;
    ctx.read<ConsentBloc>().add(ConsentSigned(data: signed));
    Navigator.of(ctx).pop();
  }

  Future<String> _renderSignatureToBase64() async {
    const width = 600.0;
    const height = 200.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..color = Colors.white,
    );
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final stroke in _strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final pt in stroke.skip(1)) {
        path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(path, paint);
    }
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    return 'data:image/png;base64,${base64Encode(bytes)}';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final result = widget.consentResult;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 40,
        vertical: isMobile ? 24 : 40,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title (spec §10)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 20 : 28,
                    isMobile ? 20 : 24,
                    isMobile ? 20 : 28,
                    12,
                  ),
                  child: Text(
                    result.consentHeading.isNotEmpty
                        ? result.consentHeading
                        : 'Consent Form Title',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                // Scrollable consent text
                if (result.consentText.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                    child: Container(
                      constraints: BoxConstraints(maxHeight: isMobile ? 180 : 240),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            result.consentText,
                            style: TextStyle(
                              fontSize: isMobile ? 13 : 14,
                              height: 1.6,
                              color: const Color(0xFF333333),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Signature section
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 24,
                    16,
                    isMobile ? 16 : 24,
                    0,
                  ),
                  child: _buildSignatureSection(isMobile),
                ),

                // Email me checkbox (UI only per spec §10)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16),
                  child: CheckboxListTile(
                    value: _emailMe,
                    contentPadding: EdgeInsets.zero,
                    activeColor: const Color(0xFFE12242),
                    dense: true,
                    title: const Text('Email me', style: TextStyle(fontSize: 15)),
                    onChanged: (v) => setState(() => _emailMe = v ?? false),
                  ),
                ),

                // Action buttons
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 24,
                    12,
                    isMobile ? 16 : 24,
                    isMobile ? 20 : 24,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE12242)),
                            foregroundColor: const Color(0xFFE12242),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      12.hs,
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE12242),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFBDBDBD),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                          ),
                          onPressed: _canConfirm ? () => _confirm(context) : null,
                          child: const Text('Confirm'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignatureSection(bool isMobile) {
    final method = _signingMethod;

    if (method == 'TYPED_NAME') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Type Your Name',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          8.vs,
          TextField(
            controller: _typedNameController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Full name',
              hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE12242), width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
      );
    }

    if (method == 'CHECKBOX_ONLY') {
      return CheckboxListTile(
        value: _checkboxAgreed,
        contentPadding: EdgeInsets.zero,
        activeColor: const Color(0xFFE12242),
        title: const Text(
          'I accept the terms and conditions',
          style: TextStyle(fontSize: 15),
        ),
        onChanged: (v) => setState(() => _checkboxAgreed = v ?? false),
      );
    }

    // DRAW_SIGNATURE / SIGNATURE_IMAGE (spec §10)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Sign Here',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            TextButton.icon(
              onPressed: () => setState(() {
                _strokes.clear();
                _currentStroke = [];
                _hasSigned = false;
              }),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Clear'),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF737373)),
            ),
          ],
        ),
        6.vs,
        Container(
          height: isMobile ? 160 : 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hasSigned ? const Color(0xFFE12242) : const Color(0xFFD7D7DA),
              width: _hasSigned ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Stack(
              children: [
                GestureDetector(
                  onPanStart: (d) {
                    setState(() {
                      _currentStroke = [d.localPosition];
                    });
                  },
                  onPanUpdate: (d) {
                    setState(() {
                      _currentStroke.add(d.localPosition);
                      _hasSigned = true;
                    });
                  },
                  onPanEnd: (_) {
                    setState(() {
                      if (_currentStroke.isNotEmpty) {
                        _strokes.add(List.from(_currentStroke));
                      }
                      _currentStroke = [];
                    });
                  },
                  child: CustomPaint(
                    painter: _SignaturePainter(
                      strokes: _strokes,
                      currentStroke: _currentStroke,
                    ),
                    child: Container(color: Colors.white),
                  ),
                ),
                if (!_hasSigned)
                  const Center(
                    child: Text(
                      'Draw your signature here',
                      style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 14),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Signature painter ─────────────────────────────────────────────────────────

class _SignaturePainter extends CustomPainter {
  _SignaturePainter({required this.strokes, required this.currentStroke});

  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final stroke in [...strokes, currentStroke]) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final pt in stroke.skip(1)) {
        path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => true;
}
