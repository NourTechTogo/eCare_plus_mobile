import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_decor.dart';
import 'page_header.dart';

class CarePage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool showBack;
  const CarePage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = true,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: floatingActionButton,
    floatingActionButtonLocation: floatingActionButtonLocation,
    backgroundColor: AppColors.scaffoldBackground,
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(
                  title: title,
                  subtitle: subtitle,
                  showBack: showBack,
                ),
                const SizedBox(height: 26),
                child,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class CareCard extends StatelessWidget {
  final Widget child;
  const CareCard({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.border.withValues(alpha: .6)),
      boxShadow: AppDecor.shadow(.035),
    ),
    child: child,
  );
}

class CareEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget? action;
  const CareEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.action,
  });
  @override
  Widget build(BuildContext context) => CareCard(
    child: Column(
      children: [
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: AppColors.primaryLighter,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 38),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppDecor.t(17, w: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          textAlign: TextAlign.center,
          style: AppDecor.t(13, c: AppColors.textMuted, h: 1.7),
        ),
        if (action != null) ...[const SizedBox(height: 24), action!],
        const SizedBox(height: 18),
      ],
    ),
  );
}

String careDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
String careTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
