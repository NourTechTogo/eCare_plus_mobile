import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class LegalConsent extends StatefulWidget {
  const LegalConsent({
    super.key,
    required this.value,
    required this.onChanged,
    this.showError = false,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showError;

  @override
  State<LegalConsent> createState() => _LegalConsentState();
}

class _LegalConsentState extends State<LegalConsent> {
  bool _privacyRead = false, _termsRead = false;
  Future<void> _read(String route, bool terms) async {
    final read = await Navigator.pushNamed(context, route);
    if (mounted && read == true) {
      setState(() {
        if (terms) {
          _termsRead = true;
        } else {
          _privacyRead = true;
        }
      });
    }
  }

  late final _privacy = TapGestureRecognizer()
    ..onTap = () => _read(AppRoutes.privacyPolicy, false);
  late final _terms = TapGestureRecognizer()
    ..onTap = () => _read(AppRoutes.termsOfUse, true);

  @override
  void dispose() {
    _privacy.dispose();
    _terms.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final linkStyle = AppTextStyles.caption.copyWith(
      color: AppColors.primary,
      fontSize: 13,
      height: 1.7,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.primary,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(4, 4, 14, 12),
      decoration: BoxDecoration(
        color: widget.showError
            ? AppColors.required.withAlpha(8)
            : AppColors.primary.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.showError
              ? AppColors.required
              : AppColors.primary.withAlpha(35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: widget.value,
                semanticLabel:
                    'Accepter la politique de confidentialité et les conditions générales d’utilisation. Obligatoire pour s’inscrire.',
                onChanged: _privacyRead && _termsRead
                    ? (value) => widget.onChanged(value ?? false)
                    : null,
                activeColor: AppColors.primary,
                side: BorderSide(
                  color: widget.showError
                      ? AppColors.required
                      : AppColors.borderDark,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'J’ai lu et j’accepte la '),
                        TextSpan(
                          text: 'politique de confidentialité',
                          style: linkStyle,
                          recognizer: _privacy,
                        ),
                        const TextSpan(text: ' et les '),
                        TextSpan(
                          text: 'conditions générales d’utilisation',
                          style: linkStyle,
                          recognizer: _terms,
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      height: 1.7,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 48, top: 6),
            child: Semantics(
              liveRegion: widget.showError,
              child: Text(
                widget.showError
                    ? 'Cochez la case pour accepter ces documents et vous inscrire.'
                    : 'Lisez et validez les deux documents jusqu’à la fin pour activer cette case.',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  color: widget.showError
                      ? AppColors.required
                      : AppColors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
