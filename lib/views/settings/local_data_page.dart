import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../utils/app_decor.dart';
import '../../utils/app_colors.dart';
import '../../widgets/care_page.dart';
import '../../widgets/settings_section.dart';
import 'local_archive_page.dart';

class LocalDataPage extends StatelessWidget {
  const LocalDataPage({super.key});
  @override
  Widget build(BuildContext context) => CarePage(
    title: 'Mes données',
    subtitle: 'Comprendre ce qui est conservé sur cet appareil.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          'Documents et suivis médicaux',
          Icons.folder_copy_outlined,
          'Le carnet principal utilise le serveur commun et ses accès privés. Le carnet local historique est séparé par identifiant patient et conservé sur cet appareil. Sa transmission est volontaire depuis les archives locales. Les fichiers historiques non attribués à un compte ne sont pas migrés automatiquement.',
        ),
        const SizedBox(height: 16),
        _card(
          'Mesures et agenda',
          Icons.timeline_rounded,
          'Le profil, les mesures et les messages texte confirmés sont conservés par le serveur et rechargés après connexion. Le jeton reste uniquement en mémoire : un redémarrage impose une nouvelle connexion. Les données affichées sont retirées à la déconnexion. Les dates confirmées de votre agenda personnel sont enregistrées sur le serveur et rechargées après connexion ; elles ne réservent pas de consultation.',
        ),
        const SizedBox(height: 16),
        _card(
          'Export et partage',
          Icons.file_download_outlined,
          'Télécharger un document crée une copie à l’emplacement choisi. Les documents transmis au serveur sont accessibles aux professionnels habilités du dossier. Retirer un document serveur ne supprime ni vos exports ni les originaux locaux.',
        ),
        const SizedBox(height: 22),
        SettingsSection(
          title: 'Gérer mes informations',
          children: [
            SettingsItem(
              icon: Icons.archive_outlined,
              title: 'Archives locales conservées',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const LocalArchivePage(),
                ),
              ),
            ),
            SettingsItem(
              icon: Icons.folder_outlined,
              title: 'Ouvrir mon carnet',
              onTap: () => Navigator.pushNamed(context, AppRoutes.documents),
            ),
            SettingsItem(
              icon: Icons.privacy_tip_outlined,
              title: 'Politique de confidentialité',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.privacyPolicy),
            ),
          ],
        ),
      ],
    ),
  );
  Widget _card(String title, IconData icon, String description) => CareCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 28),
        const SizedBox(height: 12),
        Text(
          title,
          style: AppDecor.t(16, w: FontWeight.w700, c: AppColors.primaryDeep),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: AppDecor.t(13, c: AppColors.textMuted, h: 1.6),
        ),
      ],
    ),
  );
}
