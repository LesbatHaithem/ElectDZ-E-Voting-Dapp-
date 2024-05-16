import 'dart:ui';
import 'package:flutter/material.dart';


Widget glassmorphicContainer({
  required BuildContext context,
  BoxDecoration? decoration,
  required Widget child,
  double? height,
  double? width,
}) {
  return Padding(
    padding: const EdgeInsets.all(10.0),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          decoration: decoration ?? BoxDecoration(
            boxShadow: [
              BoxShadow(
                blurRadius: 50,
                spreadRadius: 5,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              )
            ],
          ),
          height: height,
          width: width,
          child: Center(child: child),
        ),
      ),
    ),
  );
}


