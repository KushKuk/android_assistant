import 'package:flutter/material.dart';

class AssistantOrb extends StatelessWidget {
  const AssistantOrb({super.key, required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.94, end: isActive ? 1 : 0.88),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        width: 184,
        height: 184,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [colors.primaryContainer, colors.primary],
          ),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: .32),
              blurRadius: 38,
              spreadRadius: 8,
            ),
          ],
        ),
        child: Icon(
          Icons.graphic_eq_rounded,
          size: 72,
          color: colors.onPrimary,
        ),
      ),
    );
  }
}
