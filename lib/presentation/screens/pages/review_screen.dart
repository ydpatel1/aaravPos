import 'dart:convert' show base64Encode;

import 'package:aaravpos/core/utils/extensions/space_extension.dart';
import 'package:aaravpos/domain/model/customer.dart';
import 'package:aaravpos/presentation/bloc/booking/booking_bloc.dart';
import 'package:aaravpos/presentation/bloc/consent/consent_bloc.dart';
import 'package:aaravpos/presentation/bloc/customer/customer_bloc.dart';
import 'package:aaravpos/presentation/bloc/session/session_bloc.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:signature/signature.dart';

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

  Customer? _selectedCustomer;
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

  void _onCustomerSelected(Customer customer) {
    setState(() {
      _selectedCustomer = customer;
      _showSuggestions = false;
      _firstNameController.text = customer.firstName;
      _lastNameController.text = customer.lastName;
      _emailController.text = customer.email ?? '';

      // Extract phone number without country code
      String phone = customer.phone;
      if (phone.startsWith('+')) {
        phone = phone.substring(1);
        for (var i = 1; i <= 4; i++) {
          if (phone.length > i) {
            final code = phone.substring(0, i);
            if (code == _selectedCountry.phoneCode) {
              phone = phone.substring(i);
              break;
            }
          }
        }
      }
      _phoneController.text = phone;
    });

    context.read<SessionBloc>().setCustomer(
      customer.fullName,
      customerId: customer.id,
    );

    // Trigger consent check immediately when customer is selected (per spec §5.2)
    // ConsentBloc will call GET concent/check for ONCE_PER_CUSTOMER services
    context.read<ConsentBloc>().add(
      ConsentCheckRequested(
        customerId: customer.id,
        services: context.read<SessionBloc>().state.selectedServices,
      ),
    );
  }

  void _onPhoneChanged(String value) {
    // Show suggestions dropdown from 3+ digits (UX auto-fill)
    // Trigger the actual API search at 8–9 digits (spec §4)
    final showDropdown = value.length >= 3;
    setState(() {
      _showSuggestions = showDropdown;
      if (_autoValidate) _phoneError = _validatePhone(value);
    });

    if (value.length == 8 || value.length == 9) {
      // Full search with countryCode+phone as the search param (spec §4 API)
      final searchQuery = '+${_selectedCountry.phoneCode}$value';
      context.read<CustomerBloc>().search(searchQuery);
    } else if (value.length >= 3) {
      // Lightweight search for suggestions using phone digits only
      context.read<CustomerBloc>().search(value);
    } else {
      // Below 3 digits — clear everything
      _clearCustomerSelection();
    }
  }

  void _clearCustomerSelection() {
    setState(() {
      _selectedCustomer = null;
      _showSuggestions = false;
    });
    context.read<SessionBloc>().setCustomer('', customerId: null);
    context.read<ConsentBloc>().add(const ConsentReset());
  }

  /// Returns an error string or null if valid.
  String? _validatePhone(String value) {
    final email = _emailController.text.trim();
    if (value.isEmpty && email.isEmpty) return 'Phone or email is required';
    if (value.isNotEmpty && value.length != 10) {
      return 'Phone must be exactly 10 digits';
    }
    return null;
  }

  String? _validateFirstName(String value) {
    if (value.trim().isEmpty) return 'First name is required';
    return null;
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) return null; // optional
    if (!value.contains('@')) return 'Enter a valid email address';
    return null;
  }

  /// Returns true if form is valid, false otherwise.
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

  Future<void> _openConsentDialog(BuildContext ctx) async {
    await showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: ctx.read<ConsentBloc>()),
          BlocProvider.value(value: ctx.read<BookingBloc>()),
        ],
        child: const _ConsentDialog(),
      ),
    );
  }

  void _submitBooking(BuildContext ctx) {
    ctx.read<BookingBloc>().add(
      BookingSubmitted(
        session: ctx.read<SessionBloc>().state,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: '+${_selectedCountry.phoneCode}${_phoneController.text.trim()}',
      ),
    );
  }

  void _submitBookingWithConsent(BuildContext ctx) {
    final consentState = ctx.read<ConsentBloc>().state;
    ctx.read<BookingBloc>().add(
      BookingSubmitted(
        session: ctx.read<SessionBloc>().state,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: '+${_selectedCountry.phoneCode}${_phoneController.text.trim()}',
        consentFormId: consentState.consentFormId,
        signatureType: consentState.signatureType,
        imageUrl: consentState.signedImageUrl,
        typedName: consentState.signedTypedName,
        isChecked: consentState.isChecked,
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
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country;
        });
      },
    );
  }

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
      bottomNavigationBar: BlocConsumer<ConsentBloc, ConsentState>(
        listener: (context, consentState) {
          // Only auto-open dialog when consent check fires after customer selection
          if (consentState.status == ConsentStatus.needsSign) {
            _openConsentDialog(context);
          } else if (consentState.status == ConsentStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  consentState.errorMessage ?? 'Consent check failed',
                ),
                backgroundColor: const Color(0xFFE12242),
              ),
            );
          }
        },
        builder: (context, consentState) {
          final isChecking = consentState.status == ConsentStatus.checking;
          final hasCustomer =
              _selectedCustomer != null ||
              (_firstNameController.text.isNotEmpty &&
                  _phoneController.text.isNotEmpty);
          final needsConsent = session.selectedServices.any(
            (s) => s.consentRequired,
          );

          return BlocConsumer<BookingBloc, BookingState>(
            listener: (context, bookingState) {
              if (bookingState.status == BookingStatus.success) {
                context.read<ConsentBloc>().add(const ConsentReset());
                context.go(AppRoutes.success);
              } else if (bookingState.status == BookingStatus.failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      bookingState.errorMessage ?? 'Booking failed',
                    ),
                    backgroundColor: const Color(0xFFE12242),
                  ),
                );
              }
            },
            builder: (context, bookingState) {
              final isLoading =
                  isChecking || bookingState.status == BookingStatus.loading;
              final buttonLabel = isLoading
                  ? 'Please wait...'
                  : needsConsent
                  ? 'Sign Consent'
                  : 'Continue';

              return KioskBottomBar(
                total: 'Total: ${session.formattedTotal}',
                subtitle: '${session.selectedServices.length} Service Selected',
                secondaryLabel: 'Cancel',
                onSecondary: () => context.pop(),
                primaryLabel: buttonLabel,
                primaryEnabled: hasCustomer && !isLoading,
                onPrimary: isLoading
                    ? null
                    : () {
                        // If consent check already determined needsSign → open dialog
                        if (consentState.status == ConsentStatus.needsSign) {
                          if (!_validateForm()) return;
                          _openConsentDialog(context);
                          return;
                        }
                        // If consent already signed → submit with consent data
                        if (consentState.status == ConsentStatus.signed) {
                          if (!_validateForm()) return;
                          _submitBookingWithConsent(context);
                          return;
                        }
                        // If consent was checked and skipped (not needed) → submit directly
                        if (consentState.status == ConsentStatus.skipped) {
                          if (!_validateForm()) return;
                          _submitBooking(context);
                          return;
                        }
                        // Consent check not yet run → run check now
                        if (!_validateForm()) return;
                        final customerId = session.selectedCustomerId ?? '';
                        context.read<ConsentBloc>().add(
                          ConsentCheckRequested(
                            customerId: customerId,
                            services: session.selectedServices,
                          ),
                        );
                      },
              );
            },
          );
        },
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: BlocBuilder<CustomerBloc, CustomerState>(
          builder: (context, customerState) {
            final leftPanel = PlatformGlassCard(
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
                  // Outlet name (spec §2)
                  if (session.selectedStaff != null) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.store_outlined,
                          size: 18,
                          color: Color(0xFF737373),
                        ),
                        8.hs,
                        Text(
                          session.selectedStaff!.fullName,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF737373),
                          ),
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                if (service.consentRequired)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0x1FE12242),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0x66E12242),
                                      ),
                                    ),
                                    child: const Text(
                                      'Consent Required',
                                      style: TextStyle(
                                        color: Color(0xFFE12242),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                4.vs,
                                Text(
                                  '${service.durationMin} Minutes',
                                  style: const TextStyle(
                                    color: Color(0xFF737373),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\$${service.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  12.vs,
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: Color(0xFF737373),
                      ),
                      8.hs,
                      Text(
                        session.selectedDate != null
                            ? '${session.selectedDate!.day.toString().padLeft(2, '0')}-${session.selectedDate!.month.toString().padLeft(2, '0')}-${session.selectedDate!.year}'
                            : 'No date selected',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  8.vs,
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 18,
                        color: Color(0xFF737373),
                      ),
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

            final rightPanel = PlatformGlassCard(
              radius: 24,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                      children: [
                        TextSpan(text: 'Mobile Number '),
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: Color(0xFFE12242)),
                        ),
                      ],
                    ),
                  ),
                  12.vs,
                  Row(
                    children: [
                      // Country Code Picker Section
                      InkWell(
                        onTap: _showCountryPicker,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 08,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD7D7DA)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedCountry.flagEmoji,
                                style: const TextStyle(fontSize: 24),
                              ),
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
                      // Phone Number Input Section
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            hintText: '93275167',
                            hintStyle: const TextStyle(
                              color: Color(0xFFB0B0B0),
                            ),
                            prefixIcon: const Icon(
                              Icons.phone_outlined,
                              color: Color(0xFF737373),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFD7D7DA),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFD7D7DA),
                              ),
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
                          onChanged: _onPhoneChanged,
                        ),
                      ),
                    ],
                  ),
                  // Inline phone validation error (spec §7)
                  if (_autoValidate && _phoneError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        _phoneError!,
                        style: const TextStyle(
                          color: Color(0xFFE12242),
                          fontSize: 12,
                        ),
                      ),
                    ),

                  // Customer suggestions as cards below phone field
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          // Spec §4: show Full Name + Phone + Email
                          subtitle: Text(
                            [
                              customer.phone,
                              if (customer.email != null &&
                                  customer.email!.isNotEmpty)
                                customer.email!,
                            ].join(' · '),
                            style: const TextStyle(
                              color: Color(0xFF737373),
                              fontSize: 14,
                            ),
                          ),
                          onTap: () => _onCustomerSelected(customer),
                        ),
                      ),
                    ),

                  16.vs,
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      children: [
                        TextSpan(text: 'First Name '),
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: Color(0xFFE12242)),
                        ),
                      ],
                    ),
                  ),
                  8.vs,
                  TextField(
                    controller: _firstNameController,
                    onChanged: (_) {
                      if (_autoValidate) {
                        setState(() {
                          _firstNameError = _validateFirstName(
                            _firstNameController.text,
                          );
                        });
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter Your First Name Here',
                      hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: Color(0xFF737373),
                      ),
                      errorText: _autoValidate ? _firstNameError : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFD7D7DA)),
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
                  16.vs,
                  const Text(
                    'Last Name',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  8.vs,
                  TextField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      hintText: 'Enter Your Last Name Here',
                      hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: Color(0xFF737373),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFD7D7DA)),
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
                  16.vs,
                  const Text(
                    'Email',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  8.vs,
                  TextField(
                    controller: _emailController,
                    onChanged: (_) {
                      if (_autoValidate) {
                        setState(() {
                          _emailError = _validateEmail(_emailController.text);
                          // Also re-validate phone (phone OR email required)
                          _phoneError = _validatePhone(
                            _phoneController.text.trim(),
                          );
                        });
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter Your Email Here',
                      hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: Color(0xFF737373),
                      ),
                      errorText: _autoValidate ? _emailError : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFD7D7DA)),
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
                ],
              ),
            );

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
}

// ─────────────────────────────────────────────────────────────────────────────
// Consent Dialog — shown inline from ReviewScreen via showDialog
// ─────────────────────────────────────────────────────────────────────────────

class _ConsentDialog extends StatefulWidget {
  const _ConsentDialog();

  @override
  State<_ConsentDialog> createState() => _ConsentDialogState();
}

class _ConsentDialogState extends State<_ConsentDialog> {
  final SignatureController _sigController = SignatureController(
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
    _sigController.addListener(() {
      final has = _sigController.isNotEmpty;
      if (has != _hasSignature) setState(() => _hasSignature = has);
    });
  }

  @override
  void dispose() {
    _sigController.dispose();
    _typedNameController.dispose();
    super.dispose();
  }

  bool get _canConfirm {
    final type = context.read<ConsentBloc>().state.signatureType;
    switch (type) {
      case 'CHECKBOX_ONLY':
        return _checkboxAgreed;
      case 'TYPED_NAME':
        return _typedNameController.text.trim().isNotEmpty;
      default:
        return _hasSignature;
    }
  }

  Future<void> _confirm() async {
    final bloc = context.read<ConsentBloc>();
    final type = bloc.state.signatureType;

    if (type == 'SIGNATURE_IMAGE') {
      final bytes = await _sigController.toPngBytes();
      if (bytes == null || !mounted) return;
      final b64 = 'data:image/png;base64,${base64Encode(bytes)}';
      bloc.add(ConsentSignRequested(signatureType: type, imageUrl: b64));
    } else if (type == 'TYPED_NAME') {
      bloc.add(
        ConsentSignRequested(
          signatureType: type,
          typedName: _typedNameController.text.trim(),
        ),
      );
    } else {
      bloc.add(
        const ConsentSignRequested(
          signatureType: 'CHECKBOX_ONLY',
          isChecked: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return BlocConsumer<ConsentBloc, ConsentState>(
      listener: (context, state) {
        if (state.status == ConsentStatus.signed) {
          Navigator.of(
            context,
          ).pop(); // close dialog — ReviewScreen listener handles booking
        }
      },
      builder: (context, state) {
        final type = state.signatureType;
        final isSigning = state.status == ConsentStatus.signing;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 40,
            vertical: isMobile ? 24 : 40,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 900, // spec §10: 900×700
              maxHeight: 700,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5), // spec §10
                borderRadius: BorderRadius.circular(24),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Title ────────────────────────────────────────────────
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? 20 : 28,
                        isMobile ? 20 : 24,
                        isMobile ? 20 : 28,
                        12,
                      ),
                      child: Text(
                        // spec §10: title from service.consentTemplate.heading
                        state.consentHeading.isNotEmpty
                            ? state.consentHeading
                            : 'Consent Form Title',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    // ── Scrollable consent text ──────────────────────────────
                    if (state.consentText.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 24,
                        ),
                        child: Container(
                          constraints: BoxConstraints(
                            maxHeight: isMobile ? 180 : 240,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7F8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(14),
                              child: Text(
                                state.consentText,
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

                    // ── Signature section ────────────────────────────────────
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? 16 : 24,
                        16,
                        isMobile ? 16 : 24,
                        0,
                      ),
                      child: _buildSignatureSection(type, isMobile),
                    ),

                    // ── Email me ─────────────────────────────────────────────
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 16,
                      ),
                      child: CheckboxListTile(
                        value: _emailMe,
                        contentPadding: EdgeInsets.zero,
                        activeColor: const Color(0xFFE12242),
                        dense: true,
                        title: const Text(
                          'Email me',
                          style: TextStyle(fontSize: 15),
                        ),
                        onChanged: (v) => setState(() => _emailMe = v ?? false),
                      ),
                    ),

                    // ── Inline error ─────────────────────────────────────────
                    if (state.errorMessage != null)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 24,
                        ),
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFE12242),
                            fontSize: 13,
                          ),
                        ),
                      ),

                    // ── Buttons ──────────────────────────────────────────────
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? 16 : 24,
                        12,
                        isMobile ? 16 : 24,
                        isMobile ? 20 : 24,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFE12242),
                                ),
                                foregroundColor: const Color(0xFFE12242),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              onPressed: isSigning
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                          ),
                          12.hs,
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE12242),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: const Color(
                                  0xFFBDBDBD,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 12,
                                ),
                              ),
                              onPressed: (_canConfirm && !isSigning)
                                  ? _confirm
                                  : null,
                              child: isSigning
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Confirm'),
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
      },
    );
  }

  Widget _buildSignatureSection(String type, bool isMobile) {
    if (type == 'SIGNATURE_IMAGE') {
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
                onPressed: () {
                  _sigController.clear();
                  setState(() => _hasSignature = false);
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Clear'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF737373),
                ),
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
                    controller: _sigController,
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
        ],
      );
    }

    if (type == 'TYPED_NAME') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Type Your Name', // spec §10
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
        ],
      );
    }

    // CHECKBOX_ONLY
    return CheckboxListTile(
      value: _checkboxAgreed,
      contentPadding: EdgeInsets.zero,
      activeColor: const Color(0xFFE12242),
      title: const Text(
        'I have read and agree to the consent form',
        style: TextStyle(fontSize: 15),
      ),
      onChanged: (v) => setState(() => _checkboxAgreed = v ?? false),
    );
  }
}
