import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_decor.dart';
import 'care_page.dart';

class CareSummary extends StatelessWidget {
  final IconData icon;
  final String title, description;
  final Widget? footer;
  const CareSummary({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.footer,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: AppDecor.buttonGradient,
      borderRadius: BorderRadius.circular(26),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppDecor.t(
                      18,
                      w: FontWeight.w700,
                      c: Colors.white,
                      h: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: AppDecor.t(
                      12,
                      c: Colors.white.withValues(alpha: .9),
                      h: 1.65,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (footer != null) ...[const SizedBox(height: 18), footer!],
      ],
    ),
  );
}

class CareSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const CareSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 26),
      Text(
        title,
        style: AppDecor.t(17, w: FontWeight.w700, c: AppColors.primaryDeep),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 6),
        Text(subtitle!, style: AppDecor.t(12, c: AppColors.textMuted, h: 1.6)),
      ],
      const SizedBox(height: 14),
      child,
    ],
  );
}

class CareNotice extends StatelessWidget {
  final String text;
  final bool error;
  const CareNotice(this.text, {super.key, this.error = false});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: error ? const Color(0xFFFFF0F0) : AppColors.primaryLighter,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          error ? Icons.info_outline : Icons.shield_outlined,
          size: 20,
          color: error ? AppColors.required : AppColors.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppDecor.t(
              12,
              c: error ? AppColors.required : AppColors.textMuted,
              h: 1.65,
            ),
          ),
        ),
      ],
    ),
  );
}

class CareAction extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool busy;
  const CareAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.busy = false,
  });
  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: busy ? null : onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      minimumSize: const Size(0, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    icon: busy
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icon, size: 20),
    label: Text(
      label,
      textAlign: TextAlign.center,
      style: AppDecor.t(13, w: FontWeight.w600, c: Colors.white),
    ),
  );
}

class CareDetail extends StatelessWidget {
  final IconData icon;
  final String title, detail;
  final Widget? action;
  const CareDetail({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    this.action,
  });
  @override
  Widget build(BuildContext context) => CareCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.primaryLighter,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: AppColors.primary, size: 23),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppDecor.t(14, w: FontWeight.w600, h: 1.4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    detail,
                    style: AppDecor.t(12, c: AppColors.textMuted, h: 1.65),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    ),
  );
}
