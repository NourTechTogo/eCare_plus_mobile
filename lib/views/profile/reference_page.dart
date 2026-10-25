import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/api_session.dart';
import '../../services/care_api.dart';
import '../../widgets/care_page.dart';
import '../../widgets/care_components.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_decor.dart';

class ReferencePage extends StatefulWidget {
  const ReferencePage({super.key});
  @override
  State<ReferencePage> createState() => _ReferencePageState();
}

class _ReferencePageState extends State<ReferencePage> {
  Map<String, dynamic>? reference;
  String? error;
  bool busy = false;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> generate() async {
    if (busy) return;
    setState(() {
      busy = true;
      reference = null;
      error = null;
    });
    try {
      final data = await CareApi(context.read<ApiSession>()).reference();
      if (mounted) setState(() => reference = data);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expiry = DateTime.tryParse('${reference?['expireLe']}');
    final expired =
        reference != null &&
        (expiry == null || !expiry.isAfter(DateTime.now()));
    final active = reference != null && !expired;
    return CarePage(
      title: 'Mon référencement',
      subtitle: 'Un lien simple avec votre établissement.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CareSummary(
            icon: Icons.qr_code_rounded,
            title: 'Votre code personnel',
            description:
                'Présentez ce code à un membre habilité de votre établissement pour rattacher votre dossier.',
          ),
          if (error != null) CareNotice(error!, error: true),
          CareSection(
            title: active ? 'Prêt à être scanné' : 'Présenter mon code',
            child: CareCard(
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, c) => Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white
                            : AppColors.scaffoldBackground,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: active
                          ? QrImageView(
                              data: reference!['jeton'] as String,
                              size: (c.maxWidth - 28)
                                  .clamp(100, 220)
                                  .toDouble(),
                              backgroundColor: Colors.white,
                            )
                          : const Padding(
                              padding: EdgeInsets.all(28),
                              child: Icon(
                                Icons.qr_code_2_rounded,
                                size: 100,
                                color: AppColors.primary,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    expired
                        ? 'Votre code a expiré'
                        : active
                        ? 'Code temporaire actif'
                        : 'Un code à usage temporaire',
                    textAlign: TextAlign.center,
                    style: AppDecor.t(16, w: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    active
                        ? 'Valable jusqu’à ${careTime(expiry!.toLocal())} le ${careDate(expiry.toLocal())}.'
                        : 'Générez votre code lorsque vous êtes avec le personnel de votre établissement.',
                    textAlign: TextAlign.center,
                    style: AppDecor.t(12, c: AppColors.textMuted, h: 1.6),
                  ),
                  if (active) ...[
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 12),
                    Text(
                      'Saisie manuelle',
                      style: AppDecor.t(12, w: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      reference!['jeton'] as String,
                      textAlign: TextAlign.center,
                      style: AppDecor.t(12, c: AppColors.primary, h: 1.6),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          CareAction(
            label: active || expired
                ? 'Générer un nouveau code'
                : 'Générer mon code',
            icon: Icons.qr_code_rounded,
            busy: busy,
            onPressed: generate,
          ),
          const CareNotice(
            'Votre code est confidentiel. Il permet le rattachement de votre dossier et ne remplace pas votre consentement au suivi.',
          ),
        ],
      ),
    );
  }
}
