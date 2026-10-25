import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

/// Champ de saisie arrondi, rempli, avec halo bleu à la sélection.
class AuthField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final String? prefixText;
  final String? helperText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    this.prefixText,
    this.helperText,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onChanged,
  });

  OutlineInputBorder _border(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: c, width: w),
  );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onChanged: onChanged,
      cursorColor: AppColors.primary,
      style: AppTextStyles.body.copyWith(
        fontSize: 15,
        color: AppColors.textMuted,
      ),
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        helperMaxLines: 4,
        errorMaxLines: 4,
        helperStyle: AppTextStyles.caption.copyWith(
          color: AppColors.textMuted,
          fontSize: 12,
        ),
        labelStyle: AppTextStyles.body.copyWith(
          fontSize: 14,
          color: AppColors.textHint,
        ),
        floatingLabelStyle: AppTextStyles.body.copyWith(
          fontSize: 13,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: const Color(0xFFF4F7FB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        prefixIcon: prefixText == null
            ? Icon(icon, color: AppColors.textHint, size: 21)
            : Padding(
                padding: const EdgeInsets.only(left: 16, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: AppColors.textHint, size: 21),
                    const SizedBox(width: 8),
                    Text(
                      prefixText!,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
        suffixIcon: suffix,
        border: _border(Colors.transparent),
        enabledBorder: _border(Colors.transparent),
        focusedBorder: _border(AppColors.primary, 1.6),
        errorBorder: _border(AppColors.required),
        focusedErrorBorder: _border(AppColors.required, 1.6),
        errorStyle: AppTextStyles.caption.copyWith(
          color: AppColors.required,
          fontSize: 12,
        ),
      ),
    );
  }
}
