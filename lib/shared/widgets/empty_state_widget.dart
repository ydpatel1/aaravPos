import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message));
  }
}
