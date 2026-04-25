import 'dart:ui';

import 'package:flutter/material.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar({required this.title, this.actions, super.key});

  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    return AppBar(
      title: Text(title),
      centerTitle: true,
      actions: actions,
      backgroundColor: isIos ? Colors.white.withOpacity(0.74) : const Color(0xFFF7F7F8),
      flexibleSpace: isIos
          ? ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: const SizedBox.expand(),
              ),
            )
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
