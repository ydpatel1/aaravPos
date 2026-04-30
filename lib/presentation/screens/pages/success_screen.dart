import 'dart:async';

import 'package:flutter/foundation.dart';
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

class _SuccessScreenState extends State<SuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // Auto-navigate to details after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) context.go(AppRoutes.details);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 32 : 64),
          child: Column(
            children: [
              const Spacer(),

              // Celebration Lottie — .lottie format uses decodeZip decoder
              FadeTransition(
                opacity: _opacity,
                child: ScaleTransition(
                  scale: _scale,
                  child: LottieBuilder.asset(
                    'assets/Celebration.lottie',
                    width: isMobile ? 280 : 360,
                    height: isMobile ? 280 : 360,
                    fit: BoxFit.contain,
                    // .lottie files are zip archives — must use decodeZip
                    decoder: LottieComposition.decodeZip,
                    errorBuilder: (_, error, __) {
                      debugPrint('Lottie load error: $error');
                      return Icon(
                        Icons.celebration_rounded,
                        size: isMobile ? 120 : 160,
                        color: const Color(0xFFE12242),
                      );
                    },
                  ),
                ),
              ),

              SizedBox(height: isMobile ? 32 : 40),

              // Title
              FadeTransition(
                opacity: _opacity,
                child: Text(
                  'Your salon appointment is confirmed !!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: isMobile ? 26 : 36,
                    color: const Color(0xFF1A1A1A),
                    height: 1.3,
                  ),
                ),
              ),

              SizedBox(height: isMobile ? 16 : 20),

              // Subtitle
              FadeTransition(
                opacity: _opacity,
                child: Text(
                  "We're excited to serve you! Thank you for choosing us. See you soon!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF737373),
                    fontSize: isMobile ? 15 : 18,
                    height: 1.6,
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
