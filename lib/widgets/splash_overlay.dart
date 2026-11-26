import 'package:flutter/material.dart';

/// Animated Islamic Emerald & Gold splash overlay shared across Mobile & Desktop.
class SplashOverlay extends StatefulWidget {
  final VoidCallback onFinished;

  const SplashOverlay({super.key, required this.onFinished});

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 1700), () {
      if (!mounted) return;
      setState(() => _exiting = true);
      Future.delayed(const Duration(milliseconds: 420), () {
        if (mounted) widget.onFinished();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 700;
    final logoSize = isDesktop ? 132.0 : 108.0;

    return AnimatedOpacity(
      opacity: _exiting ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.2),
              radius: 1.15,
              colors: [
                Color(0xFF047857),
                Color(0xFF064E3B),
                Color(0xFF022C22),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: _scaleAnim,
                        child: Container(
                          width: logoSize + 18,
                          height: logoSize + 18,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.75),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.28),
                                blurRadius: 32,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/icons/app_logo.png',
                              width: logoSize,
                              height: logoSize,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: Column(
                          children: [
                            const Text(
                              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontFamily: 'ScheherazadeNew',
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFCD34D),
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Zikr Companion',
                              style: TextStyle(
                                fontFamily: 'HindSiliguri',
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'প্রতিদিনের জিকির, তাসবিহ ও আমলের সঙ্গী',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'HindSiliguri',
                                fontSize: 15,
                                color: Colors.white.withValues(alpha: 0.78),
                              ),
                            ),
                            const SizedBox(height: 34),
                            SizedBox(
                              width: 140,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  minHeight: 3.5,
                                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFFF59E0B),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
