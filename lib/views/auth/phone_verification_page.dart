import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/auth_layout.dart';
import '../../widgets/auth_field.dart';
import '../../widgets/gradient_button.dart';
import 'code_verification_page.dart';

class PhoneVerificationPage extends StatefulWidget {
  /// Numéro (sans indicatif) à pré-remplir, par ex. celui saisi à l'inscription.
  final String initialPhone;
  const PhoneVerificationPage({super.key, this.initialPhone = ''});

  @override
  State<PhoneVerificationPage> createState() => _PhoneVerificationPageState();
}

class _PhoneVerificationPageState extends State<PhoneVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phone = TextEditingController(
    text: widget.initialPhone,
  );

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final full = '+228 ${_phone.text.trim()}';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Confirmer le numéro',
          textAlign: TextAlign.center,
          style: AppTextStyles.heading1.copyWith(
            fontSize: 18,
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nous allons envoyer un code de sécurité au numéro suivant :',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              full,
              style: AppTextStyles.heading1.copyWith(
                fontSize: 20,
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Modifier',
              style: AppTextStyles.label.copyWith(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Confirmer',
              style: AppTextStyles.label.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      // TODO: demander l'envoi du SMS ici
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CodeVerificationPage(phone: full)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Votre numéro\nde téléphone',
      subtitle:
          'Confirmez votre indicatif et saisissez un numéro où vous êtes joignable en cas d\'alerte.',
      headerHeight: 320,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            AuthField(
              label: 'Numéro de téléphone',
              controller: _phone,
              icon: Icons.phone_outlined,
              prefixText: '+228',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              validator: (v) {
                final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                if (d.isEmpty) return 'Ce champ est obligatoire';
                return d.length < 8 ? 'Numéro invalide' : null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 16,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Votre numéro ne sert qu\'à vous envoyer des alertes et à sécuriser votre compte.',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            GradientButton(text: 'Suivant', onPressed: _next),
          ],
        ),
      ),
    );
  }
}
