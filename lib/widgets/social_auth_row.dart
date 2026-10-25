import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

/// Séparateur "ou continuer avec" + deux boutons Google / Facebook.
class SocialAuthRow extends StatelessWidget {
  final String title;
  final VoidCallback? onGoogle;
  final VoidCallback? onFacebook;

  const SocialAuthRow({
    super.key,
    this.title = 'ou continuer avec',
    this.onGoogle,
    this.onFacebook,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                title,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textHint,
                  fontSize: 13,
                ),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.border)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _Pill(
                label: 'Google',
                icon: Icons.g_mobiledata_rounded,
                iconSize: 32,
                color: const Color(0xFFDB4437),
                onTap: onGoogle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Pill(
                label: 'Facebook',
                icon: Icons.facebook_rounded,
                iconSize: 24,
                color: AppColors.facebookBlue,
                onTap: onFacebook,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;
  final double iconSize;
  final Color color;
  final VoidCallback? onTap;

  const _Pill({
    required this.label,
    required this.icon,
    required this.iconSize,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1.4),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap ?? () {},
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: iconSize),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
