import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ConfidenceLevel { high, medium, low }

class StatusBadgeWidget extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final double fontSize;

  const StatusBadgeWidget({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    this.fontSize = 11,
  });

  factory StatusBadgeWidget.confidence(ConfidenceLevel level) {
    switch (level) {
      case ConfidenceLevel.high:
        return StatusBadgeWidget(
          label: '● High Confidence',
          backgroundColor: const Color(0x2639FF14),
          textColor: const Color(0xFF39FF14),
          borderColor: const Color(0x4D39FF14),
        );
      case ConfidenceLevel.medium:
        return StatusBadgeWidget(
          label: '● Medium Confidence',
          backgroundColor: const Color(0x26F59E0B),
          textColor: const Color(0xFFF59E0B),
          borderColor: const Color(0x4DF59E0B),
        );
      case ConfidenceLevel.low:
        return StatusBadgeWidget(
          label: '● Low Confidence',
          backgroundColor: const Color(0x26EF4444),
          textColor: const Color(0xFFEF4444),
          borderColor: const Color(0x4DEF4444),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1)
            : null,
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
