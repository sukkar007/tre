import 'package:flutter/material.dart';

class AnimatedProgressBar extends StatelessWidget {
  final Animation<double> animation;
  final Color color;
  final Color backgroundColor;
  final double height;
  final BorderRadius? borderRadius;

  const AnimatedProgressBar({
    super.key,
    required this.animation,
    required this.color,
    required this.backgroundColor,
    this.height = 4.0,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: animation.value,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

