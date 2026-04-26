import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Global shimmer wrapper. Wrap any skeleton widget with this
/// to get consistent shimmer colors across the whole app.
///
/// Usage:
/// ```dart
/// AppShimmer(
///   child: Column(
///     children: [
///       ShimmerBox(height: 80, borderRadius: 12),
///       ShimmerBox(height: 80, borderRadius: 12),
///     ],
///   ),
/// )
/// ```
class AppShimmer extends StatelessWidget {
  const AppShimmer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Color(0xFFF5F5F5),
      highlightColor: Color.fromARGB(255, 154, 154, 154),
      child: child,
    );
  }
}

/// A plain white rounded box — use as the skeleton shape inside [AppShimmer].
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    required this.height,
    this.width = double.infinity,
    this.borderRadius = 12,
    super.key,
  });

  final double height;
  final double width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
