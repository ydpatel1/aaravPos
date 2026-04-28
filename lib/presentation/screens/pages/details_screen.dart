import 'package:aaravpos/presentation/bloc/booking/booking_bloc.dart';
import 'package:aaravpos/presentation/bloc/consent/consent_bloc.dart';
import 'package:aaravpos/presentation/bloc/session/session_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/extensions/context_extension.dart';
import '../../../../core/utils/extensions/space_extension.dart';
import '../../../../shared/widgets/platform_glass_card.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  void _goHome(BuildContext context) {
    context.read<SessionBloc>().reset();
    context.read<ConsentBloc>().add(const ConsentReset());
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionBloc>().state;
    final bookingId = context.watch<BookingBloc>().state.bookingId ?? 'N/A';
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Appointment Details',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _goHome(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: PlatformGlassCard(
          radius: 20,
          border: Border.all(color: const Color(0xFFE12242), width: 1.4),
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              // Booking ID & customer
              Row(
                children: [
                  const Icon(
                    Icons.confirmation_number_outlined,
                    color: Color(0xFFE12242),
                    size: 20,
                  ),
                  8.hs,
                  Text(
                    'Booking ID: $bookingId',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              8.vs,
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    color: Color(0xFF737373),
                    size: 20,
                  ),
                  8.hs,
                  Text(
                    session.selectedCustomer ?? '-',
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
              const Divider(height: 32),

              // Services
              const Text(
                'Services',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              16.vs,
              ...session.selectedServices.map(
                (service) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
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
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        service.displayPrice,
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

              // Subtotal
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Subtotal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    session.formattedTotal,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE12242),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
