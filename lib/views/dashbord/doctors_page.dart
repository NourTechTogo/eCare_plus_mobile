import 'package:flutter/material.dart';
import '../../data/doctor_catalog.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_decor.dart';
import '../../widgets/care_page.dart';
import '../../widgets/doctor_specialty_filter_sheet.dart';
import 'package:provider/provider.dart';
import '../../services/api_session.dart';
import '../messaging/server_chat_page.dart';
import '../messaging/doctor_contact_page.dart';
import 'appointments_page.dart';

class DoctorsPage extends StatefulWidget {
  const DoctorsPage({super.key});
  @override
  State<DoctorsPage> createState() => _DoctorsPageState();
}

class _DoctorsPageState extends State<DoctorsPage> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _specialty;
  List<CareDoctor>? _doctors;
  String? _error;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final api = context.read<ApiSession>();
    final generation = api.generation;
    try {
      final rows = await api.all('/mobile/me/professionnels');
      if (!mounted || api.generation != generation) return;
      setState(() {
        _doctors = rows.map(CareDoctor.fromServer).toList();
        _error = null;
      });
    } catch (error) {
      if (mounted && api.generation == generation) {
        setState(() => _error = error.toString());
      }
    }
  }

  Future<void> _open(CareDoctor doctor) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final api = context.read<ApiSession>();
      final generation = api.generation;
      final row = await api.request(
        'POST',
        '/mobile/conversations',
        body: {'professionnelId': doctor.serverId},
      );
      if (!mounted || api.generation != generation) return;
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ServerChatPage(
            conversationId: '${row['id']}',
            doctorName: doctor.name,
            doctor: doctor,
          ),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _openFilters() async {
    FocusScope.of(context).unfocus();
    final specialties =
        (_doctors ?? <CareDoctor>[])
            .map((doctor) => doctor.specialty)
            .toSet()
            .toList()
          ..sort();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => DoctorSpecialtyFilterSheet(
        specialties: specialties,
        initialSpecialty: _specialty,
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _specialty = result.isEmpty ? null : result);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctors = (_doctors ?? <CareDoctor>[])
        .where(
          (doctor) =>
              (_specialty == null || doctor.specialty == _specialty) &&
              doctor.name.toLowerCase().contains(_query.trim().toLowerCase()),
        )
        .toList();
    return CarePage(
      title: 'Mes médecins',
      subtitle: 'Trouvez votre médecin et découvrez son parcours.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppDecor.shadow(.035),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              style: AppDecor.t(14),
              decoration: InputDecoration(
                labelText: 'Rechercher un médecin',
                hintText: 'Nom du médecin',
                labelStyle: AppDecor.t(13, c: AppColors.textMuted),
                hintStyle: AppDecor.t(13, c: AppColors.textHint),
                prefixIcon: const Icon(Icons.search_rounded, size: 23),
                prefixIconColor: AppColors.primary,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_query.isNotEmpty)
                      IconButton(
                        tooltip: 'Effacer la recherche',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                    IconButton(
                      tooltip: 'Filtres',
                      onPressed: _openFilters,
                      icon: const Icon(Icons.tune_rounded),
                      style: IconButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        backgroundColor: _specialty == null
                            ? null
                            : AppColors.primaryLighter,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: AppColors.border.withValues(alpha: .7),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_specialty != null) ...[
            InputChip(
              label: Text('Spécialité : $_specialty'),
              backgroundColor: AppColors.primaryLighter,
              deleteButtonTooltipMessage: 'Retirer le filtre de spécialité',
              onDeleted: () => setState(() => _specialty = null),
            ),
            const SizedBox(height: 12),
          ],
          if (_error != null) ...[
            Text(
              _error!,
              style: AppDecor.t(13, c: Theme.of(context).colorScheme.error),
            ),
            TextButton(onPressed: _load, child: const Text('Réessayer')),
          ],
          if (_doctors == null && _error == null)
            const Center(child: CircularProgressIndicator())
          else if (_doctors?.isEmpty == true)
            const CareEmpty(
              icon: Icons.medical_services_outlined,
              title: 'Aucun professionnel affecté',
              description:
                  'Votre suivi personnel reste disponible. Le rattachement à un professionnel est facultatif.',
            )
          else if (doctors.isEmpty)
            const CareEmpty(
              icon: Icons.search_off_rounded,
              title: 'Aucun résultat',
              description:
                  'Essayez un autre nom ou modifiez le filtre de spécialité.',
            )
          else
            for (final doctor in doctors) ...[
              _DoctorDirectoryCard(
                doctor: doctor,
                onMessage: _opening ? null : () => _open(doctor),
              ),
              const SizedBox(height: 18),
            ],
        ],
      ),
    );
  }
}

class _DoctorDirectoryCard extends StatelessWidget {
  final CareDoctor doctor;
  final VoidCallback? onMessage;
  const _DoctorDirectoryCard({required this.doctor, this.onMessage});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(26),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => DoctorContactPage(doctor: doctor),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked =
                constraints.maxWidth < 280 ||
                MediaQuery.textScalerOf(context).scale(14) > 20;
            final portrait = ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: ColoredBox(
                color: doctor.color,
                child: Image.asset(
                  doctor.imageAsset,
                  width: stacked ? constraints.maxWidth : 88,
                  height: 112,
                  fit: stacked ? BoxFit.contain : BoxFit.cover,
                  alignment: const Alignment(-.44, -1),
                  semanticLabel: doctor.name,
                  errorBuilder: (_, _, _) => SizedBox(
                    width: stacked ? constraints.maxWidth : 88,
                    height: 112,
                    child: Icon(
                      doctor.icon,
                      color: AppColors.primary,
                      size: 44,
                    ),
                  ),
                ),
              ),
            );
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doctor.name, style: AppDecor.t(15, w: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  doctor.specialty,
                  style: AppDecor.t(12, c: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: Tooltip(
                    message: 'Écrire un message',
                    child: FilledButton.icon(
                      clipBehavior: Clip.antiAlias,
                      style: FilledButton.styleFrom(
                        backgroundBuilder: AppDecor.buttonBackground,
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 46),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: onMessage,
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                      ),
                      label: Text(
                        'Message',
                        textAlign: TextAlign.center,
                        style: AppDecor.t(
                          12,
                          c: Colors.white,
                          w: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
            return Column(
              children: [
                if (stacked) ...[
                  portrait,
                  const SizedBox(height: 16),
                  details,
                ] else
                  Row(
                    children: [
                      portrait,
                      const SizedBox(width: 14),
                      Expanded(child: details),
                    ],
                  ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 2),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () =>
                        openAppointmentsPage(context, doctor: doctor.name),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                    ),
                    icon: const Icon(Icons.calendar_month_outlined, size: 19),
                    label: Text(
                      'Ajouter à mon agenda',
                      textAlign: TextAlign.center,
                      style: AppDecor.t(
                        11,
                        c: AppColors.primary,
                        w: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
