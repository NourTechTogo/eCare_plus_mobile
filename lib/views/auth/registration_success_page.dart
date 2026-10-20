import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../routes/app_routes.dart';

class RegistrationSuccessPage extends StatefulWidget {
  final bool firstRegistration;
  const RegistrationSuccessPage({super.key, this.firstRegistration = false});

  @override
  State<RegistrationSuccessPage> createState() =>
      _RegistrationSuccessPageState();
}

class _RegistrationSuccessPageState extends State<RegistrationSuccessPage>
    with SingleTickerProviderStateMixin {
  static const _items = [
    'Profil créé',
    'Pathologie configurée',
    'Données initiales enregistrées',
    'Notifications activées',
  ];

  late final AnimationController _c;
  Timer? _redirect;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    if (widget.firstRegistration) _c.forward();
    _redirect = Timer(
      widget.firstRegistration ? const Duration(seconds: 5) : Duration.zero,
      () {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      },
    );
  }

  Animation<double> _iv(
    double a,
    double b, [
    Curve curve = Curves.easeOutCubic,
  ]) => CurvedAnimation(
    parent: _c,
    curve: Interval(a, b, curve: curve),
  );

  @override
  void dispose() {
    _redirect?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.firstRegistration) {
      return const Scaffold(body: SizedBox.shrink());
    }
    const deep = AppColors.primaryDeep;
    final badge = _iv(0, .35, Curves.elasticOut);
    final title = _iv(.2, .45);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [deep, AppColors.primary, AppColors.primaryAccent],
              stops: const [0, .55, 1],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: badge,
                        child: Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withAlpha(70),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: AppColors.primary,
                            size: 64,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      FadeTransition(
                        opacity: title,
                        child: Column(
                          children: [
                            Text(
                              'Félicitations !',
                              style: AppTextStyles.heading1.copyWith(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Votre profil est configuré. Vous êtes prêt à prendre soin de votre santé.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body.copyWith(
                                color: Colors.white.withAlpha(225),
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(34),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: Colors.white.withAlpha(70)),
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < _items.length; i++)
                              _CheckRow(
                                label: _items[i],
                                animation: _iv(.30 + i * .1, .58 + i * .1),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      FadeTransition(
                        opacity: _iv(.85, 1),
                        child: Text(
                          'Vous allez être redirigé vers la page de connexion…',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withAlpha(200),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String label;
  final Animation<double> animation;
  const _CheckRow({required this.label, required this.animation});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(.12, 0),
          end: Offset.zero,
        ).animate(animation),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.primary,
                  size: 17,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
