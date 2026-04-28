import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/extensions/context_extension.dart';

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({super.key});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-navigate to Details after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) context.go(AppRoutes.details);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 48),
          child: Column(
            children: [
              const Spacer(),
              SizedBox(
                width: isMobile ? 200 : 280,
                height: isMobile ? 200 : 280,
                child: Lottie.asset(
                  'assets/animations/success.json',
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.celebration_rounded,
                    size: isMobile ? 120 : 180,
                    color: const Color(0xFF8D6ED9),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Booking Confirmed!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: isMobile ? 30 : 42,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "We're excited to serve you! Thank you for choosing us. See you soon!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF737373),
                  fontSize: isMobile ? 15 : 20,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
