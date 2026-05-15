import 'package:flutter/material.dart';

/// Nền ảnh dùng chung cho Home, Courses, ...
class AppScreenBackground extends StatelessWidget {
  const AppScreenBackground({super.key});

  static const String assetPath = 'assets/images/bg.jpg';

  static const BoxDecoration decoration = BoxDecoration(
    image: DecorationImage(
      image: AssetImage(assetPath),
      fit: BoxFit.cover,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: decoration,
      child: SizedBox.expand(),
    );
  }
}
