import 'dart:typed_data';
import 'dart:ui';
import '../../../core/app_export.dart';

class ResultsHeaderWidget extends StatelessWidget {
  final Uint8List? imageBytes;
  final String? imagePath;
  final VoidCallback onBack;
  final bool isTabletLandscape;

  const ResultsHeaderWidget({
    super.key,
    this.imageBytes,
    this.imagePath,
    required this.onBack,
    this.isTabletLandscape = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isTabletLandscape) {
      return _buildTabletVersion(context);
    }
    return _buildPhoneVersion(context);
  }

  Widget _buildPhoneVersion(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AppBar row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              _buildBackButton(context),
              const Spacer(),
              _buildLogoChip(),
              const Spacer(),
              const SizedBox(width: 40),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Product image
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: _buildProductImage(height: 220),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletVersion(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              _buildBackButton(context),
              const SizedBox(width: 12),
              _buildLogoChip(),
            ],
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: _buildProductImage(height: double.infinity),
          ),
        ),
      ],
    );
  }

  Widget _buildProductImage({required double height}) {
    if (imageBytes != null) {
      return Hero(
        tag: 'product-scan-image',
        child: Image.memory(
          imageBytes!,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    // Fallback placeholder
    return Container(
      height: height == double.infinity ? 300 : height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1A1A35), const Color(0xFF0D0D20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_rounded,
            size: 56,
            color: Colors.white.withAlpha(51),
          ),
          const SizedBox(height: 12),
          Text(
            'Product Image',
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: Colors.white.withAlpha(77),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: onBack,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withAlpha(38)),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoChip() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(20),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withAlpha(31)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D4FF), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Icon(
                  Icons.document_scanner_rounded,
                  color: Colors.white,
                  size: 11,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'SnapPrice',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
