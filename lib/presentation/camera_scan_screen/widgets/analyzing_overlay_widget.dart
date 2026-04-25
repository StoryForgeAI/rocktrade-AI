import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnalyzingOverlayWidget extends StatefulWidget {
  final Uint8List? imageBytes;

  const AnalyzingOverlayWidget({super.key, this.imageBytes});

  @override
  State<AnalyzingOverlayWidget> createState() => _AnalyzingOverlayWidgetState();
}

class _AnalyzingOverlayWidgetState extends State<AnalyzingOverlayWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late AnimationController _textController;

  late Animation<double> _textFade;

  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  final List<String> _statusMessages = [
    'Analyzing image...',
    'Identifying product...',
    'Estimating price...',
    'Generating search links...',
  ];
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _textFade = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    );
    _textController.forward();

    // Generate particles
    for (int i = 0; i < 18; i++) {
      _particles.add(
        _Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextDouble() * 3 + 1.5,
          speed: _random.nextDouble() * 0.3 + 0.1,
          offset: _random.nextDouble(),
        ),
      );
    }

    // Cycle status messages
    _cycleMessages();
  }

  void _cycleMessages() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 750));
      if (!mounted) break;
      await _textController.reverse();
      if (!mounted) break;
      setState(() {
        _messageIndex = (_messageIndex + 1) % _statusMessages.length;
      });
      _textController.forward();
    }
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            color: const Color(0xCC0A0A1A),
            child: Stack(
              children: [
                // Particles
                AnimatedBuilder(
                  animation: _particleController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _ParticlePainter(
                        particles: _particles,
                        progress: _particleController.value,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
                // Center content
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Spinning ring
                      AnimatedBuilder(
                        animation: _rotateController,
                        builder: (context, _) {
                          return AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              final scale = 1.0 + _pulseController.value * 0.06;
                              return Transform.scale(
                                scale: scale,
                                child: SizedBox(
                                  width: 88,
                                  height: 88,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Outer ring
                                      Transform.rotate(
                                        angle:
                                            _rotateController.value *
                                            2 *
                                            math.pi,
                                        child: CustomPaint(
                                          painter: _SpinningRingPainter(
                                            color: const Color(0xFF00D4FF),
                                          ),
                                          size: const Size(88, 88),
                                        ),
                                      ),
                                      // Inner ring (reverse)
                                      Transform.rotate(
                                        angle:
                                            -_rotateController.value *
                                            2 *
                                            math.pi *
                                            0.7,
                                        child: CustomPaint(
                                          painter: _SpinningRingPainter(
                                            color: const Color(0xFF7C3AED),
                                            radius: 32,
                                            arcLength: math.pi * 0.8,
                                          ),
                                          size: const Size(88, 88),
                                        ),
                                      ),
                                      // Center icon
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(
                                                0xFF00D4FF,
                                              ).withAlpha(51),
                                              const Color(
                                                0xFF7C3AED,
                                              ).withAlpha(51),
                                            ],
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withAlpha(38),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.auto_awesome_rounded,
                                          color: Color(0xFF00D4FF),
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      // Status text
                      FadeTransition(
                        opacity: _textFade,
                        child: Text(
                          _statusMessages[_messageIndex],
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Powered by GPT-4o mini',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: Colors.white.withAlpha(102),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Dot progress
                      _buildDotProgress(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDotProgress() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (i) {
            final active = _messageIndex == i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF00D4FF)
                    : Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        );
      },
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double offset;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.offset,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress * p.speed + p.offset) % 1.0;
      final opacity = (math.sin(t * math.pi) * 0.6).clamp(0.0, 1.0);
      final y = p.y * size.height - t * size.height * 0.4;
      final paint = Paint()
        ..color = const Color(0xFF00D4FF).withOpacity(opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x * size.width, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) =>
      old.progress != progress;
}

class _SpinningRingPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double arcLength;

  _SpinningRingPainter({
    required this.color,
    this.radius = 40,
    this.arcLength = math.pi * 1.4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, 0, arcLength, false, paint);

    // Fade tail
    final fadePaint = Paint()
      ..shader = SweepGradient(
        colors: [color.withAlpha(0), color],
        stops: const [0.0, 1.0],
      ).createShader(rect)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawArc(rect, 0, arcLength, false, fadePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
