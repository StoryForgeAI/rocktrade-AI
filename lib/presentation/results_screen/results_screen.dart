import 'dart:typed_data';


import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import './widgets/price_estimate_card_widget.dart';
import './widgets/product_identity_card_widget.dart';
import './widgets/results_header_widget.dart';
import './widgets/shopping_links_widget.dart';

// TODO: Replace with Riverpod/Bloc for production
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  // ── Data ──────────────────────────────────────────────────────
  Map<String, dynamic>? _result;
  Uint8List? _imageBytes;
  String? _imagePath;

  // ── Entrance Animations ────────────────────────────────────────
  late AnimationController _entranceController;
  late List<Animation<double>> _itemFades;
  late List<Animation<Offset>> _itemSlides;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Staggered animations for 4 sections: header, identity, price, links
    _itemFades = List.generate(4, (i) {
      final start = i * 0.18;
      final end = (start + 0.45).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _entranceController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _itemSlides = List.generate(4, (i) {
      final start = i * 0.18;
      final end = (start + 0.45).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _entranceController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _result = args['result'] as Map<String, dynamic>?;
      _imageBytes = args['imageBytes'] as Uint8List?;
      _imagePath = args['imagePath'] as String?;
    }
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      extendBodyBehindAppBar: true,
      body: isTablet && isLandscape
          ? _buildTabletLandscape()
          : _buildPhoneLayout(),
    );
  }

  // ── Phone / Tablet Portrait Layout ────────────────────────────
  Widget _buildPhoneLayout() {
    return Stack(
      children: [
        // Background
        _buildBackground(),
        // Scrollable content
        SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildAnimated(
                  index: 0,
                  child: ResultsHeaderWidget(
                    imageBytes: _imageBytes,
                    imagePath: _imagePath,
                    onBack: () => Navigator.pop(context),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 16),
                    _buildAnimated(
                      index: 1,
                      child: ProductIdentityCardWidget(result: _result),
                    ),
                    const SizedBox(height: 14),
                    _buildAnimated(
                      index: 2,
                      child: PriceEstimateCardWidget(result: _result),
                    ),
                    const SizedBox(height: 14),
                    _buildAnimated(
                      index: 3,
                      child: ShoppingLinksWidget(result: _result),
                    ),
                    const SizedBox(height: 8),
                  ]),
                ),
              ),
            ],
          ),
        ),
        // Scan Again FAB
        _buildScanAgainFab(),
      ],
    );
  }

  // ── Tablet Landscape Layout ────────────────────────────────────
  Widget _buildTabletLandscape() {
    return Stack(
      children: [
        _buildBackground(),
        SafeArea(
          child: Row(
            children: [
              // Left column — image
              Expanded(
                flex: 45,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildAnimated(
                    index: 0,
                    child: ResultsHeaderWidget(
                      imageBytes: _imageBytes,
                      imagePath: _imagePath,
                      onBack: () => Navigator.pop(context),
                      isTabletLandscape: true,
                    ),
                  ),
                ),
              ),
              // Right column — cards
              Expanded(
                flex: 55,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(0, 24, 24, 100),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildAnimated(
                        index: 1,
                        child: ProductIdentityCardWidget(result: _result),
                      ),
                      const SizedBox(height: 14),
                      _buildAnimated(
                        index: 2,
                        child: PriceEstimateCardWidget(result: _result),
                      ),
                      const SizedBox(height: 14),
                      _buildAnimated(
                        index: 3,
                        child: ShoppingLinksWidget(result: _result),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildScanAgainFab(),
      ],
    );
  }

  Widget _buildAnimated({required int index, required Widget child}) {
    return FadeTransition(
      opacity: _itemFades[index],
      child: SlideTransition(position: _itemSlides[index], child: child),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D0D2B), Color(0xFF0A0A1A), Color(0xFF12071F)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Top-left cyan glow
            Positioned(
              top: -80,
              left: -60,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00D4FF).withAlpha(31),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Bottom-right purple glow
            Positioned(
              bottom: -60,
              right: -40,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF7C3AED).withAlpha(38),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanAgainFab() {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.cameraScanScreen,
              (route) => false,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00D4FF), Color(0xFF7C3AED)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4FF).withAlpha(89),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add_a_photo_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Scan Another Item',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
