import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Base dark radial gradient (center to edge)
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  AppColors.background,
                  AppColors.backgroundDeep,
                ],
                stops: [0.0, 1.0],
              ),
            ),
          ),
        ),
        // 2. Purple glow in the top-left (approx 8% opacity)
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-1.0, -1.0),
                radius: 1.5,
                colors: [
                  Color(0x148B5CF6),
                  Color(0x00000000),
                ],
                stops: [0.0, 1.0],
              ),
            ),
          ),
        ),
        // 3. Green glow in the bottom-right (approx 5% opacity)
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(1.0, 1.0),
                radius: 1.5,
                colors: [
                  Color(0x0C1DD75B),
                  Color(0x00000000),
                ],
                stops: [0.0, 1.0],
              ),
            ),
          ),
        ),
        // 4. Content
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}
