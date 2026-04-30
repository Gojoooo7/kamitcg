import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 140),
      physics: const BouncingScrollPhysics(),
      children: [
        Text(
          title,
          style: AppTypography.inter(
            size: 26,
            weight: FontWeight.w700,
            color: AppColors.text0,
            letterSpacing: -0.025,
          ),
        ),
        const SizedBox(height: 60),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppTypography.inter(size: 13, color: AppColors.text2),
        ),
      ],
    );
  }
}
