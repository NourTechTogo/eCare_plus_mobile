import 'package:flutter/material.dart';
import '../../data/doctor_catalog.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_decor.dart';
import '../../widgets/doctor_career.dart';
import '../../widgets/doctor_social_links.dart';
import '../../widgets/page_header.dart';
import '../dashbord/appointments_page.dart';

class DoctorContactPage extends StatelessWidget {
  final CareDoctor doctor;
  const DoctorContactPage({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                const PageHeader(title: 'Profil du médecin'),
                const SizedBox(height: 26),
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: doctor.color,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      doctor.imageAsset,
                      width: 170,
                      height: 170,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      semanticLabel: 'Portrait de ${doctor.name}',
                      errorBuilder: (_, _, _) => SizedBox(
                        width: 170,
                        height: 170,
                        child: Icon(
                          doctor.icon,
                          size: 64,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  doctor.name,
                  textAlign: TextAlign.center,
                  style: AppDecor.t(25, w: FontWeight.w700, h: 1.3),
                ),
                const SizedBox(height: 8),
                Text(
                  doctor.specialty,
                  textAlign: TextAlign.center,
                  style: AppDecor.t(
                    15,
                    c: AppColors.primary,
                    w: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                DoctorSocialLinks(doctor: doctor),
                const SizedBox(height: 28),
                if (doctor.isDemo) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLighter,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Profil de démonstration · Présentation et parcours illustratifs. Les coordonnées réelles ne sont pas encore renseignées.',
                      textAlign: TextAlign.center,
                      style: AppDecor.t(11, c: AppColors.textMuted, h: 1.6),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
                _section(
                  'À propos',
                  Text(
                    doctor.biography.isEmpty
                        ? 'La présentation du médecin sera bientôt disponible.'
                        : doctor.biography,
                    style: AppDecor.t(14, h: 1.9),
                  ),
                ),
                const SizedBox(height: 28),
                _section(
                  'Mon parcours',
                  doctor.career.isEmpty
                      ? Text(
                          'Le parcours du médecin n’est pas encore renseigné.',
                          style: AppDecor.t(13, c: AppColors.textMuted),
                        )
                      : DoctorCareer(steps: doctor.career),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    clipBehavior: Clip.antiAlias,
                    style: FilledButton.styleFrom(
                      backgroundBuilder: AppDecor.buttonBackground,
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () =>
                        openAppointmentsPage(context, doctor: doctor.name),
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text(
                      'Ajouter à mon agenda',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Ajoutez à votre agenda une consultation convenue avec ce médecin.',
                  textAlign: TextAlign.center,
                  style: AppDecor.t(11, c: AppColors.textMuted, h: 1.6),
                ),
                const SizedBox(height: 12),
                if (Navigator.canPop(context))
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Retour'),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _section(String title, Widget child) => SizedBox(
    width: double.infinity,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppDecor.t(19, w: FontWeight.w700)),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}
