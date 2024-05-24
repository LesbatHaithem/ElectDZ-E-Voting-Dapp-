import 'package:flutter/material.dart';

import '../constants/colors.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const CustomButton({
    required this.label,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: primaryBlack,
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),
            CircleAvatar(
              radius: 28,
              backgroundColor: accentColor,
              child: Center(
                child: Icon(
                  Icons.arrow_circle_right,
                  color: buttonColor,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
