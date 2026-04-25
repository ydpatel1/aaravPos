import 'package:flutter/material.dart';

import '../../core/utils/extensions/context_extension.dart';

class KioskBottomBar extends StatelessWidget {
  const KioskBottomBar({
    required this.total,
    required this.subtitle,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.primaryEnabled = true,
    super.key,
  });

  final String total;
  final String subtitle;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool primaryEnabled;

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Container(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 12, isMobile ? 16 : 24, isMobile ? 12 : 18),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F1F2),
        border: Border(top: BorderSide(color: Color(0xFFE3E3E6))),
      ),
      child: isMobile
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(total, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Color(0xFF737373), fontSize: 14)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (secondaryLabel != null) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onSecondary,
                          style: _outlineStyle(),
                          child: Text(secondaryLabel!, style: const TextStyle(color: Color(0xFFE12242), fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: primaryEnabled ? onPrimary : null,
                        style: _primaryStyle(),
                        child: Text(primaryLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(total, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(color: Color(0xFF737373), fontSize: 14)),
                    ],
                  ),
                ),
                if (secondaryLabel != null) ...[
                  OutlinedButton(
                    onPressed: onSecondary,
                    style: _outlineStyle().copyWith(minimumSize: MaterialStateProperty.all(const Size(180, 56))),
                    child: Text(
                      secondaryLabel!,
                      style: const TextStyle(color: Color(0xFFE12242), fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                ElevatedButton(
                  onPressed: primaryEnabled ? onPrimary : null,
                  style: _primaryStyle().copyWith(minimumSize: MaterialStateProperty.all(const Size(220, 56))),
                  child: Text(primaryLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
    );
  }

  ButtonStyle _outlineStyle() {
    return OutlinedButton.styleFrom(
      minimumSize: const Size(0, 50),
      side: const BorderSide(color: Color(0xFFE12242), width: 1.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
    );
  }

  ButtonStyle _primaryStyle() {
    return ElevatedButton.styleFrom(
      minimumSize: const Size(0, 50),
      backgroundColor: const Color(0xFFE12242),
      disabledBackgroundColor: const Color(0xFFD0D0D2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
    );
  }
}
