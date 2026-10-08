import 'dart:math';

import 'package:flutter/material.dart';

/// Subtle Islamic eight-pointed-star geometric pattern, drawn procedurally
/// so no image assets are needed in Phase 1.
class IslamicPatternPainter extends CustomPainter {
  IslamicPatternPainter({required this.color, this.opacity = 0.10});

  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const double cell = 56;
    for (double y = -cell; y < size.height + cell; y += cell) {
      for (double x = -cell; x < size.width + cell; x += cell) {
        _drawStar(canvas, paint, Offset(x, y), cell * 0.32);
      }
    }
  }

  void _drawStar(Canvas canvas, Paint paint, Offset center, double r) {
    // Eight-pointed star = two squares rotated 45°.
    for (int k = 0; k < 2; k++) {
      final Path path = Path();
      for (int i = 0; i <= 4; i++) {
        final double angle = (i * pi / 2) + (k * pi / 4) - pi / 4;
        final Offset p = Offset(
          center.dx + r * cos(angle),
          center.dy + r * sin(angle),
        );
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }
    canvas.drawCircle(center, r * 0.18, paint);
  }

  @override
  bool shouldRepaint(covariant IslamicPatternPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.opacity != opacity;
  }
}

/// Decorative header background combining a gradient with the pattern.
class PatternHeader extends StatelessWidget {
  const PatternHeader({
    super.key,
    required this.child,
    this.height = 220,
  });

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0E7C5B),
            const Color(0xFF083F31),
            colors.primary.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: IslamicPatternPainter(color: Colors.white),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
