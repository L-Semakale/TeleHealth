import 'dart:math' as math;
import 'package:flutter/material.dart';

const LinearGradient kBrandGradient = LinearGradient(
  colors: [
    Color(0xFFD6246F),
    Color(0xFF8C3B95),
    Color(0xFF5B4AA0),
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

AppBar buildBrandAppBar(String title) {
  return AppBar(
    title: Text(title),
    foregroundColor: Colors.white,
    backgroundColor: Colors.transparent,
    elevation: 0,
    flexibleSpace: Stack(children: [
      Container(decoration: const BoxDecoration(gradient: kBrandGradient)),
      const NoiseOverlay(opacity: 0.07),
    ]),
  );
}

class BrandGradientCard extends StatelessWidget {
  const BrandGradientCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(8),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
      Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: kBrandGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(padding: padding, child: child),
      ),
      ),
      NoiseOverlay(opacity: 0.07, borderRadius: BorderRadius.circular(16)),
      ],
    );
  }
}

/// Paints a subtle grain/noise texture. Drop this on top of any gradient
/// using a [Stack]. [opacity] controls grain visibility (0.0–1.0).
class NoiseOverlay extends StatelessWidget {
  final double opacity;
  final BorderRadius? borderRadius;
  const NoiseOverlay({super.key, this.opacity = 0.06, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    Widget painter = RepaintBoundary(
      child: CustomPaint(
        painter: _NoisePainter(opacity: opacity),
        size: Size.infinite,
      ),
    );
    if (borderRadius != null) {
      painter = ClipRRect(borderRadius: borderRadius!, child: painter);
    }
    return Positioned.fill(child: IgnorePointer(child: painter));
  }
}

class _NoisePainter extends CustomPainter {
  final double opacity;
  _NoisePainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint()..style = PaintingStyle.fill;
    const int grainCount = 1800;
    for (int i = 0; i < grainCount; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final radius = rng.nextDouble() * 0.9 + 0.3;
      final bright = rng.nextBool();
      paint.color = (bright ? Colors.white : Colors.black)
          .withValues(alpha: (rng.nextDouble() * 0.5 + 0.1) * opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_NoisePainter old) => old.opacity != opacity;
}
