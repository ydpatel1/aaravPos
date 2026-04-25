import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/extensions/context_extension.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
              ),
              const Spacer(),
              SizedBox(
                width: isMobile ? 180 : 260,
                height: isMobile ? 180 : 260,
                child: Lottie.asset(
                  'assets/animations/success.json',
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.celebration_rounded,
                    size: isMobile ? 120 : 180,
                    color: const Color(0xFF8D6ED9),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Your salon appointment is confirmed !!',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: isMobile ? 28 : 40),
              ),
              const SizedBox(height: 12),
              Text(
                'We\'re excited to serve you! Thank you for choosing us. See you soon!',
                textAlign: TextAlign.center,
                style: TextStyle(color: const Color(0xFF737373), fontSize: isMobile ? 15 : 22),
              ),
              const Spacer(),
              SizedBox(
                width: isMobile ? double.infinity : 280,
                child: ElevatedButton(onPressed: () => context.go(AppRoutes.details), child: const Text('View Details')),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
