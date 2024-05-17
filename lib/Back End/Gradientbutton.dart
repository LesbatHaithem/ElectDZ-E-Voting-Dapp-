import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;  // Make onPressed nullable
  final double width;
  final double height;
  final Widget? icon;  // Optional icon
  final TextStyle textStyle;  // Text style if not managed internally
  final EdgeInsets padding;  // Adding padding as a parameter
  final double borderRadius;



  const GradientButton({
    Key? key,
    required this.text,
    this.onPressed,  // It's now nullable
    this.width = double.infinity,
    this.height = 50.0,
    this.icon,  // New parameter for the icon
    this.textStyle = const TextStyle(color: Colors.white, fontSize: 17),  // Default text style
    this.padding = const EdgeInsets.symmetric(vertical: 16, horizontal: 32),  // Default padding
    this.borderRadius = 30.0,

  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.cyanAccent, Colors.white],  // Gradient colors from green to white
        ),
        borderRadius: BorderRadius.circular(30.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 4,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,  // Display the icon if it's not null
                SizedBox(width: 8),  // Spacing between icon and text
              ],
              Text(
                text,
                style: TextStyle(
                  color: Colors.black,  // Ensure text color contrasts well with the button's gradient
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
