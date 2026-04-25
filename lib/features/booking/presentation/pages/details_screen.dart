import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/platform_glass_card.dart';
import '../blocs/booking_bloc.dart';
import '../cubit/session_cubit.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>().state;
    final bookingId = context.watch<BookingBloc>().state.bookingId ?? 'N/A';

    return Scaffold(
      appBar: const CommonAppBar(title: 'Appointment Confirmed'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: PlatformGlassCard(
          radius: 20,
          border: Border.all(color: const Color(0xFFE12242), width: 1.4),
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              Text('Booking: $bookingId'),
              const SizedBox(height: 8),
              Text('Customer: ${session.selectedCustomer ?? '-'}'),
              const Divider(height: 30),
              const Text('Service Selected', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
              const SizedBox(height: 12),
              ...session.selectedServices.map(
                (service) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(service.name, style: const TextStyle(fontSize: 18)),
                            Text('${service.durationMin} min', style: const TextStyle(color: Color(0xFF737373))),
                          ],
                        ),
                      ),
                      Text('\$${service.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
                    ],
                  ),
                ),
              ),
              const Divider(height: 30),
              const Row(
                children: [
                  Expanded(child: Text('Subtotal', style: TextStyle(fontSize: 24))),
                  Text('\$215.00', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context.read<SessionCubit>().reset();
                  context.go(AppRoutes.home);
                },
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
