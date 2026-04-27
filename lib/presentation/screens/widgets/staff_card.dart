import 'package:aaravpos/core/storage/secure_storage.dart';
import 'package:aaravpos/core/theme/app_colors.dart';
import 'package:aaravpos/core/utils/extensions/space_extension.dart';
import 'package:aaravpos/core/utils/helpers/injector.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../shared/widgets/platform_glass_card.dart';

class StaffCard extends StatelessWidget {
  const StaffCard({
    required this.name,
    required this.role,
    required this.index,
    required this.isSelected,
    required this.onTap,
    this.color,
    this.imageUrl,
    super.key,
  });

  final String name;
  final String role;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;
  final String? color; // HSL color from API
  final String? imageUrl; // Full image URL

  /// Fallback pastel colors if API doesn't provide color
  static const List<Color> _pastelColors = [
    Color(0xFFF0DDE2), // Pink
    Color(0xFFD8E3EB), // Blue
    Color(0xFFE7E7D8), // Yellow
    Color(0xFFE9DBEA), // Purple
    Color(0xFFD7E8F4), // Light Blue
  ];

  /// Parse HSL color string from API (e.g., "hsl(353.41, 30%, 78.04%)")
  Color _parseHslColor(String hslString) {
    try {
      // Extract numbers from "hsl(h, s%, l%)"
      final regex = RegExp(r'hsl\(([^,]+),\s*([^%]+)%,\s*([^%]+)%\)');
      final match = regex.firstMatch(hslString);

      if (match != null) {
        final h = double.parse(match.group(1)!);
        final s = double.parse(match.group(2)!) / 100;
        final l = double.parse(match.group(3)!) / 100;

        return HSLColor.fromAHSL(1.0, h, s, l).toColor();
      }
    } catch (e) {
      // If parsing fails, return fallback color
    }
    return _pastelColors[index % _pastelColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = color != null
        ? _parseHslColor(color!)
        : _pastelColors[index % _pastelColors.length];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: PlatformGlassCard(
        color: backgroundColor,
        radius: 24,
        border: Border.all(
          color: isSelected ? const Color(0xFFE12242) : Colors.transparent,
          width: 2,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAvatar(isSelected: isSelected),
              16.vs,
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: isSelected ? const Color(0xFFE12242) : Colors.black,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              5.vs,
              Text(
                role,
                style: const TextStyle(color: Color(0xFF737373), fontSize: 14),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar({bool isSelected = false}) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.error : Colors.white,
          width: 3,
        ),
      ),
      child: FutureBuilder<String?>(
        future: getIt<SecureStorage>().getToken(),
        builder: (context, snapshot) {
          final token = snapshot.data;

          if (imageUrl != null && imageUrl!.isNotEmpty && token != null) {
            return ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                width: 76,
                height: 76,
                fit: BoxFit.cover,
                httpHeaders: {'Authorization': 'Bearer $token'},
                placeholder: (context, url) => CircleAvatar(
                  radius: 38,
                  backgroundColor: const Color(0xFFD4D4D6),
                  child: Icon(Icons.person, size: 40, color: AppColors.black),
                ),
                errorWidget: (context, url, error) => CircleAvatar(
                  radius: 38,
                  backgroundColor: const Color(0xFFD4D4D6),
                  child: Icon(Icons.person, size: 40, color: AppColors.black),
                ),
              ),
            );
          }

          // Fallback to icon if no image
          return CircleAvatar(
            radius: 38,
            backgroundColor: const Color(0xFFD4D4D6),
            child: Icon(Icons.person, size: 40, color: const Color(0xFF737373)),
          );
        },
      ),
    );
  }
}
