import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final bool showValue;
  final Color? starColor;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 15,
    this.showValue = true,
    this.starColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = starColor ?? AppColors.gold;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ...List.generate(5, (i) {
          IconData icon;
          if (rating >= i + 1) {
            icon = Icons.star_rounded;
          } else if (rating > i && rating < i + 1) {
            icon = Icons.star_half_rounded;
          } else {
            icon = Icons.star_border_rounded;
          }
          return Icon(icon, size: size, color: color);
        }),
        if (showValue) ...[
          const SizedBox(width: 5),
          Text(
            rating.toStringAsFixed(1),
            style: GoogleFonts.plusJakartaSans(
              fontSize: size * 0.82,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ],
    );
  }
}

