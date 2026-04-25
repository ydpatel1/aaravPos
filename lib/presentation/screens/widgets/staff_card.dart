import 'package:flutter/material.dart';

import '../../../../shared/widgets/platform_glass_card.dart';

class StaffCard extends StatelessWidget {
  const StaffCard({
    required this.name,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials = name.split(' ').where((e) => e.isNotEmpty).take(2).map((e) => e[0]).join();
    final palette = [
      const Color(0xFFF0DDE2),
      const Color(0xFFD8E3EB),
      const Color(0xFFE7E7D8),
      const Color(0xFFE9DBEA),
      const Color(0xFFD7E8F4),
    ];
    final bg = palette[name.length % palette.length];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: PlatformGlassCard(
        color: bg,
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
              child: Text(
                initials,
                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF252525)),
              ),
            ),
            const SizedBox(height: 16),
            Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
            const SizedBox(height: 5),
            const Text('Barber', style: TextStyle(color: Color(0xFF737373), fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
