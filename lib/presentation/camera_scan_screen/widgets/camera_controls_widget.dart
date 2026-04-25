import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CameraControlsWidget extends StatelessWidget {
  final bool flashOn;
  final VoidCallback onCapture;
  final VoidCallback onGallery;
  final VoidCallback onFlashToggle;

  const CameraControlsWidget({
    super.key,
    required this.flashOn,
    required this.onCapture,
    required this.onGallery,
    required this.onFlashToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 28),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border(
                top: BorderSide(color: Colors.white.withAlpha(31)),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Gallery picker
                    _buildGalleryButton(context),
                    // Capture button
                    _buildCaptureButton(),
                    // Flash toggle
                    _buildFlashButton(),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Tap to capture • Or pick from gallery',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: Colors.white.withAlpha(102),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryButton(BuildContext context) {
    return GestureDetector(
      onTap: onGallery,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(26),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withAlpha(38)),
            ),
            child: const Icon(
              Icons.photo_library_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Gallery',
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: Colors.white.withAlpha(140),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: onCapture,
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF00D4FF), Color(0xFF7C3AED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00D4FF).withAlpha(102),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF00D4FF), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlashButton() {
    return GestureDetector(
      onTap: onFlashToggle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: flashOn
                  ? const Color(0xFF00D4FF).withAlpha(51)
                  : Colors.white.withAlpha(26),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: flashOn
                    ? const Color(0xFF00D4FF).withAlpha(128)
                    : Colors.white.withAlpha(38),
              ),
            ),
            child: Icon(
              flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: flashOn ? const Color(0xFF00D4FF) : Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            flashOn ? 'Flash On' : 'Flash',
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: Colors.white.withAlpha(140),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
