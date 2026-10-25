import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../routes/app_routes.dart';
import '../../widgets/auth_layout.dart';
import '../../widgets/gradient_button.dart';

class CodeVerificationPage extends StatefulWidget {
  final String phone;
  const CodeVerificationPage({super.key, this.phone = ''});

  @override
  State<CodeVerificationPage> createState() => _CodeVerificationPageState();
}

class _CodeVerificationPageState extends State<CodeVerificationPage> {
  static const _length = 4;
  final _code = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  int _seconds = 30;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds == 0) {
        t.cancel();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  Future<void> _verify() async {
    if (_code.text.length < _length) {
      setState(() => _error = 'Saisissez les $_length chiffres du code.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    // TODO: vérifier le code auprès de l'API. Si invalide :
    //   setState(() => _error = 'Code incorrect, réessayez.');
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.pushReplacementNamed(context, AppRoutes.registrationSuccess);
  }

  void _resend() {
    // TODO: renvoyer le SMS
    _code.clear();
    setState(() => _error = null);
    _startTimer();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(
          'Un nouveau code a été envoyé.',
          style: AppTextStyles.caption.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _seconds == 0;
    return AuthLayout(
      title: 'Vérification\ndu code',
      subtitle: widget.phone.isEmpty
          ? 'Saisissez le code reçu par SMS.'
          : 'Un code à $_length chiffres a été envoyé par SMS au ${widget.phone}.',
      headerHeight: 320,
      child: Column(
        children: [
          Text(
            'Code PIN',
            style: AppTextStyles.label.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _OtpBoxes(
            controller: _code,
            focus: _focus,
            length: _length,
            hasError: _error != null,
            onChanged: (v) {
              if (_error != null) setState(() => _error = null);
              if (v.length == _length) _verify();
            },
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _error == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.required,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 22),
          GradientButton(
            text: 'Suivant',
            onPressed: _verify,
            isLoading: _loading,
          ),
          const SizedBox(height: 12),
          canResend
              ? TextButton(
                  onPressed: _resend,
                  child: Text(
                    'Renvoyer le code',
                    style: AppTextStyles.link.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Renvoyer le code dans ${_seconds}s',
                    style: AppTextStyles.caption.copyWith(fontSize: 13),
                  ),
                ),
        ],
      ),
    );
  }
}

/// Cases PIN : un seul champ invisible pilote l'affichage (saisie, collage
/// et remplissage automatique du SMS fonctionnent naturellement).
class _OtpBoxes extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focus;
  final int length;
  final bool hasError;
  final ValueChanged<String> onChanged;

  const _OtpBoxes({
    required this.controller,
    required this.focus,
    required this.length,
    required this.hasError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: focus.requestFocus,
      child: AnimatedBuilder(
        animation: Listenable.merge([controller, focus]),
        builder: (_, _) {
          final text = controller.text;
          final active = text.length.clamp(0, length - 1);
          return SizedBox(
            height: 66,
            child: Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      _Box(
                        char: i < text.length ? text[i] : '',
                        isActive: focus.hasFocus && i == active,
                        hasError: hasError,
                      ),
                    ],
                  ],
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: controller,
                      focusNode: focus,
                      autofocus: true,
                      showCursor: false,
                      enableInteractiveSelection: false,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(length),
                      ],
                      onChanged: onChanged,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Box extends StatelessWidget {
  final String char;
  final bool isActive;
  final bool hasError;
  const _Box({
    required this.char,
    required this.isActive,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    final border = hasError
        ? AppColors.required
        : isActive
        ? AppColors.primary
        : Colors.transparent;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 58,
      height: 66,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.8),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primary.withAlpha(45),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        char,
        style: AppTextStyles.heading1.copyWith(
          fontSize: 28,
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
