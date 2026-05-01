// consent_screen.dart
// The consent dialog is now shown inline from ReviewScreen via showDialog().
// This stub exists only to satisfy the router route definition.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ConsentScreen extends StatelessWidget {
  const ConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => context.pop());
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
