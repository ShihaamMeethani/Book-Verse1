import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import '../onboarding/onboarding_screen.dart';
import '../auth/login_screen.dart';
import '../main_nav/main_navigation_screen.dart';
import '../admin/admin_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final seenOnboarding = prefs.getBool(AppConstants.prefOnboardingSeen) ?? false;

    var attempts = 0;
    while (authProvider.status == AuthStatus.unknown && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (!mounted) return;

    Widget next;
    if (!seenOnboarding) {
      next = const OnboardingScreen();
    } else if (authProvider.status == AuthStatus.authenticated) {
      next = authProvider.isAdmin
          ? const AdminNavigationScreen()
          : const MainNavigationScreen();
    } else {
      next = const LoginScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, __) => FadeTransition(opacity: animation, child: next),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ZoomIn(
              duration: const Duration(milliseconds: 800),
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.auto_stories_rounded, size: 48, color: Colors.white),
              ),
            ),
            const SizedBox(height: 28),
            FadeInUp(
              delay: const Duration(milliseconds: 350),
              child: Text(
                AppConstants.appName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.8,
                ),
              ),
            ),
            const SizedBox(height: 8),
            FadeInUp(
              delay: const Duration(milliseconds: 550),
              child: Text(
                'Your literary universe. Every story, boundless.',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(height: 50),
            FadeIn(
              delay: const Duration(milliseconds: 750),
              child: const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
