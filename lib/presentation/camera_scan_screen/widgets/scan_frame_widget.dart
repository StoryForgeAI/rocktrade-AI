import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScanFrameWidget extends StatelessWidget {
  final AnimationController pulseController;

  const ScanFrameWidget({super.key, required this.pulseController});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final frameSize = (screenWidth * 0.72).clamp(220.0, 340.0);

    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        final glowOpacity = (0.4 + pulseController.value * 0.5).clamp(0.0, 1.0);
        final cornerColor = Color.lerp(
          const Color(0xFF00D4FF),
          const Color(0xFF7C3AED),
          pulseController.value,
        )!;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: frameSize,
              height: frameSize,
              child: Stack(
                children: [
                  // Outer glow
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: cornerColor.withOpacity(glowOpacity * 0.3),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Dim overlay inside frame
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: cornerColor.withAlpha(102),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  // Corner brackets
                  ..._buildCorners(cornerColor, frameSize),
                  // Scanning beam
                  _buildScanBeam(frameSize, cornerColor),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(128),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withAlpha(31)),
              ),
              child: Text(
                'Point at any product to scan',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withAlpha(204),
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildCorners(Color color, double frameSize) {
    const cornerLength = 28.0;
    const cornerThickness = 3.0;
    const cornerRadius = 6.0;

    Widget corner({required bool top, required bool left}) {
      return Positioned(
        top: top ? 0 : null,
        bottom: top ? null : 0,
        left: left ? 0 : null,
        right: left ? null : 0,
        child: SizedBox(
          width: cornerLength + cornerThickness,
          height: cornerLength + cornerThickness,
          child: CustomPaint(
            painter: _CornerPainter(
              color: color,
              top: top,
              left: left,
              thickness: cornerThickness,
              length: cornerLength,
              radius: cornerRadius,
            ),
          ),
        ),
      );
    }

    return [
      corner(top: true, left: true),
      corner(top: true, left: false),
      corner(top: false, left: true),
      corner(top: false, left: false),
    ];
  }

  Widget _buildScanBeam(double frameSize, Color color) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, _) {
        final beamY = pulseController.value * (frameSize - 4);
        return Positioned(
          top: beamY,
          left: 12,
          right: 12,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  color.withAlpha(204),
                  color,
                  color.withAlpha(204),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(153),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final bool top;
  final bool left;
  final double thickness;
  final double length;
  final double radius;

  _CornerPainter({
    required this.color,
    required this.top,
    required this.left,
    required this.thickness,
    required this.length,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final x = left ? thickness / 2 : size.width - thickness / 2;
    final y = top ? thickness / 2 : size.height - thickness / 2;
    final xDir = left ? 1.0 : -1.0;
    final yDir = top ? 1.0 : -1.0;

    // Horizontal arm
    path.moveTo(x + xDir * radius, y);
    path.lineTo(x + xDir * length, y);

    // Vertical arm
    path.moveTo(x, y + yDir * radius);
    path.lineTo(x, y + yDir * length);

    // Corner arc
    final arcRect = Rect.fromCenter(
      center: Offset(x + xDir * radius, y + yDir * radius),
      width: radius * 2,
      height: radius * 2,
    );
    final startAngle = top
        ? (left ? 3.14159 : 0.0)
        : (left ? 3.14159 / 2 : 3.14159 * 1.5);
    final sweepAngle = 3.14159 / 2;
    path.addArc(arcRect, startAngle, left == top ? sweepAngle : -sweepAngle);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) =>
      oldDelegate.color != color;
}
