import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ShoppingLinksWidget extends StatelessWidget {
  final Map<String, dynamic>? result;

  const ShoppingLinksWidget({super.key, this.result});

  @override
  Widget build(BuildContext context) {
    if (result == null) return const SizedBox.shrink();

    final searchLinks = result!['searchLinks'] as Map<String, dynamic>? ?? {};

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
              // Header
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withAlpha(38),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      color: Color(0xFFF59E0B),
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Shop Online',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF59E0B),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Compare prices',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: Colors.white.withAlpha(89),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Platform buttons
              if (searchLinks['googleShopping'] != null)
                _ShoppingPlatformButton(
                  platform: 'Google Shopping',
                  tagline: 'Compare across all stores',
                  url: searchLinks['googleShopping'] as String,
                  primaryColor: const Color(0xFF4285F4),
                  icon: Icons.search_rounded,
                  gradientColors: const [Color(0xFF4285F4), Color(0xFF34A853)],
                ),
              const SizedBox(height: 10),

              if (searchLinks['ebay'] != null)
                _ShoppingPlatformButton(
                  platform: 'eBay',
                  tagline: 'New & used listings',
                  url: searchLinks['ebay'] as String,
                  primaryColor: const Color(0xFFE53238),
                  icon: Icons.storefront_rounded,
                  gradientColors: const [Color(0xFFE53238), Color(0xFFF5AF02)],
                ),
              const SizedBox(height: 10),

              if (searchLinks['amazon'] != null)
                _ShoppingPlatformButton(
                  platform: 'Amazon',
                  tagline: 'Prime shipping available',
                  url: searchLinks['amazon'] as String,
                  primaryColor: const Color(0xFFFF9900),
                  icon: Icons.local_shipping_rounded,
                  gradientColors: const [Color(0xFFFF9900), Color(0xFFFF6B00)],
                ),

              const SizedBox(height: 14),

              // Copy search hint
              GestureDetector(
                onTap: () {
                  final productName = result!['productName'] as String? ?? '';
                  Clipboard.setData(ClipboardData(text: productName));
                  Fluttertoast.showToast(
                    msg: 'Product name copied to clipboard',
                    toastLength: Toast.LENGTH_SHORT,
                    backgroundColor: const Color(0xFF1A1A35),
                    textColor: Colors.white,
                    fontSize: 13,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withAlpha(20)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.content_copy_rounded,
                        size: 14,
                        color: Colors.white.withAlpha(115),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          result!['productName'] as String? ?? 'Product name',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: Colors.white.withAlpha(140),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'Copy',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF00D4FF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShoppingPlatformButton extends StatefulWidget {
  final String platform;
  final String tagline;
  final String url;
  final Color primaryColor;
  final IconData icon;
  final List<Color> gradientColors;

  const _ShoppingPlatformButton({
    required this.platform,
    required this.tagline,
    required this.url,
    required this.primaryColor,
    required this.icon,
    required this.gradientColors,
  });

  @override
  State<_ShoppingPlatformButton> createState() =>
      _ShoppingPlatformButtonState();
}

class _ShoppingPlatformButtonState extends State<_ShoppingPlatformButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl() async {
    setState(() => _isLoading = true);
    try {
      final uri = Uri.parse(widget.url);
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Fluttertoast.showToast(
          msg: 'Could not open ${widget.platform}',
          backgroundColor: const Color(0xFF1A1A35),
          textColor: Colors.white,
          fontSize: 13,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Could not open ${widget.platform}',
        backgroundColor: const Color(0xFF1A1A35),
        textColor: Colors.white,
        fontSize: 13,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        _launchUrl();
      },
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.gradientColors[0].withAlpha(46),
                widget.gradientColors[1].withAlpha(26),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.primaryColor.withAlpha(77)),
          ),
          child: Row(
            children: [
              // Platform icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(9),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(widget.icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 14),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.platform,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      widget.tagline,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: Colors.white.withAlpha(115),
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: widget.primaryColor.withAlpha(179),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
