import 'package:flutter/material.dart';

import '../../../../shared/widgets/platform_glass_card.dart';

class ServiceCard extends StatelessWidget {
  const ServiceCard({
    required this.title,
    required this.duration,
    required this.price,
    required this.consentRequired,
    this.consentTemplateId,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String title;
  final int duration;
  final double price;
  final bool consentRequired;

  /// From service.consentTemplate?.id — badge only shows when this is non-null/non-empty.
  final String? consentTemplateId;

  final bool isSelected;
  final VoidCallback onTap;

  /// True when all three conditions are met (matches review screen logic).
  bool get _showConsentBadge =>
      consentRequired &&
      consentTemplateId != null &&
      consentTemplateId!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: PlatformGlassCard(
        radius: 18,
        border: Border.all(
          color: isSelected ? const Color(0xFFE12242) : const Color(0xFFD7D7DA),
          width: isSelected ? 2 : 1,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                CircleAvatar(
                  radius: 15,
                  backgroundColor: isSelected
                      ? const Color(0xFFE12242)
                      : const Color(0xFFF3F3F4),
                  child: Icon(
                    Icons.add,
                    color: isSelected ? Colors.white : const Color(0xFFE12242),
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_showConsentBadge)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x1FE12242),
                  border: Border.all(color: const Color(0x66E12242)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Consent Required',
                  style: TextStyle(color: Color(0xFFE12242), fontSize: 11),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              '$duration min',
              style: const TextStyle(color: Color(0xFF727272), fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              '\$${price.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Color(0xFFE12242),
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
