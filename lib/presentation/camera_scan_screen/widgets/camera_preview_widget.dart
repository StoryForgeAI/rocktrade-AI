import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Conditional web-only imports via stub pattern
import 'camera_preview_web.dart'
    if (dart.library.io) 'camera_preview_stub.dart';

class CameraPreviewWidget extends StatefulWidget {
  final Uint8List? imageBytes;
  final bool cameraPermissionGranted;

  const CameraPreviewWidget({
    super.key,
    this.imageBytes,
    required this.cameraPermissionGranted,
  });

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      registerWebCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    // If we have a captured image, show it
    if (widget.imageBytes != null) {
      return Image.memory(
        widget.imageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    // Web: HtmlElementView for real camera
    if (kIsWeb) {
      return const HtmlElementView(viewType: 'snap-price-camera-view');
    }

    // Mobile: permission check
    if (!widget.cameraPermissionGranted) {
      return _buildPermissionDenied();
    }

    // Mobile: Show a dark placeholder
    return Container(
      color: const Color(0xFF0D0D20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(painter: _GridPainter(), size: Size.infinite),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt_rounded,
                color: Color(0x40FFFFFF),
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'Point at any product',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.white.withAlpha(102),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Container(
      color: const Color(0xFF0A0A1A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.no_photography_rounded,
              color: Color(0xFFEF4444),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Camera access denied',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enable camera access in Settings\nto scan products',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: Colors.white.withAlpha(140),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(10)
      ..strokeWidth = 1;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
