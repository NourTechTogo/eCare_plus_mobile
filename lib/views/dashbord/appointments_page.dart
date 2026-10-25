import 'package:flutter/material.dart';
import '../../widgets/appointment_availability_form.dart';
import 'package:provider/provider.dart';
import '../../models/care_data.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_decor.dart';
import '../../widgets/care_page.dart';
import '../../widgets/care_components.dart';

class AppointmentsPage extends StatefulWidget {
  final bool showBack;
  final String initialDoctor;
  const AppointmentsPage({
    super.key,
    this.showBack = true,
    this.initialDoctor = '',
  });

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  @override
  void initState() {
    super.initState();
    if (widget.initialDoctor.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openAddDialog();
      });
    }
  }

  Future<void> _openAddDialog() => showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.sizeOf(dialogContext).height * .9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: AppointmentAvailabilityForm(
            doctor: widget.initialDoctor,
            onSaved: _save,
          ),
        ),
      ),
    ),
  );

  void _save(CareAppointment appointment) {
    context.read<CareData>().addAppointment(appointment);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rendez-vous ajouté à votre agenda personnel.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointments = [...context.watch<CareData>().appointments]
      ..sort((a, b) => a.date.compareTo(b.date));
    return CarePage(
      title: 'Mes rendez-vous',
      subtitle: 'Retrouvez les dates de votre suivi.',
      showBack: widget.showBack,
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddDialog,
        tooltip: 'Ajouter un rendez-vous',
        backgroundColor: AppColors.primaryDeep,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      child: Column(
        children: [
          CareSummary(
            icon: Icons.calendar_month_rounded,
            title: 'Votre agenda santé',
            description:
                '${appointments.length} rendez-vous dans votre agenda personnel.',
            footer: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: _openAddDialog,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Ajouter une date'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (appointments.isEmpty)
            const CareEmpty(
              icon: Icons.event_available_outlined,
              title: 'Votre agenda est libre',
              description:
                  'Les exemples de créneaux servent uniquement à votre agenda personnel. Ils ne représentent pas les disponibilités de votre médecin affecté.',
            )
          else
            for (final appointment in appointments) ...[
              CareCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 54,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLighter,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${appointment.date.day}',
                                style: AppDecor.t(
                                  22,
                                  c: AppColors.primary,
                                  w: FontWeight.w700,
                                ),
                              ),
                              Text(
                                const [
                                  'JAN',
                                  'FÉV',
                                  'MAR',
                                  'AVR',
                                  'MAI',
                                  'JUIN',
                                  'JUIL',
                                  'AOÛT',
                                  'SEP',
                                  'OCT',
                                  'NOV',
                                  'DÉC',
                                ][appointment.date.month - 1],
                                style: AppDecor.t(
                                  10,
                                  c: AppColors.primary,
                                  w: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${appointment.doctor}\n${careTime(appointment.date)} · Agenda personnel',
                            style: AppDecor.t(14, w: FontWeight.w600, h: 1.8),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Supprimer le rendez-vous',
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () async {
                            final remove = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Supprimer ce rendez-vous ?'),
                                content: const Text(
                                  'Cette action supprime uniquement votre entrée dans cet agenda.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, false),
                                    child: const Text('Conserver'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, true),
                                    child: const Text('Supprimer'),
                                  ),
                                ],
                              ),
                            );
                            if (remove == true && context.mounted) {
                              context.read<CareData>().removeAppointment(
                                appointment,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
          const SizedBox(height: 18),
          Text(
            'Enregistré pour cette session. Une date ajoutée ici ne confirme pas une réservation auprès du médecin.',
            textAlign: TextAlign.center,
            style: AppDecor.t(11, c: AppColors.textMuted, h: 1.6),
          ),
        ],
      ),
    );
  }
}

Future<void> openAppointmentsPage(
  BuildContext context, {
  String doctor = '',
}) async {
  await Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (_) => AppointmentsPage(initialDoctor: doctor),
    ),
  );
}
