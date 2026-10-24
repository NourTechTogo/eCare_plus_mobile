import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/doctor_catalog.dart';
import '../../models/care_data.dart';
import '../../routes/app_routes.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_decor.dart';
import '../profile/profile_page.dart';
import 'appointments_page.dart';
import '../../widgets/page_header.dart';
import '../../widgets/patient_avatar.dart';
import '../../widgets/doctor_message_button.dart';
import '../messaging/doctor_contact_page.dart';

class HomePage extends StatelessWidget {
  final VoidCallback? onWelcomeTap;
  const HomePage({super.key, this.onWelcomeTap});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned(
        top: -95,
        right: -65,
        child: Container(
          width: 290,
          height: 290,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFFBCD9F5), Color(0xFFDCEBFA)],
            ),
            border: Border.all(color: const Color(0xFFC5DFF5)),
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        top: 315,
        left: -100,
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFC9E6F3), Color(0xFFE2F1F8)],
            ),
            border: Border.all(color: const Color(0xFFCAE4F0)),
            shape: BoxShape.circle,
          ),
        ),
      ),
      SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              key: const PageStorageKey('home-scroll'),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                _Header(greeting: _greeting),
                const SizedBox(height: 24),
                const _SearchBar(),
                const SizedBox(height: 22),
                _WelcomeCard(onTap: onWelcomeTap),
                const SizedBox(height: 24),
                Text('Accès rapide', style: AppDecor.t(16, w: FontWeight.w700)),
                const SizedBox(height: 10),
                const _QuickActions(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Mes médecins',
                        style: AppDecor.t(16, w: FontWeight.w700),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.doctors),
                      child: const Text('Voir tout'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height:
                      268 +
                      120 *
                          (MediaQuery.textScalerOf(context).scale(14) / 14 - 1)
                              .clamp(0, double.infinity),
                  child: ListView.separated(
                    key: const PageStorageKey('doctor-scroll'),
                    scrollDirection: Axis.horizontal,
                    itemCount: doctorCatalog.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (_, index) =>
                        _DoctorCard(doctor: doctorCatalog[index]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

class _Header extends StatelessWidget {
  final String greeting;
  const _Header({required this.greeting});
  @override
  Widget build(BuildContext context) {
    final data = context.watch<CareData>();
    return PageHeader(
      title: '$greeting Gloria',
      showBack: false,
      leading: Semantics(
        button: true,
        label: 'Mon profil',
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          ),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              gradient: AppDecor.gradient,
              shape: BoxShape.circle,
            ),
            child: const PatientAvatar(radius: 25),
          ),
        ),
      ),
      action: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: AppDecor.shadow(.04),
        ),
        child: IconButton(
          tooltip: 'Notifications',
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.notifications),
          icon: Badge(
            isLabelVisible:
                data.remindersEnabled && data.appointments.isNotEmpty,
            backgroundColor: AppColors.primary,
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: Color(0xFFDCE6F2)),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => Navigator.pushNamed(context, AppRoutes.doctors),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Rechercher un médecin',
                style: AppDecor.t(13, c: AppColors.textMuted),
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ],
        ),
      ),
    ),
  );
}

class _WelcomeCard extends StatelessWidget {
  final VoidCallback? onTap;
  const _WelcomeCard({this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primaryDeep, AppColors.primary],
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: AppColors.navigationBlue.withValues(alpha: .09),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        splashColor: Colors.white.withValues(alpha: .15),
        highlightColor: Colors.white.withValues(alpha: .08),
        onTap: onTap ?? () => Navigator.pushNamed(context, AppRoutes.articles),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenue',
                      style: AppDecor.t(20, w: FontWeight.w700, c: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Votre suivi médical\ncommence ici.',
                      style: AppDecor.t(13, c: const Color(0xFFE2EFFA), h: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 80,
                height: 92,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Image.asset(
                  'assets/images/ecareImage1.png',
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();
  @override
  Widget build(BuildContext context) {
    const items = [
      (
        Icons.monitor_heart_outlined,
        'Suivi',
        AppRoutes.followUp,
        'lib/data/icon_suivi.png',
      ),
      (
        Icons.folder_copy_outlined,
        'Documents',
        AppRoutes.documents,
        'lib/data/icon_document.png',
      ),
      (
        Icons.medical_services_outlined,
        'Médecins',
        AppRoutes.doctors,
        'lib/data/Icon_medecin.png',
      ),
    ];
    final textGrowth = (MediaQuery.textScalerOf(context).scale(11) / 11 - 1)
        .clamp(0, double.infinity)
        .toDouble();
    return SizedBox(
      height: 110 + 55 * textGrowth,
      child: ListView.separated(
        key: const PageStorageKey('shortcut-scroll'),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, index) => SizedBox(
          width: 100 + 50 * textGrowth,
          child: Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: Color(0xFFDCE6F2)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => Navigator.pushNamed(context, items[index].$3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: [
                        const Color(0xFFD3E6F8),
                        const Color(0xFFE9EFFB),
                        const Color(0xFFE8F2FC),
                      ][index],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.asset(
                      items[index].$4,
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                      errorBuilder: (_, _, _) => Icon(
                        items[index].$1,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 11),
                  Text(
                    items[index].$2,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppDecor.t(11, w: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final CareDoctor doctor;
  const _DoctorCard({required this.doctor});
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(24),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => DoctorContactPage(doctor: doctor),
        ),
      ),
      child: Container(
    width: 210,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.border.withValues(alpha: .5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: doctor.color,
            borderRadius: BorderRadius.circular(18),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              doctor.imageAsset,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              semanticLabel: doctor.name,
              errorBuilder: (_, _, _) =>
                  Icon(doctor.icon, color: AppColors.primary, size: 54),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          doctor.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppDecor.t(13, w: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          doctor.specialty,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppDecor.t(11, c: AppColors.textMuted),
        ),
        const Spacer(),
        Row(
          children: [
            DoctorMessageButton(doctor: doctor),
            const SizedBox(width: 6),
            Expanded(
              child: FilledButton.icon(
                clipBehavior: Clip.antiAlias,
                style: FilledButton.styleFrom(
                  backgroundBuilder: AppDecor.buttonBackground,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () =>
                    openAppointmentsPage(context, doctor: doctor.name),
                icon: const Icon(Icons.calendar_month_outlined, size: 14),
                label: Text(
                  'Planifier',
                  style: AppDecor.t(12, w: FontWeight.w600, c: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
      ),
    ),
  );
}
