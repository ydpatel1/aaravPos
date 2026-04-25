import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class SignaturePad extends StatelessWidget {
  const SignaturePad({required this.controller, super.key});

  final SignatureController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Signature(
        controller: controller,
        backgroundColor: Colors.white,
      ),
    );
  }
}
