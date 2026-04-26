import 'package:aaravpos/core/theme/app_styles.dart';
import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    this.label,
    this.controller,
    this.hint,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.prefix,
    this.suffix,
    super.key,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final Widget? prefix;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(8));
    const borderSide = BorderSide(color: Colors.black, width: 2);
    const border = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: borderSide,
    );

    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: AppStyles.fieldLabel,
        prefixIcon: prefix,
        suffixIcon: suffix,
        border: border,
        isDense: true,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: borderSide.copyWith(color: Colors.red),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: borderSide.copyWith(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: borderSide.copyWith(color: Colors.red),
        ),
      ),
    );
  }
}
