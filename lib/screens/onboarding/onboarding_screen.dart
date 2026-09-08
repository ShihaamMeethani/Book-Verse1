import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../auth/login_screen.dart';

class _OnboardData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  _OnboardData(this.icon, this.title, this.subtitle, this.color);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  final List<_OnboardData> _pages = [
    _OnboardData(
      Icons.travel_explore_rounded,
      'Discover Your Next Favorite Read',
      'Browse thousands of curated titles across every genre, award winners, and global bestsellers.',
      AppColors.primary,
    ),
    _OnboardData(
      Icons.local_shipping_rounded,
      'Fast, Trackable Book Delivery',
      'Order with total confidence and track your packaged books in real-time right to your doorstep.',
      AppColors.plum,
    ),
    _OnboardData(
      Icons.workspace_premium_rounded,
      'Exclusive Rewards & Community',
      'Earn VIP loyalty points on every purchase, unlock reader discounts, and share verified reviews.',
      AppColors.coral,
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefOnboardingSeen, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: const LoginScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: dark ? AppColors.ink : AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Skip',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                physics: const BouncingScrollPhysics(),
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FadeInDown(
                          duration: const Duration(milliseconds: 500),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 170,
                                height: 170,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: page.color.withValues(alpha: 0.12),
                                ),
                              ),
                              Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: page.color,
                                ),
                                child: Icon(page.icon, size: 58, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 44),
                        FadeInUp(
                          duration: const Duration(milliseconds: 450),
                          child: Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        FadeInUp(
                          delay: const Duration(milliseconds: 150),
                          child: Text(
                            page.subtitle,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 14.5,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SmoothPageIndicator(
              controller: _controller,
              count: _pages.length,
              effect: ExpandingDotsEffect(
                activeDotColor: AppColors.primary,
                dotColor: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
                dotHeight: 8,
                dotWidth: 8,
                expansionFactor: 3.5,
                spacing: 6,
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: CustomButton(
                label: _index == _pages.length - 1 ? 'Start reading' : 'Next',
                icon: _index == _pages.length - 1 ? Icons.auto_stories_rounded : Icons.arrow_forward_rounded,
                onPressed: () {
                  if (_index == _pages.length - 1) {
                    _finish();
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOut,
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
