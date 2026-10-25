import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_session.dart';
import '../../widgets/auth_layout.dart';
import '../../widgets/auth_field.dart';
import '../../widgets/gradient_button.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/password_rules.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final email = TextEditingController(),
      code = TextEditingController(),
      password = TextEditingController();
  int step = 0;
  bool busy = false;
  String? token, error;
  @override
  void dispose() {
    email.dispose();
    code.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (step == 2) {
      final validation = validateNewPassword(password.text);
      if (validation != null) {
        setState(() => error = validation);
        return;
      }
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final api = context.read<ApiSession>();
      if (step == 0) {
        await api.request(
          'POST',
          '/auth/mot-de-passe/otp',
          public: true,
          body: {'email': email.text.trim()},
        );
      } else if (step == 1) {
        final r = await api.request(
          'POST',
          '/auth/mot-de-passe/otp/verifier',
          public: true,
          body: {'email': email.text.trim(), 'code': code.text.trim()},
        );
        token = r['jetonReinitialisation'] as String;
      } else {
        await api.request(
          'POST',
          '/auth/mot-de-passe/reinitialiser',
          public: true,
          body: {'jeton': token, 'nouveauMotDePasse': password.text},
        );
      }
      if (mounted) setState(() => step++);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
    title: 'Mot de passe\noublié ?',
    subtitle: 'Pas de panique, nous vous aidons à retrouver l’accès.',
    headerHeight: 280,
    showEcg: false,
    footer: TextButton.icon(
      onPressed: () => Navigator.pop(context),
      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
      label: Text(
        'Retour à la connexion',
        style: AppTextStyles.link.copyWith(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: Column(
        key: ValueKey(step),
        children: [
          _RoundIcon(
            icon: step == 3
                ? Icons.check_circle_outline_rounded
                : step == 0
                ? Icons.lock_reset_rounded
                : Icons.mark_email_read_rounded,
            color: step == 3 ? AppColors.success : AppColors.primary,
            bg: step == 3 ? const Color(0xFFDCFCE7) : AppColors.primaryLighter,
          ),
          const SizedBox(height: 18),
          Text(
            step == 3
                ? 'Mot de passe modifié !'
                : step == 0
                ? 'Réinitialiser votre mot de passe'
                : step == 1
                ? 'Code de vérification'
                : 'Nouveau mot de passe',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading1.copyWith(
              fontSize: 22,
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            step == 0
                ? 'Entrez votre e-mail. Nous vous enverrons un code pour modifier votre mot de passe.'
                : step == 1
                ? 'Si ce compte existe, un code a été envoyé par e-mail.'
                : step == 2
                ? newPasswordHint
                : 'Vous pouvez maintenant vous reconnecter.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              fontSize: 14,
              height: 1.55,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 22),
          if (step == 0)
            AuthField(
              label: 'E-mail',
              controller: email,
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
          if (step == 1) ...[
            AuthField(
              label: 'Code de vérification',
              controller: code,
              icon: Icons.pin_outlined,
              keyboardType: TextInputType.number,
            ),
            TextButton(
              onPressed: busy ? null : () => setState(() => step = 0),
              child: const Text('Renvoyer un code'),
            ),
          ],
          if (step == 2)
            AuthField(
              label: 'Nouveau mot de passe',
              controller: password,
              icon: Icons.lock_outline_rounded,
              obscureText: true,
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 24),
          if (step < 3)
            GradientButton(
              text: step == 0
                  ? 'Envoyer le code'
                  : step == 1
                  ? 'Vérifier le code'
                  : 'Enregistrer le mot de passe',
              onPressed: submit,
              isLoading: busy,
            )
          else
            GradientButton(
              text: 'Se connecter',
              onPressed: () => Navigator.pop(context),
            ),
        ],
      ),
    ),
  );
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  const _RoundIcon({required this.icon, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .6, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (_, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 38),
      ),
    );
  }
}
