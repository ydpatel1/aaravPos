import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class NetworkImageWidget extends StatelessWidget {
  const NetworkImageWidget({
    required this.url,
    this.height,
    this.width,
    super.key,
  });

  final String url;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      height: height,
      width: width,
      placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
      errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
    );
  }
}
