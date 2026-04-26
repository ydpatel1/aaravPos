import 'package:flutter/material.dart';

class AaravPosLogo extends StatelessWidget {
  const AaravPosLogo({this.size = LogoSize.medium, super.key});

  final LogoSize size;

  @override
  Widget build(BuildContext context) {
    final avatarRadius = switch (size) {
      LogoSize.small => 16.0,
      LogoSize.medium => 22.0,
      LogoSize.large => 28.0,
    };
    final iconSize = switch (size) {
      LogoSize.small => 16.0,
      LogoSize.medium => 22.0,
      LogoSize.large => 28.0,
    };
    final titleSize = switch (size) {
      LogoSize.small => 24.0,
      LogoSize.medium => 36.0,
      LogoSize.large => 44.0,
    };
    final subtitleSize = switch (size) {
      LogoSize.small => 12.0,
      LogoSize.medium => 16.0,
      LogoSize.large => 20.0,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: avatarRadius,
          backgroundColor: const Color(0xFFE12242),
          child: Icon(Icons.content_cut, color: Colors.white, size: iconSize),
        ),
        const SizedBox(width: 10),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Aarav',
                style: TextStyle(
                  fontSize: titleSize,
                  color: const Color(0xFFE12242),
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: 'POS',
                style: TextStyle(
                  fontSize: subtitleSize,
                  color: const Color(0xFFE12242),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum LogoSize { small, medium, large }
