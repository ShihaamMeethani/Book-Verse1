import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

/// Reliable network image for book covers with clean flat presentation
/// and shimmer placeholders.
class BookCoverImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final bool showSpineEffect;

  const BookCoverImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.showSpineEffect = true,
  });

  String get _cleanUrl => url.trim();

  @override
  Widget build(BuildContext context) {
    final imageWidget = _cleanUrl.isEmpty
        ? _fallback(context)
        : Image.network(
            _cleanUrl,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            filterQuality: FilterQuality.medium,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return placeholder ?? _loading(context);
            },
            errorBuilder: (context, error, stack) {
              debugPrint('BookVerse cover failed to load: $_cleanUrl | $error');
              return _fallback(context);
            },
          );

    final content = imageWidget;

    if (borderRadius == null) return content;
    return ClipRRect(borderRadius: borderRadius!, child: content);
  }

  Widget _loading(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: dark ? AppColors.surfaceRaised : const Color(0xFFE2E8F0),
      highlightColor: dark ? AppColors.surfaceStrong : const Color(0xFFF1F5F9),
      child: Container(
        color: dark ? AppColors.surfaceRaised : Colors.white,
        child: const Center(
          child: Icon(Icons.menu_book_rounded, size: 28, color: Colors.white24),
        ),
      ),
    );
  }

  Widget _fallback(BuildContext context) => Container(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceRaised
            : const Color(0xFFEDE2D7),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_stories_rounded, size: 36, color: AppColors.primaryLight),
            const SizedBox(height: 8),
            Text(
              'Cover\nUnavailable',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
}
