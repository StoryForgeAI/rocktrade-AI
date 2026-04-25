import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/status_badge_widget.dart';

class ProductIdentityCardWidget extends StatelessWidget {
  final Map<String, dynamic>? result;

  const ProductIdentityCardWidget({super.key, this.result});

  @override
  Widget build(BuildContext context) {
    if (result == null) return const SizedBox.shrink();

    final productName = result!['productName'] as String? ?? 'Unknown Product';
    final brand = result!['brand'] as String? ?? 'Unknown';
    final model = result!['model'] as String? ?? '';
    final category = result!['category'] as String? ?? '';
    final condition = result!['condition'] as String? ?? '';
    final description = result!['description'] as String? ?? '';
    final confidenceStr = result!['confidence'] as String? ?? 'medium';

    ConfidenceLevel confidence;
    switch (confidenceStr.toLowerCase()) {
      case 'high':
        confidence = ConfidenceLevel.high;
        break;
      case 'low':
        confidence = ConfidenceLevel.low;
        break;
      default:
        confidence = ConfidenceLevel.medium;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(31)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section label
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4FF).withAlpha(38),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF00D4FF),
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Product Identity',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF00D4FF),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const Spacer(),
                  StatusBadgeWidget.confidence(confidence),
                ],
              ),
              const SizedBox(height: 16),

              // Product name
              Text(
                productName,
                style: GoogleFonts.manrope(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),

              // Meta chips row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (brand != 'Unknown')
                    _MetaChip(
                      icon: Icons.business_rounded,
                      label: brand,
                      color: const Color(0xFF7C3AED),
                    ),
                  if (model.isNotEmpty && model != 'N/A')
                    _MetaChip(
                      icon: Icons.tag_rounded,
                      label: model,
                      color: const Color(0xFF00D4FF),
                    ),
                  if (category.isNotEmpty)
                    _MetaChip(
                      icon: Icons.category_rounded,
                      label: category,
                      color: const Color(0xFF10B981),
                    ),
                  if (condition.isNotEmpty)
                    _MetaChip(
                      icon: Icons.star_rounded,
                      label: condition,
                      color: const Color(0xFFF59E0B),
                    ),
                ],
              ),

              if (description.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(13),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withAlpha(20)),
                  ),
                  child: Text(
                    description,
                    style: GoogleFonts.manrope(
                      fontSize: 12.5,
                      color: Colors.white.withAlpha(166),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(64)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
