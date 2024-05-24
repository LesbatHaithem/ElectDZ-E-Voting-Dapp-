import 'package:flutter/material.dart';

import '../constants/colors.dart';

class CustomTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final String? Function(String?)? validate;
  final GlobalKey? formFieldKey;

  const CustomTextFormField({
    required this.hintText,
    this.formFieldKey,
    this.controller,
    this.validate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: formFieldKey,
      controller: controller,
      cursorColor: primaryBlack,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        contentPadding: EdgeInsets.all(20),
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 16,
          color: primaryGrey.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: primaryWhite,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      validator: validate,
    );
  }
}
