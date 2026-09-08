import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_colors.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  IconData _getGenreIcon(String genre) {
    switch (genre.toLowerCase()) {
      case 'all':
        return Icons.auto_awesome_rounded;
      case 'fiction':
        return Icons.auto_stories_rounded;
      case 'non-fiction':
        return Icons.psychology_rounded;
      case 'sci-fi':
      case 'science fiction':
        return Icons.rocket_launch_rounded;
      case 'fantasy':
        return Icons.hotel_class_rounded;
      case 'mystery':
      case 'thriller':
        return Icons.fingerprint_rounded;
      case 'romance':
        return Icons.favorite_rounded;
      case 'business':
      case 'finance':
        return Icons.trending_up_rounded;
      case 'technology':
      case 'tech':
        return Icons.code_rounded;
      case 'self-help':
        return Icons.lightbulb_rounded;
      case 'biography':
      case 'memoir':
        return Icons.person_search_rounded;
      case 'history':
        return Icons.account_balance_rounded;
      default:
        return Icons.bookmark_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : (dark ? AppColors.surfaceRaised : AppColors.paperSurface),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? AppColors.primaryLight
                  : (dark ? AppColors.surfaceBorder : AppColors.paperBorder),
              width: 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getGenreIcon(label),
                size: 15,
                color: selected
                    ? Colors.white
                    : (dark ? AppColors.textSecondary : AppColors.textDarkSecondary),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : (dark ? AppColors.textPrimary : AppColors.textDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

