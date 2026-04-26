import 'package:flutter/material.dart';

import '../../../../shared/widgets/platform_glass_card.dart';

class StaffCard extends StatelessWidget {
  const StaffCard({
    required this.name,
    required this.role,
    required this.index,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String name;
  final String role;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  /// Deterministic pastel colors based on index
  static const List<Color> _pastelColors = [
    Color(0xFFF0DDE2), // Pink
    Color(0xFFD8E3EB), // Blue
    Color(0xFFE7E7D8), // Yellow
    Color(0xFFE9DBEA), // Purple
    Color(0xFFD7E8F4), // Light Blue
  ];

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _pastelColors[index % _pastelColors.length];

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: const Color(0xFFD4D4D6),
              child: Icon(
                Icons.person,
                size: 40,
                color: const Color(0xFF737373),
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 5),
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
    );
  }
}
