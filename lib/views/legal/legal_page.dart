import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_decor.dart';
import '../../widgets/care_page.dart';

class LegalSection {
  final String title, body;
  const LegalSection(this.title, this.body);
}

class LegalPage extends StatelessWidget {
  final String title, introduction;
  final IconData icon;
  final List<LegalSection> sections;
  const LegalPage({
    super.key,
    required this.title,
    required this.introduction,
    required this.icon,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) => CarePage(
    title: title,
    subtitle: 'eCARE+ · Mise à jour du 16 octobre 2026',
    child: CareCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 14),
          Text(
            'Version de développement',
            style: AppDecor.t(13, w: FontWeight.w600, c: AppColors.primary),
          ),
          const SizedBox(height: 12),
          SelectableText(
            introduction,
            style: AppDecor.t(14, c: AppColors.textDark, h: 1.8),
          ),
          for (final section in sections) ...[
            const SizedBox(height: 28),
            Semantics(
              header: true,
              child: Text(
                section.title,
                style: AppDecor.t(
                  17,
                  w: FontWeight.w700,
                  c: AppColors.primaryDeep,
                  h: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              section.body,
              style: AppDecor.t(14, c: AppColors.textDark, h: 1.8),
            ),
          ],
        ],
      ),
    ),
  );
}
