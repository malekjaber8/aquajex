import 'package:flutter/material.dart';

/// Fond décoratif : dégradé doux + arcs/halos discrets dans les coins.
class DecorativeBackground extends StatelessWidget {
  final Widget child;

  const DecorativeBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3F6FA), Color(0xFFEFF3F7)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Halo doré en haut à gauche.
          Positioned(
            top: -120,
            left: -120,
            child: _Glow(
              size: 340,
              colors: [
                const Color(0xFFC9A24B).withValues(alpha: 0.16),
                const Color(0xFFC9A24B).withValues(alpha: 0.0),
              ],
            ),
          ),
          // Halo bleu/sarcelle en bas à droite.
          Positioned(
            bottom: -140,
            right: -140,
            child: _Glow(
              size: 400,
              colors: [
                const Color(0xFF2CA6A4).withValues(alpha: 0.16),
                const Color(0xFF2CA6A4).withValues(alpha: 0.0),
              ],
            ),
          ),
          CustomPaint(painter: _ArcPainter(), child: const SizedBox.expand()),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _Glow({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintGold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..shader = const LinearGradient(
        colors: [Color(0x552E6C8E), Color(0x00C9A24B)],
      ).createShader(Rect.fromLTWH(0, 0, size.width * 0.5, size.height * 0.5));

    final topLeftPath = Path()
      ..moveTo(-40, size.height * 0.22)
      ..quadraticBezierTo(
        size.width * 0.14,
        size.height * 0.14,
        size.width * 0.30,
        -40,
      );
    canvas.drawPath(topLeftPath, paintGold);

    final paintTeal = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..shader =
          const LinearGradient(colors: [Color(0x552CA6A4), Color(0x001B3B5F)])
              .createShader(
                Rect.fromLTWH(
                  size.width * 0.6,
                  size.height * 0.55,
                  size.width * 0.4,
                  size.height * 0.45,
                ),
              );

    final bottomRightPath = Path()
      ..moveTo(size.width + 40, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.86,
        size.height * 0.84,
        size.width * 0.70,
        size.height + 40,
      );
    canvas.drawPath(bottomRightPath, paintTeal);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) => false;
}
