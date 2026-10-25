import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../routes/app_routes.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/auth_field.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/legal_consent.dart';
import '../../services/api_session.dart';
import '../../utils/password_rules.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _lastName = TextEditingController();
  final _firstName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _accept = false;
  bool _termsError = false;
  bool _loading = false;

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _anim,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, .08),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _anim.forward();
    });
  }

  @override
  void dispose() {
    for (final c in [
      _lastName,
      _firstName,
      _email,
      _phone,
      _password,
      _confirm,
    ]) {
      c.dispose();
    }
    _anim.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    final ok = _formKey.currentState!.validate();
    setState(() => _termsError = !_accept);
    if (!ok || !_accept) return;
    setState(() => _loading = true);
    try {
      await context.read<ApiSession>().request(
        'POST',
        '/auth/inscription',
        public: true,
        body: {
          'nom': _lastName.text.trim(),
          'prenoms': _firstName.text.trim(),
          'email': _email.text.trim(),
          'telephone': '+228${_phone.text.trim()}',
          'motDePasse': _password.text,
          'consentementAccepte': true,
          'versionDocument': legalDocumentVersion,
          'cguLues': true,
          'confidentialiteLue': true,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Compte créé. Connectez-vous pour compléter votre dossier.',
          ),
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Obligatoire' : null;

  Widget _eye(bool obscured, VoidCallback onTap) => IconButton(
    tooltip: obscured ? 'Afficher' : 'Masquer',
    onPressed: onTap,
    icon: Icon(
      obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      color: AppColors.textHint,
      size: 21,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              const AuthHeader(
                title: 'Créez votre\ncompte',
                subtitle:
                    'Remplissez ce formulaire pour débuter votre accompagnement personnalisé.',
                height: 330,
                showBack: true,
                showEcg: false,
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: Transform.translate(
                        offset: const Offset(0, -52),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0B2A5B).withAlpha(26),
                                blurRadius: 40,
                                offset: const Offset(0, 18),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: AuthField(
                                            label: 'Nom',
                                            controller: _lastName,
                                            icon: Icons.person_outline_rounded,
                                            validator: _required,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: AuthField(
                                            label: 'Prénom',
                                            controller: _firstName,
                                            icon: Icons.badge_outlined,
                                            validator: _required,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    AuthField(
                                      label: 'Email',
                                      controller: _email,
                                      icon: Icons.mail_outline_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (v) {
                                        final s = v?.trim() ?? '';
                                        if (s.isEmpty) {
                                          return 'Ce champ est obligatoire';
                                        }
                                        return RegExp(
                                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                            ).hasMatch(s)
                                            ? null
                                            : 'Email invalide';
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    AuthField(
                                      label: 'Numéro de téléphone',
                                      controller: _phone,
                                      icon: Icons.phone_outlined,
                                      prefixText: '+228',
                                      keyboardType: TextInputType.phone,
                                      validator: (v) {
                                        final d = (v ?? '').replaceAll(
                                          RegExp(r'\D'),
                                          '',
                                        );
                                        if (d.isEmpty) {
                                          return 'Ce champ est obligatoire';
                                        }
                                        return d.length < 8
                                            ? 'Numéro invalide'
                                            : null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    AuthField(
                                      label: 'Mot de passe',
                                      helperText: newPasswordHint,
                                      controller: _password,
                                      icon: Icons.lock_outline_rounded,
                                      obscureText: _obscure,
                                      onChanged: (_) => setState(() {}),
                                      suffix: _eye(
                                        _obscure,
                                        () => setState(
                                          () => _obscure = !_obscure,
                                        ),
                                      ),
                                      validator: validateNewPassword,
                                    ),
                                    _StrengthBar(password: _password.text),
                                    const SizedBox(height: 16),
                                    AuthField(
                                      label: 'Confirmer le mot de passe',
                                      helperText: newPasswordHint,
                                      controller: _confirm,
                                      icon: Icons.lock_outline_rounded,
                                      obscureText: _obscureConfirm,
                                      textInputAction: TextInputAction.done,
                                      suffix: _eye(
                                        _obscureConfirm,
                                        () => setState(
                                          () => _obscureConfirm =
                                              !_obscureConfirm,
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Ce champ est obligatoire';
                                        }
                                        return v != _password.text
                                            ? 'Les mots de passe ne correspondent pas'
                                            : null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              LegalConsent(
                                value: _accept,
                                showError: _termsError,
                                onChanged: (value) => setState(() {
                                  _accept = value;
                                  if (_accept) _termsError = false;
                                }),
                              ),
                              const SizedBox(height: 22),
                              GradientButton(
                                text: "S'inscrire",
                                onPressed: _register,
                                isLoading: _loading,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -34),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Vous avez déjà un compte ?',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 14.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Connectez-vous',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.link.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }
}

/// Jauge de robustesse du mot de passe.
class _StrengthBar extends StatelessWidget {
  final String password;
  const _StrengthBar({required this.password});

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    var score = 0;
    if (validateNewPassword(password) == null) score++;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;

    const labels = ['Faible', 'Faible', 'Moyen', 'Bon', 'Excellent'];
    const colors = [
      Color(0xFFE5484D),
      Color(0xFFE5484D),
      Color(0xFFF5A524),
      Color(0xFF3BBFF3),
      Color(0xFF17B26A),
    ];
    final c = colors[score];
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 4, right: 4),
      child: Row(
        children: [
          for (var i = 0; i < 4; i++)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4,
                margin: EdgeInsets.only(right: i < 3 ? 5 : 0),
                decoration: BoxDecoration(
                  color: i < score ? c : const Color(0xFFE6EBF2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          const SizedBox(width: 12),
          Text(
            labels[score],
            style: AppTextStyles.caption.copyWith(
              color: c,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
