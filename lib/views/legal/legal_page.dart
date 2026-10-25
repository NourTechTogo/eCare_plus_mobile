import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_decor.dart';
import '../../widgets/care_page.dart';

class LegalSection {
  final String title, body;
  const LegalSection(this.title, this.body);
}

class LegalPage extends StatefulWidget {
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
  State<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> {
  bool read = false;
  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.extentAfter < 8 && !read) setState(() => read = true);
          return false;
        },
        child: CarePage(
          title: widget.title,
          subtitle: 'eCARE+ · Version du 24 octobre 2026',
          child: CareCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(widget.icon, color: AppColors.primary, size: 28),
                const SizedBox(height: 14),
                SelectableText(
                  widget.introduction,
                  style: AppDecor.t(14, h: 1.8),
                ),
                for (final s in widget.sections) ...[
                  const SizedBox(height: 28),
                  Text(s.title, style: AppDecor.t(17, w: FontWeight.w700)),
                  const SizedBox(height: 12),
                  SelectableText(s.body, style: AppDecor.t(14, h: 1.8)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: read ? () => Navigator.pop(context, true) : null,
                  child: const Text('J’ai lu ce document jusqu’à la fin'),
                ),
              ],
            ),
          ),
        ),
      );
}
