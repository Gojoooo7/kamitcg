import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Modale plein écran pour zoomer sur une illustration.
/// Pinch & pan via [InteractiveViewer]. Tap hors image ou bouton X pour fermer.
class ImageZoomDialog extends StatelessWidget {
  const ImageZoomDialog({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.heroTag,
    super.key,
  });

  final String imageUrl;
  final String title;
  final String subtitle;
  final Object heroTag;

  static Future<void> show(
    BuildContext context, {
    required String imageUrl,
    required String title,
    required String subtitle,
    required Object heroTag,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, _, _) => ImageZoomDialog(
          imageUrl: imageUrl,
          title: title,
          subtitle: subtitle,
          heroTag: heroTag,
        ),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: SafeArea(
          child: Stack(
            children: [
              // Image centrée + InteractiveViewer
              Center(
                child: GestureDetector(
                  // Capture les taps sur l'image pour ne pas remonter au parent
                  onTap: () {},
                  child: Hero(
                    tag: heroTag,
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4.0,
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (_, _) => const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppColors.gold),
                          ),
                        ),
                        errorWidget: (_, _, _) => const Icon(
                          Icons.broken_image_rounded,
                          size: 64,
                          color: AppColors.text2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Top bar : titre + close
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.inter(
                              size: 15,
                              weight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.inter(
                              size: 12,
                              color: const Color(0xCCFFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: const Color(0x66000000),
                      shape: const CircleBorder(
                        side: BorderSide(color: AppColors.line2),
                      ),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(context).pop(),
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Hint en bas
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x66000000),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.line2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.zoom_out_map_rounded,
                          size: 14,
                          color: Color(0xCCFFFFFF),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          Strings.scannerZoomHint,
                          style: AppTypography.inter(
                            size: 11,
                            color: const Color(0xCCFFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
