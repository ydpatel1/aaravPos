import 'dart:ui';

import 'package:flutter/material.dart';

class PlatformGlassCard extends StatelessWidget {
  const PlatformGlassCard({
    required this.child,
    this.padding,
    this.radius = 24,
    this.border,
    this.color,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final BoxBorder? border;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    final decoration = BoxDecoration(
      color: color ?? (isIos ? Colors.white.withOpacity(0.72) : Colors.white),
      borderRadius: BorderRadius.circular(radius),
      border: border,
      boxShadow: const [
        BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 6)),
      ],
    );

    if (!isIos) {
      return Container(
        padding: padding,
        decoration: decoration,
        child: child,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: decoration,
          child: child,
        ),
      ),
    );
  }
}
