import 'package:flutter/material.dart';
import 'dart:ui';

class MaintenancePage extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const MaintenancePage({
    super.key,
    this.title = 'Sedang Istirahat Untuk Tumbuh',
    this.message =
        'InvestCow sedang dalam pemeliharaan rutin untuk meningkatkan kualitas layanan dan keamanan aset Anda. Kami akan segera kembali!',
    this.onRetry,
  });

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Dynamic Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE0F2F1), Color(0xFFB2DFDB), Color(0xFF80CBC4)],
              ),
            ),
          ),
          
          // Floating Circles for depth
          Positioned(
            top: -50,
            left: -50,
            child: _CircleBlur(color: Colors.cyan[200]!.withOpacity(0.5), size: 200),
          ),
          Positioned(
            bottom: -80,
            right: -30,
            child: _CircleBlur(color: Colors.white.withOpacity(0.3), size: 250),
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Image
                  AnimatedBuilder(
                    animation: _bounceAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -_bounceAnimation.value),
                        child: Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 40,
                                spreadRadius: 5,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/maintenance_illustration.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.white,
                                child: const Icon(Icons.grass, size: 80, color: Colors.cyan),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 48),

                  // Content Card with Glassmorphism
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Text(
                              widget.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00796B),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.message,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // Action Button
                            ElevatedButton(
                              onPressed: widget.onRetry ?? () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF009688),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Coba Hubungkan Kembali',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  const Text(
                    'Update terbaru tersedia di Play Store & App Store',
                    style: TextStyle(color: Color(0xFF004D40), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleBlur extends StatelessWidget {
  final Color color;
  final double size;

  const _CircleBlur({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(1),
            blurRadius: 100,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}
