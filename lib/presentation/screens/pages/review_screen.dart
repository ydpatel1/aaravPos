import 'package:aaravpos/presentation/bloc/customer/customer_bloc.dart';
import 'package:aaravpos/presentation/bloc/session/session_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/extensions/context_extension.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/kiosk_bottom_bar.dart';
import '../../../../shared/widgets/platform_glass_card.dart';

import '../widgets/customer_dropdown.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _phoneController = TextEditingController(text: '1234567890');
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().search('');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionBloc>().state;
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: const CommonAppBar(title: 'Review & Confirm'),
      bottomNavigationBar: KioskBottomBar(
        total: 'Total : \$215.00',
        subtitle: '2 Service Selected',
        secondaryLabel: 'Cancel',
        onSecondary: () => context.pop(),
        primaryLabel: 'Continue',
        primaryEnabled: session.selectedCustomer != null,
        onPrimary: () => context.push(AppRoutes.consent),
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
                  ...session.selectedServices.map(
                    (service) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                                if (service.consentRequired)
                                  Container(
                                    margin: const EdgeInsets.only(top: 6),
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
                                const SizedBox(height: 6),
                                Text(
                                  '${service.durationMin} Minutes',
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
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    'Date: ${session.selectedDate?.toIso8601String().split('T').first ?? '23-04-2026'}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Time: ${session.selectedSlot?.startTime ?? '11:00 AM'}',
                  ),
                ],
              ),
            );

            final rightPanel = PlatformGlassCard(
              radius: 24,
              padding: const EdgeInsets.all(20),
              child: ListView(
                shrinkWrap: true,
                children: [
                  const Text(
                    'Mobile Number *',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 88,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD7D7DA)),
                        ),
                        child: const Text('+1'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.phone_outlined),
                            hintText: '1234567890',
                          ),
                          onChanged: context.read<CustomerBloc>().search,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CustomerDropdown(
                    customers: customerState.results,
                    value: session.selectedCustomer,
                    onChanged: (value) {
                      if (value != null) {
                        context.read<SessionBloc>().setCustomer(value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _firstName,
                    decoration: const InputDecoration(
                      labelText: 'First Name *',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _lastName,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                ],
              ),
            );

            if (isMobile) {
              return ListView(
                children: [leftPanel, const SizedBox(height: 12), rightPanel],
              );
            }

            return Row(
              children: [
                Expanded(child: leftPanel),
                const SizedBox(width: 16),
                Expanded(child: rightPanel),
              ],
            );
          },
        ),
      ),
    );
  }
}
