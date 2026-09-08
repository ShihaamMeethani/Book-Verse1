import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'About ${AppConstants.appName}',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        physics: const BouncingScrollPhysics(),
        children: [
          // Logo & Branding
          Center(
            child: FadeInDown(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 42),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppConstants.appName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 2.0.0 (Build 2026)',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Mission Card
          FadeInUp(
            delay: const Duration(milliseconds: 100),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: dark ? AppColors.surfaceBorder : AppColors.paperBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Our Mission',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'BookVerse is your premier digital bookstore designed to bring world-class literature, timeless classics, and contemporary bestsellers to your fingertips. Built with passion for readers, authors, and dreamers.',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      height: 1.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Features List
          FadeInUp(
            delay: const Duration(milliseconds: 150),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: dark ? AppColors.surfaceBorder : AppColors.paperBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Key Features',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  _featureRow(Icons.bolt_rounded, 'Instant Delivery & Real-time Tracking'),
                  _featureRow(Icons.workspace_premium_rounded, 'Reader Rewards & Loyalty Points'),
                  _featureRow(Icons.local_offer_rounded, 'Exclusive Promo Codes & Flash Deals'),
                  _featureRow(Icons.verified_user_rounded, 'Encrypted Checkout & Secure Payments'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Legal & Support Card
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: dark ? AppColors.surfaceBorder : AppColors.paperBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Support & Contact',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  _contactRow(Icons.email_outlined, 'Support Email', AppConstants.supportEmail),
                  _contactRow(Icons.language_rounded, 'Website', 'https://bookverse.app'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          Center(
            child: Text(
              '© 2026 BookVerse Inc. All rights reserved.',
              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text('$label: ', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
