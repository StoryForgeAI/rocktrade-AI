import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PriceEstimateCardWidget extends StatefulWidget {
  final Map<String, dynamic>? result;

  const PriceEstimateCardWidget({super.key, this.result});

  @override
  State<PriceEstimateCardWidget> createState() =>
      _PriceEstimateCardWidgetState();
}

class _PriceEstimateCardWidgetState extends State<PriceEstimateCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _barController;
  late Animation<double> _barAnim;

  @override
  void initState() {
    super.initState();
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _barAnim = CurvedAnimation(
      parent: _barController,
      curve: Curves.easeOutCubic,
    );
    // Delay bar fill slightly for visual polish
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _barController.forward();
    });
  }

  @override
  void dispose() {
    _barController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.result == null) return const SizedBox.shrink();

    final priceRange =
        widget.result!['estimatedPriceRange'] as Map<String, dynamic>?;
    if (priceRange == null) return const SizedBox.shrink();

    final low = (priceRange['low'] as num?)?.toDouble() ?? 0;
    final high = (priceRange['high'] as num?)?.toDouble() ?? 0;
    final currency = priceRange['currency'] as String? ?? 'USD';
    final midpoint = (low + high) / 2;

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
                      color: const Color(0xFF39FF14).withAlpha(38),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.price_check_rounded,
                      color: Color(0xFF39FF14),
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Price Estimate',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF39FF14),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const Spacer(),
                  _CurrencyBadge(currency: currency),
                ],
              ),
              const SizedBox(height: 20),

              // Price range display
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Est. Range',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: Colors.white.withAlpha(115),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '\$${low.toStringAsFixed(0)}',
                            style: GoogleFonts.manrope(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF39FF14),
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          Text(
                            ' – ',
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withAlpha(102),
                            ),
                          ),
                          Text(
                            '\$${high.toStringAsFixed(0)}',
                            style: GoogleFonts.manrope(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Midpoint pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF39FF14).withAlpha(38),
                          const Color(0xFF39FF14).withAlpha(13),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF39FF14).withAlpha(64),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Avg',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            color: Colors.white.withAlpha(115),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '\$${midpoint.toStringAsFixed(0)}',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF39FF14),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Price range bar
              _PriceRangeBar(
                lowFraction: 0.2,
                highFraction: 0.8,
                barAnimation: _barAnim,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Low',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      color: Colors.white.withAlpha(89),
                      letterSpacing: 0.2,
                    ),
                  ),
                  Text(
                    'Market Range',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      color: Colors.white.withAlpha(89),
                      letterSpacing: 0.2,
                    ),
                  ),
                  Text(
                    'High',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      color: Colors.white.withAlpha(89),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // AI disclaimer
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 12,
                    color: Colors.white.withAlpha(77),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Estimate based on AI training data. Verify on shopping platforms.',
                      style: GoogleFonts.manrope(
                        fontSize: 10.5,
                        color: Colors.white.withAlpha(89),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceRangeBar extends StatelessWidget {
  final double lowFraction;
  final double highFraction;
  final Animation<double> barAnimation;

  const _PriceRangeBar({
    required this.lowFraction,
    required this.highFraction,
    required this.barAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: barAnimation,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final rangeStart = lowFraction * totalWidth;
            final rangeWidth =
                (highFraction - lowFraction) * totalWidth * barAnimation.value;

            return Container(
              height: 8,
              width: totalWidth,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Stack(
                children: [
                  // Active range
                  Positioned(
                    left: rangeStart,
                    child: Container(
                      width: rangeWidth,
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF39FF14), Color(0xFF00D4FF)],
                        ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF39FF14).withAlpha(102),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CurrencyBadge extends StatelessWidget {
  final String currency;

  const _CurrencyBadge({required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withAlpha(31)),
      ),
      child: Text(
        currency,
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white.withAlpha(153),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
