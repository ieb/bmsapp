import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Border? border;
  final Widget? icon;
  final String? title;
  final Color? accentColor;
  final bool expandChild;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.border,
    this.icon,
    this.title,
    this.accentColor,
    this.expandChild = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF254646).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: border ?? Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title!.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.grey,
                  ),
                ),
                if (icon != null) icon!,
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (expandChild) Expanded(child: child) else child,
        ],
      ),
    );
  }
}
