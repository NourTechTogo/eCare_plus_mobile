import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_session.dart';
import '../../services/care_api.dart';
import '../../widgets/care_page.dart';
import '../../widgets/care_components.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_decor.dart';

class ServerPreferencesPage extends StatefulWidget {
  const ServerPreferencesPage({super.key});
  @override
  State<ServerPreferencesPage> createState() => _ServerPreferencesPageState();
}

class _ServerPreferencesPageState extends State<ServerPreferencesPage> {
  Map<String, dynamic>? prefs;
  String? error, information;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  Future<void> load() async {
    try {
      final data = await CareApi(context.read<ApiSession>()).preferences();
      if (mounted) setState(() => prefs = data);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  Future<void> save(bool push, bool whatsapp) async {
    setState(() => busy = true);
    try {
      final data = await CareApi(
        context.read<ApiSession>(),
      ).savePreferences(push: push, whatsapp: whatsapp);
      if (mounted) {
        setState(() {
          prefs = data;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> sensitive(bool erase) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(
          erase ? 'Demander l’effacement ?' : 'Retirer votre consentement ?',
        ),
        content: Text(
          erase
              ? 'Une demande sera enregistrée. La suppression dépend des obligations de conservation et ne sera pas immédiate.'
              : 'L’accès au suivi clinique sera interrompu. Vous pourrez accepter à nouveau depuis votre espace.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    try {
      final care = CareApi(context.read<ApiSession>());
      if (erase) {
        final data = await care.deleteRequest();
        if (mounted) {
          setState(
            () => information =
                'Demande ${data['id']} : ${data['statut']}. ${data['information']}',
          );
        }
      } else {
        await care.withdrawConsent();
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => CarePage(
    title: 'Notifications et données',
    subtitle: 'Votre compte, vos choix, votre confidentialité.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CareSummary(
          icon: Icons.tune_rounded,
          title: 'Vos préférences',
          description:
              'Choisissez comment recevoir vos rappels et gardez la main sur vos données.',
        ),
        if (error != null) CareNotice(error!, error: true),
        CareSection(
          title: 'Mes notifications',
          subtitle: 'Vos choix sont enregistrés sur votre compte.',
          child: CareCard(
            child: prefs == null
                ? Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.primary,
                          size: 36,
                        ),
                      ),
                      CareAction(
                        label: 'Charger les préférences',
                        onPressed: load,
                        icon: Icons.refresh_rounded,
                      ),
                    ],
                  )
                : Column(
                    children: [
                      preference(
                        'Notifications push',
                        'Recevez vos rappels sur un appareil enregistré.',
                        Icons.notifications_active_outlined,
                        prefs!['pushActif'] == true,
                        (v) => save(v, prefs!['whatsappActif'] == true),
                      ),
                      const Divider(height: 32, color: AppColors.border),
                      preference(
                        'Recevoir sur WhatsApp',
                        'Des notifications génériques sur votre numéro, avec votre accord.',
                        Icons.chat_bubble_outline_rounded,
                        prefs!['whatsappActif'] == true,
                        (v) => save(prefs!['pushActif'] == true, v),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'La réception dépend de la disponibilité des services de notification.',
                        style: AppDecor.t(11, c: AppColors.textMuted, h: 1.6),
                      ),
                    ],
                  ),
          ),
        ),
        CareSection(
          title: 'Mes données personnelles',
          subtitle: 'Ces actions demandent toujours votre confirmation.',
          child: Column(
            children: [
              CareDetail(
                icon: Icons.manage_accounts_outlined,
                title: 'Demander l’effacement',
                detail:
                    'Adressez une demande concernant vos données. Certains éléments restent soumis aux obligations de conservation.',
                action: OutlinedButton(
                  onPressed: busy ? null : () => sensitive(true),
                  style: actionStyle,
                  child: const Text(
                    'Demander l’effacement de mes données',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              CareDetail(
                icon: Icons.shield_outlined,
                title: 'Mon consentement au suivi',
                detail:
                    'Le retrait interrompt l’accès au suivi clinique. Vous pourrez l’accepter à nouveau depuis votre espace.',
                action: OutlinedButton(
                  onPressed: busy ? null : () => sensitive(false),
                  style: actionStyle,
                  child: const Text(
                    'Retirer mon consentement au suivi',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (information != null) CareNotice(information!),
      ],
    ),
  );
  ButtonStyle get actionStyle => OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    side: const BorderSide(color: AppColors.border),
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );
  Widget preference(
    String title,
    String detail,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: AppDecor.t(14, w: FontWeight.w600)),
          ),
          Switch.adaptive(
            value: value,
            onChanged: busy ? null : onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(detail, style: AppDecor.t(12, c: AppColors.textMuted, h: 1.6)),
    ],
  );
}
