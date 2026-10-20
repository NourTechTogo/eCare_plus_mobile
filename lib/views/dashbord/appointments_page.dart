import 'package:flutter/material.dart';
import '../../widgets/appointment_availability_form.dart';
import 'package:provider/provider.dart';
import '../../models/care_data.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_decor.dart';
import '../../widgets/care_page.dart';
import '../../widgets/gradient_button.dart';

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
  late bool _adding = widget.initialDoctor.isNotEmpty;

  void _save(CareAppointment appointment) {
    context.read<CareData>().addAppointment(appointment);
    setState(() => _adding = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rendez-vous ajouté à votre agenda personnel.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointments = context.watch<CareData>().appointments;
    return CarePage(
      title: 'Mes rendez-vous',
      subtitle:
          'Organisez vos consultations et retrouvez vos prochains rendez-vous.',
      showBack: widget.showBack,
      child: Column(
        children: [
          if (_adding)
            CareCard(
              child: Column(
                children: [
                  AppointmentAvailabilityForm(
                    doctor: widget.initialDoctor,
                    onSaved: _save,
                  ),
                  TextButton(
                    onPressed: () => setState(() => _adding = false),
                    child: const Text('Annuler'),
                  ),
                ],
              ),
            )
          else
            GradientButton(
              text: 'Ajouter un rendez-vous',
              onPressed: () => setState(() => _adding = true),
            ),
          const SizedBox(height: 20),
          if (appointments.isEmpty)
            const CareEmpty(
              icon: Icons.event_available_outlined,
              title: 'Votre agenda est libre',
              description:
                  'Choisissez votre médecin et un créneau disponible pour planifier votre consultation.',
            )
          else
            for (final appointment in appointments) ...[
              CareCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            appointment.doctor,
                            style: AppDecor.t(15, w: FontWeight.w700),
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
                    const SizedBox(height: 12),
                    Text(
                      '${careDate(appointment.date)} · ${careTime(appointment.date)}',
                      style: AppDecor.t(
                        14,
                        c: AppColors.primary,
                        w: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
          const SizedBox(height: 18),
          Text(
            'Agenda personnel · Les entrées restent disponibles pendant cette session. '
            'L’ajout ne réserve pas de consultation auprès du médecin.',
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
