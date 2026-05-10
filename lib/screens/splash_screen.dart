import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _auraController;
  late AnimationController _particleController;
  late AnimationController _shimmerController;
  
  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _contentOpacity;
  late Animation<double> _progressValue;
  
  final List<AuraPoint> _auraPoints = [
    AuraPoint(color: const Color(0xFF6366F1), offset: const Offset(-0.5, -0.5), speed: 0.2),
    AuraPoint(color: const Color(0xFFD946EF), offset: const Offset(0.5, 0.5), speed: 0.15),
    AuraPoint(color: const Color(0xFFF59E0B), offset: const Offset(-0.3, 0.6), speed: 0.25),
  ];

  final List<Particle> _particles = List.generate(40, (index) => Particle());

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _auraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.5, curve: Curves.elasticOut)),
    );

    _contentOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.4, 0.7, curve: Curves.easeIn)),
    );

    _progressValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.5, 1.0, curve: Curves.easeInOut)),
    );

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _auraController.dispose();
    _particleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF030303),
      body: Stack(
        children: [
          // 1. Dynamic Aura Background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _auraController,
              builder: (context, _) {
                return CustomPaint(
                  painter: AuraPainter(
                    points: _auraPoints,
                    animationValue: _auraController.value,
                  ),
                );
              },
            ),
          ),

          // 2. Blur Overlay for depth
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(color: Colors.black.withOpacity(0.4)),
            ),
          ),

          // 3. Moving Particles
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) {
                return CustomPaint(
                  painter: ParticlePainterV2(
                    particles: _particles,
                    animationValue: _particleController.value,
                  ),
                );
              },
            ),
          ),

          // 4. Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Premium Glassmorphic Logo
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoScale.value,
                      child: Opacity(
                        opacity: _logoOpacity.value,
                        child: child,
                      ),
                    );
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Shimmering Border
                      AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, _) {
                          return Container(
                            width: 144,
                            height: 144,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: const [
                                  Colors.transparent,
                                  Colors.amber,
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                                transform: GradientRotation(_shimmerController.value * 2 * math.pi),
                              ),
                            ),
                          );
                        },
                      ),
                      // Glass Card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(28),
                            child: Hero(
                              tag: 'logo',
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(Icons.grid_4x4_rounded, color: Colors.amber, size: 50),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                // Cinematic Typography
                FadeTransition(
                  opacity: _contentOpacity,
                  child: Column(
                    children: [
                      _buildAnimatedTitle(),
                      const SizedBox(height: 16),
                      _buildSubtitle(),
                    ],
                  ),
                ),

                const SizedBox(height: 100),

                // Advanced Loader
                FadeTransition(
                  opacity: _contentOpacity,
                  child: Container(
                    width: size.width * 0.6,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _progressValue,
                          builder: (context, _) {
                            return CustomPaint(
                              size: const Size(double.infinity, 6),
                              painter: ModernLoaderPainter(
                                progress: _progressValue.value,
                                shimmerValue: _shimmerController.value,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'PREPARING YOUR EXPERIENCE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTitle() {
    const title = 'WORDLE';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(title.length, (index) {
        return AnimatedBuilder(
          animation: _mainController,
          builder: (context, child) {
            final double delay = 0.4 + (index * 0.05);
            final double animValue = Curves.easeOutBack.transform(
              (math.max(0.0, math.min(1.0, (_mainController.value - delay) * 5))),
            );
            
            return Transform.translate(
              offset: Offset(0, 20 * (1 - animValue)),
              child: Opacity(
                opacity: animValue,
                child: Text(
                  title[index],
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.amber, blurRadius: 10),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildSubtitle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1),
      ),
      child: const Text(
        'THE ULTIMATE PUZZLE JOURNEY',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 5,
          color: Colors.amber,
        ),
      ),
    );
  }
}

class AuraPoint {
  final Color color;
  final Offset offset;
  final double speed;
  AuraPoint({required this.color, required this.offset, required this.speed});
}

class AuraPainter extends CustomPainter {
  final List<AuraPoint> points;
  final double animationValue;

  AuraPainter({required this.points, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    for (var point in points) {
      final double angle = animationValue * 2 * math.pi * point.speed;
      final double dx = math.cos(angle) * (size.width * 0.3) + point.offset.dx * size.width;
      final double dy = math.sin(angle) * (size.height * 0.3) + point.offset.dy * size.height;
      
      final paint = Paint()
        ..color = point.color.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
      
      canvas.drawCircle(center + Offset(dx, dy), size.width * 0.8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Particle {
  late double x;
  late double y;
  late double size;
  late double speed;
  late double opacity;
  late double angle;

  Particle() {
    reset();
  }

  void reset() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble();
    size = math.Random().nextDouble() * 3 + 1;
    speed = math.Random().nextDouble() * 0.05 + 0.02;
    opacity = math.Random().nextDouble() * 0.6 + 0.1;
    angle = math.Random().nextDouble() * 2 * math.pi;
  }
}

class ParticlePainterV2 extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  ParticlePainterV2({required this.particles, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final double time = animationValue * 2 * math.pi;
      final double driftX = math.sin(time + particle.angle) * 20;
      final double currentY = (particle.y - (animationValue * particle.speed)) % 1.0;
      
      final paint = Paint()
        ..color = Colors.amber.withOpacity(particle.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
      
      canvas.drawCircle(
        Offset((particle.x * size.width) + driftX, currentY * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ModernLoaderPainter extends CustomPainter {
  final double progress;
  final double shimmerValue;
  ModernLoaderPainter({required this.progress, required this.shimmerValue});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    
    final rRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(10),
    );
    canvas.drawRRect(rRect, bgPaint);

    if (progress > 0) {
      final progressWidth = size.width * progress;
      final progressPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.amber.shade400,
            Colors.amber.shade700,
            Colors.orange.shade800,
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, progressWidth, size.height))
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, progressWidth, size.height),
          const Radius.circular(10),
        ),
        progressPaint,
      );

      // Shimmer effect on the progress
      final shimmerPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.4),
            Colors.white.withOpacity(0.0),
          ],
          stops: [
            (shimmerValue - 0.2).clamp(0.0, 1.0),
            shimmerValue.clamp(0.0, 1.0),
            (shimmerValue + 0.2).clamp(0.0, 1.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, progressWidth, size.height));

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, progressWidth, size.height),
          const Radius.circular(10),
        ),
        shimmerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
