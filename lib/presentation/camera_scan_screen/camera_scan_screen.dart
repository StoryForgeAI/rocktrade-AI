import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import './widgets/analyzing_overlay_widget.dart';
import './widgets/camera_controls_widget.dart';
import './widgets/camera_preview_widget.dart';
import './widgets/scan_frame_widget.dart';

// TODO: Replace with Riverpod/Bloc for production
class CameraScanScreen extends StatefulWidget {
  const CameraScanScreen({super.key});

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen>
    with TickerProviderStateMixin {
  // ── State ─────────────────────────────────────────────────────
  bool _isAnalyzing = false;
  bool _cameraPermissionGranted = false;
  bool _flashOn = false;
  Uint8List? _capturedImageBytes;
  String? _capturedImagePath;

  final ImagePicker _picker = ImagePicker();

  // ── Animation Controllers ─────────────────────────────────────
  late AnimationController _scanPulseController;
  late AnimationController _headerFadeController;
  late Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _scanPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _headerFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerFade = CurvedAnimation(
      parent: _headerFadeController,
      curve: Curves.easeOutCubic,
    );
    _headerFadeController.forward();

    _checkCameraPermission();
  }

  @override
  void dispose() {
    _scanPulseController.dispose();
    _headerFadeController.dispose();
    super.dispose();
  }

  // ── Permission ────────────────────────────────────────────────
  Future<void> _checkCameraPermission() async {
    if (kIsWeb) {
      setState(() => _cameraPermissionGranted = true);
      return;
    }
    final status = await Permission.camera.status;
    if (status.isGranted) {
      setState(() => _cameraPermissionGranted = true);
    } else {
      final result = await Permission.camera.request();
      setState(() => _cameraPermissionGranted = result.isGranted);
    }
  }

  // ── Image Capture ─────────────────────────────────────────────
  Future<void> _captureFromCamera() async {
    if (_isAnalyzing) return;
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (photo != null) {
        await _processImage(photo);
      }
    } catch (e) {
      _showErrorSnack('Could not access camera. Please check permissions.');
    }
  }

  Future<void> _captureFromGallery() async {
    if (_isAnalyzing) return;
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (photo != null) {
        await _processImage(photo);
      }
    } catch (e) {
      _showErrorSnack('Could not open gallery. Please check permissions.');
    }
  }

  Future<void> _processImage(XFile photo) async {
    // Read image bytes (works on both web and mobile)
    final bytes = await photo.readAsBytes();
    setState(() {
      _capturedImageBytes = bytes;
      _capturedImagePath = kIsWeb ? null : photo.path;
      _isAnalyzing = true;
    });

    // TODO: Replace with actual Supabase upload + Edge Function call
    // Upload to Supabase Storage, then call Edge Function
    await _callSupabaseEdgeFunction(bytes, photo.name);
  }

  // ── Supabase + OpenAI Integration ─────────────────────────────
  // TODO: Replace with Riverpod/Bloc for production
  Future<void> _callSupabaseEdgeFunction(
    Uint8List imageBytes,
    String fileName,
  ) async {
    // TODO: Initialize Supabase client in main.dart:
    // await Supabase.initialize(url: 'YOUR_SUPABASE_URL', anonKey: 'YOUR_SUPABASE_ANON_KEY');
    //
    // SUPABASE EDGE FUNCTION (deploy at supabase/functions/analyze-product/index.ts):
    // ─────────────────────────────────────────────────────────────────────────────
    // import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
    // import OpenAI from "https://deno.land/x/openai@v4.24.0/mod.ts";
    //
    // const client = new OpenAI({ apiKey: Deno.env.get('OPENAI_API_KEY')! });
    //
    // serve(async (req) => {
    //   const { imageBase64, fileName } = await req.json();
    //   const response = await client.chat.completions.create({
    //     model: "gpt-4o-mini",
    //     response_format: { type: "json_object" },
    //     messages: [{
    //       role: "system",
    //       content: `You are a product identification and pricing expert.
    //         Analyze the image and return ONLY valid JSON in this exact schema:
    //         {
    //           "productName": "Full descriptive product name",
    //           "brand": "Brand name or 'Unknown'",
    //           "model": "Model number/name or 'N/A'",
    //           "category": "Product category (e.g. Electronics, Clothing, Furniture)",
    //           "condition": "New | Used - Like New | Used - Good | Used - Fair",
    //           "estimatedPriceRange": { "low": 0, "high": 0, "currency": "USD" },
    //           "confidence": "high | medium | low",
    //           "description": "One sentence description",
    //           "searchLinks": {
    //             "googleShopping": "https://www.google.com/search?tbm=shop&q=URL_ENCODED_QUERY",
    //             "ebay": "https://www.ebay.com/sch/i.html?_nkw=URL_ENCODED_QUERY",
    //             "amazon": "https://www.amazon.com/s?k=URL_ENCODED_QUERY"
    //           }
    //         }
    //         Rules: Use realistic market prices. If unidentifiable, set confidence to "low"
    //         and productName to "Unidentified Item". Always generate search links.`
    //     }, {
    //       role: "user",
    //       content: [{
    //         type: "image_url",
    //         image_url: { url: `data:image/jpeg;base64,${imageBase64}`, detail: "high" }
    //       }, {
    //         type: "text",
    //         text: "Identify this product and provide pricing information."
    //       }]
    //     }],
    //     max_tokens: 600
    //   });
    //   const result = JSON.parse(response.choices[0].message.content!);
    //   return new Response(JSON.stringify(result), {
    //     headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" }
    //   });
    // });
    //
    // FLUTTER INTEGRATION (replace mock below with this):
    // final supabase = Supabase.instance.client;
    // final base64Image = base64Encode(imageBytes);
    // final response = await supabase.functions.invoke('analyze-product',
    //   body: {'imageBase64': base64Image, 'fileName': fileName});
    // final data = response.data as Map<String, dynamic>;
    // Navigate with real data

    // ── MOCK RESPONSE (remove when Edge Function is live) ────────
    // Simulates network latency — replace with actual API call above
    await Future.delayed(const Duration(milliseconds: 2200));

    // Mock result matching the OpenAI JSON schema above
    final mockResult = {
      'productName': 'Sony WH-1000XM5 Wireless Noise-Canceling Headphones',
      'brand': 'Sony',
      'model': 'WH-1000XM5',
      'category': 'Electronics',
      'condition': 'New',
      'estimatedPriceRange': {'low': 279, 'high': 399, 'currency': 'USD'},
      'confidence': 'high',
      'description':
          'Premium over-ear wireless headphones with industry-leading noise cancellation and 30-hour battery life.',
      'searchLinks': {
        'googleShopping':
            'https://www.google.com/search?tbm=shop&q=Sony+WH-1000XM5+Wireless+Headphones',
        'ebay':
            'https://www.ebay.com/sch/i.html?_nkw=Sony+WH-1000XM5+Wireless+Headphones',
        'amazon':
            'https://www.amazon.com/s?k=Sony+WH-1000XM5+Wireless+Headphones',
      },
    };

    if (!mounted) return;

    setState(() => _isAnalyzing = false);

    Navigator.pushNamed(
      context,
      AppRoutes.resultsScreen,
      arguments: {
        'result': mockResult,
        'imageBytes': _capturedImageBytes,
        'imagePath': _capturedImagePath,
      },
    );
  }

  void _showErrorSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.manrope(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1A35),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _toggleFlash() {
    setState(() => _flashOn = !_flashOn);
    // TODO: Wire to camera package flash control when using camera package
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A1A),
        extendBodyBehindAppBar: true,
        body: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
      ),
    );
  }

  Widget _buildPhoneLayout() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Background / Camera Preview ───────────────────────
        CameraPreviewWidget(
          imageBytes: _capturedImageBytes,
          cameraPermissionGranted: _cameraPermissionGranted,
        ),

        // ── Gradient Vignette ─────────────────────────────────
        _buildGradientOverlay(),

        // ── Scan Frame ────────────────────────────────────────
        if (!_isAnalyzing && _capturedImageBytes == null)
          Center(child: ScanFrameWidget(pulseController: _scanPulseController)),

        // ── Header ────────────────────────────────────────────
        FadeTransition(opacity: _headerFade, child: _buildHeader()),

        // ── Controls ──────────────────────────────────────────
        if (!_isAnalyzing)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CameraControlsWidget(
              flashOn: _flashOn,
              onCapture: _captureFromCamera,
              onGallery: _captureFromGallery,
              onFlashToggle: _toggleFlash,
            ),
          ),

        // ── Analyzing Overlay ─────────────────────────────────
        if (_isAnalyzing)
          AnalyzingOverlayWidget(imageBytes: _capturedImageBytes),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return SafeArea(
      child: Stack(
        children: [
          // Subtle background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.4,
                colors: [Color(0xFF0D0D2B), Color(0xFF0A0A1A)],
              ),
            ),
          ),
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Camera preview card
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: SizedBox(
                              height: 380,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CameraPreviewWidget(
                                    imageBytes: _capturedImageBytes,
                                    cameraPermissionGranted:
                                        _cameraPermissionGranted,
                                  ),
                                  if (!_isAnalyzing &&
                                      _capturedImageBytes == null)
                                    Center(
                                      child: ScanFrameWidget(
                                        pulseController: _scanPulseController,
                                      ),
                                    ),
                                  if (_isAnalyzing)
                                    AnalyzingOverlayWidget(
                                      imageBytes: _capturedImageBytes,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (!_isAnalyzing)
                            CameraControlsWidget(
                              flashOn: _flashOn,
                              onCapture: _captureFromCamera,
                              onGallery: _captureFromGallery,
                              onFlashToggle: _toggleFlash,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.25, 0.65, 1.0],
              colors: [
                Color(0xCC0A0A1A),
                Color(0x330A0A1A),
                Color(0x550A0A1A),
                Color(0xFF0A0A1A),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00D4FF), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.document_scanner_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'SnapPrice',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            // History button
            _GlassIconButton(
              icon: Icons.history_rounded,
              onTap: () {
                // TODO: Navigate to scan history screen
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small glass icon button helper ────────────────────────────
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(31),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(38)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
