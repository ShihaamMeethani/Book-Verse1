import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

/// Skeleton-loading grid shown while the book catalog streams in.
class BookGridShimmer extends StatelessWidget {
  final int itemCount;
  const BookGridShimmer({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: dark ? AppColors.surfaceRaised : const Color(0xFFE2E8F0),
      highlightColor: dark ? AppColors.surfaceStrong : const Color(0xFFF1F5F9),
      child: GridView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: itemCount,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          mainAxisExtent: 310,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: dark ? AppColors.surface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
            ),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: dark ? AppColors.surfaceRaised : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: 14,
                decoration: BoxDecoration(
                  color: dark ? AppColors.surfaceRaised : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 80,
                height: 11,
                decoration: BoxDecoration(
                  color: dark ? AppColors.surfaceRaised : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 50,
                    height: 14,
                    decoration: BoxDecoration(
                      color: dark ? AppColors.surfaceRaised : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: dark ? AppColors.surfaceRaised : const Color(0xFFE2E8F0),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

