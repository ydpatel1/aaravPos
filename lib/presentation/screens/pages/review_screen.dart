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

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/extensions/context_extension.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/kiosk_bottom_bar.dart';
import '../../../../shared/widgets/platform_glass_card.dart';
import '../widgets/consent_dialog.dart';

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

  void _onCustomerSelected(Customer customer) {
    // Parse country code from customer phone, update dropdown, show digits only
    String phone = customer.phone;
    Country newCountry = _selectedCountry;

    if (phone.startsWith('+')) {
      final withoutPlus = phone.substring(1);
      bool found = false;
      // Try longest match first (4 → 1 digits)
      for (var len = 4; len >= 1; len--) {
        if (withoutPlus.length > len) {
          final candidate = withoutPlus.substring(0, len);
          try {
            final matched = CountryParser.parsePhoneCode(candidate);
            newCountry = matched;
            phone = withoutPlus.substring(len);
            found = true;
            break;
          } catch (_) {
            // try shorter
          }
        }
      }
      if (!found) {
        phone = withoutPlus;
      }
    }

    setState(() {
      _selectedCountry = newCountry;
      _showSuggestions = false;
      _firstNameController.text = customer.firstName;
      _lastNameController.text = customer.lastName;
      _emailController.text = customer.email ?? '';
      _phoneController.text = phone;
    });

    context.read<SessionBloc>().setCustomer(
      customer.fullName,
      customerId: customer.id,
    );

    // Run consent check immediately on customer selection
    context.read<ConsentBloc>().add(
      ConsentCheckRequested(
        customerId: customer.id,
        services: context.read<SessionBloc>().state.selectedServices,
        isNewCustomer: false,
      ),
    );
  }

  void _onPhoneChanged(String value) {
    // Any phone edit invalidates a previously selected customer
    final hadCustomer =
        context.read<SessionBloc>().state.selectedCustomerId != null;
    if (hadCustomer) {
      _clearCustomerSelection();
    }

    setState(() {
      _showSuggestions = value.length >= 3;
      if (_autoValidate) _phoneError = _validatePhone(value);
    });

    if (value.length >= 3) {
      // Build full phone with country code: "+91" + "9106..." → "+919106..."
      // The data source will Uri.encodeComponent this before sending.
      final searchQuery = '+${_selectedCountry.phoneCode}$value';
      context.read<CustomerBloc>().search(searchQuery);
    } else {
      // Below 3 digits — cancel any pending debounce and clear results
      context.read<CustomerBloc>().search('');
      setState(() => _showSuggestions = false);
    }
  }

  void _clearCustomerSelection() {
    setState(() {
      _showSuggestions = false;
    });
    context.read<SessionBloc>().setCustomer('', customerId: null);
    context.read<ConsentBloc>().add(const ConsentReset());
  }

  /// Returns an error string or null if valid.
  String? _validatePhone(String value) {
    final email = _emailController.text.trim();
    if (value.isEmpty && email.isEmpty) return 'Phone or email is required';
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
        child: const ConsentDialog(),
      ),
    );
  }

  void _submitBooking(BuildContext ctx) {
    final signedConsents = ctx.read<ConsentBloc>().state.signedConsents;
    ctx.read<BookingBloc>().add(
      BookingSubmitted(
        session: ctx.read<SessionBloc>().state,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: '+${_selectedCountry.phoneCode}${_phoneController.text.trim()}',
        signedConsents: signedConsents,
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
          // Do NOT auto-submit on signed — user must tap Continue themselves.
          // signed just means button changes back to "Continue".
          if (consentState.status == ConsentStatus.error) {
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

              // showSignConsentButton = consent check ran and found services needing sign
              final showSignConsent = consentState.showSignConsentButton;

              String primaryLabel;
              if (isLoading) {
                primaryLabel = 'Please wait...';
              } else if (showSignConsent) {
                primaryLabel = 'Sign Consent';
              } else {
                primaryLabel = 'Continue';
              }

              return KioskBottomBar(
                total: 'Total: ${session.formattedTotal}',
                subtitle:
                    '${session.selectedServices.length} Service Selected',
                secondaryLabel: 'Cancel',
                onSecondary: () => context.pop(),
                primaryLabel: primaryLabel,
                primaryEnabled: !isLoading,
                onPrimary: isLoading
                    ? null
                    : showSignConsent
                        // ── "Sign Consent" tapped → open dialog ──────────
                        ? () => _openConsentDialog(context)
                        // ── "Continue" tapped → validate + submit ─────────
                        : () {
                            if (!_validateForm()) return;
                            FocusScope.of(context).unfocus();
                            _submitBooking(context);
                          },
              );
            },
          );
        },
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: BlocListener<CustomerBloc, CustomerState>(
          // Fix #1 (new customer): when search returns no results, run consent check
          listenWhen: (prev, curr) =>
              prev.isCustomerNotFound != curr.isCustomerNotFound &&
              curr.isCustomerNotFound,
          listener: (ctx, _) {
            ctx.read<ConsentBloc>().add(
              ConsentCheckRequested(
                customerId: '',
                services: ctx.read<SessionBloc>().state.selectedServices,
                isNewCustomer: true,
              ),
            );
          },
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
                                if (service.consentRequired &&
                                    service.consentTemplate?.id != null &&
                                    service.consentTemplate!.id!.isNotEmpty)
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
        ), // closes BlocListener
      ),
    );
  }
}
