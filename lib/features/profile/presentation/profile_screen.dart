import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/presentation/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(currentUserEmailProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 140),
      physics: const BouncingScrollPhysics(),
      children: [
        Text(
          Strings.profileTitle,
          style: AppTypography.inter(
            size: 26,
            weight: FontWeight.w700,
            color: AppColors.text0,
            letterSpacing: -0.025,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x06FFFFFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF8A2BE2), Color(0xFF5B1AA3)],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initialsOf(email),
                  style: AppTypography.num(
                    size: 16,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Strings.userDisplayName,
                      style: AppTypography.inter(
                        size: 14,
                        weight: FontWeight.w600,
                        color: AppColors.text0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.mono(
                        size: 12,
                        color: AppColors.text2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: TextButton(
            onPressed: () => _confirmSignOut(context, ref),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0x0AFFFFFF),
              foregroundColor: AppColors.down,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.line2),
              ),
            ),
            child: Text(
              Strings.profileSignOut,
              style: AppTypography.inter(
                size: 15,
                weight: FontWeight.w600,
                color: AppColors.down,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final email = ref.read(currentUserEmailProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Text(
          Strings.profileSignOut,
          style: AppTypography.inter(
            size: 18,
            weight: FontWeight.w700,
            color: AppColors.text0,
          ),
        ),
        content: Text(
          email == null ? '' : Strings.profileSignedInAs(email),
          style: AppTypography.inter(size: 14, color: AppColors.text1),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Annuler',
              style: AppTypography.inter(size: 14, color: AppColors.text1),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              Strings.profileSignOut,
              style: AppTypography.inter(
                size: 14,
                weight: FontWeight.w600,
                color: AppColors.down,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(authRepositoryProvider).signOut();
  }

  String _initialsOf(String? email) {
    if (email == null || email.isEmpty) return 'NK';
    return String.fromCharCode(email.runes.first).toUpperCase();
  }
}
