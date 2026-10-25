import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/api_session.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_decor.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/page_header.dart';
import '../../models/care_data.dart';
import '../../services/profile_photo_service.dart';
import '../../widgets/patient_avatar.dart';
import 'package:flutter/services.dart';

class ProfilePage extends StatefulWidget {
  final bool firstTime;
  final ImagePicker? imagePicker;
  const ProfilePage({super.key, this.firstTime = false, this.imagePicker});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<void> choosePhoto() async {
    final session = context.read<ApiSession>();
    final generation = session.generation;
    try {
      final photo = await (widget.imagePicker ?? ImagePicker()).pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (photo == null) return;
      final bytes = await ProfilePhotoService.readPhoto(photo);
      if (mounted && generation == session.generation) {
        context.read<CareData>().setProfilePhoto(bytes);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is PlatformException
                ? 'Autorisez l’accès aux photos dans les paramètres du téléphone.'
                : 'Impossible de lire cette photo. Choisissez une image de moins de 10 Mo.',
          ),
        ),
      );
    }
  }

  static const fields = <String, String>{
    'nom': 'Nom',
    'prenoms': 'Prénoms',
    'email': 'E-mail',
    'telephone': 'Téléphone',
    'dateNaissance': 'Date de naissance (AAAA-MM-JJ)',
    'adresse': 'Adresse',
    'ville': 'Ville',
    'pays': 'Pays',
    'languePreferee': 'Langue préférée',
    'personneAContacter': 'Contact d’urgence',
    'telephoneUrgence': 'Téléphone d’urgence',
    'groupeSanguin': 'Groupe sanguin',
    'tailleCm': 'Taille (cm)',
    'poidsKg': 'Poids (kg)',
    'allergies': 'Allergies',
    'antecedents': 'Antécédents',
  };
  final controllers = {
    for (final key in fields.keys) key: TextEditingController(),
  };
  final form = GlobalKey<FormState>();
  String sexe = 'NON_RENSEIGNE';
  String? pathologie, error;
  bool loading = true, saving = false;
  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  Future<void> load() async {
    try {
      final session = context.read<ApiSession>();
      await session.refreshProfile();
      if (!mounted) return;
      final p = session.profile!;
      for (final e in controllers.entries) {
        e.value.text = p[e.key]?.toString() ?? '';
      }
      sexe = p['sexe'] as String? ?? 'NON_RENSEIGNE';
      pathologie = p['pathologie'] as String?;
      setState(() {
        loading = false;
        error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          error = e.toString();
        });
      }
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      final values = <String, dynamic>{
        for (final e in controllers.entries)
          e.key: e.value.text.trim().isEmpty ? null : e.value.text.trim(),
        'sexe': sexe,
        'pathologie': pathologie,
      };
      for (final k in ['poidsKg', 'tailleCm']) {
        values[k] = double.tryParse(controllers[k]!.text.replaceAll(',', '.'));
      }
      await context.read<ApiSession>().saveProfile(values);
      if (mounted) {
        setState(() => error = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil enregistré sur le serveur.')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget field(String key) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Label(fields[key]!),
      Semantics(
        label: fields[key],
        child: TextFormField(
          key: ValueKey('profile-$key'),
          controller: controllers[key],
          keyboardType: ['poidsKg', 'tailleCm'].contains(key)
              ? const TextInputType.numberWithOptions(decimal: true)
              : key == 'email'
              ? TextInputType.emailAddress
              : key.toLowerCase().contains('telephone')
              ? TextInputType.phone
              : TextInputType.text,
          style: AppDecor.t(14.5, w: FontWeight.w600),
          decoration: decoration(fields[key]!),
          validator: (v) {
            if (['nom', 'prenoms'].contains(key) &&
                (v == null || v.trim().isEmpty)) {
              return 'Obligatoire';
            }
            if (['telephone', 'email'].contains(key) &&
                controllers['telephone']!.text.trim().isEmpty &&
                controllers['email']!.text.trim().isEmpty) {
              return 'Renseignez un e-mail ou un téléphone';
            }
            if (['poidsKg', 'tailleCm'].contains(key) &&
                v != null &&
                v.isNotEmpty) {
              final n = double.tryParse(v.replaceAll(',', '.'));
              if (n == null || !n.isFinite || n <= 0) {
                return 'Nombre positif requis';
              }
            }
            if (key == 'dateNaissance' && v != null && v.isNotEmpty) {
              final d = DateTime.tryParse(v);
              if (d == null ||
                  d.isAfter(DateTime.now()) ||
                  !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) {
                return 'Date valide au format AAAA-MM-JJ';
              }
            }
            return null;
          },
        ),
      ),
    ],
  );
  InputDecoration decoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    hintStyle: AppDecor.t(14, c: AppColors.textMuted),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
    ),
  );

  void toggleCondition(String value, bool selected) {
    final choices = {
      if (pathologie?.contains('diabete') == true) 'diabete',
      if (pathologie?.contains('hypertension') == true) 'hypertension',
    };
    if (selected) {
      choices.add(value);
    } else {
      choices.remove(value);
    }
    setState(
      () => pathologie = choices.length == 2
          ? 'diabete_hypertension'
          : choices.isEmpty
          ? null
          : choices.first,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.scaffoldBackground,
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Form(
              key: form,
              child: Column(
                children: [
                  PageHeader(
                    title: 'Votre profil',
                    subtitle: 'Vos informations personnelles et médicales.',
                    showBack: !widget.firstTime,
                  ),
                  const SizedBox(height: 26),
                  _Avatar(onAdd: choosePhoto, loading: saving),
                  const SizedBox(height: 8),
                  Text(
                    'Photo limitée à cette session, non transmise au médecin.',
                    textAlign: TextAlign.center,
                    style: AppDecor.t(11, c: AppColors.textMuted),
                  ),
                  const SizedBox(height: 20),
                  if (loading) const CircularProgressIndicator(),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (!loading) ...[
                    field('nom'),
                    field('prenoms'),
                    const _Label('Sexe'),
                    DropdownButtonFormField<String>(
                      initialValue: sexe,
                      decoration: decoration('Sélectionner'),
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'FEMININ',
                          child: Text('Femme'),
                        ),
                        DropdownMenuItem(
                          value: 'MASCULIN',
                          child: Text('Homme'),
                        ),
                        DropdownMenuItem(value: 'AUTRE', child: Text('Autre')),
                        DropdownMenuItem(
                          value: 'NON_RENSEIGNE',
                          child: Text('Non renseigné'),
                        ),
                      ],
                      onChanged: (v) => setState(() => sexe = v!),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: field('poidsKg')),
                        const SizedBox(width: 14),
                        Expanded(child: field('tailleCm')),
                      ],
                    ),
                    const _Label('Groupe sanguin (facultatif)'),
                    DropdownButtonFormField<String>(
                      initialValue: controllers['groupeSanguin']!.text,
                      isExpanded: true,
                      decoration: decoration('Sélectionner'),
                      items: [
                        for (final value in {
                          '',
                          'A+',
                          'A-',
                          'B+',
                          'B-',
                          'AB+',
                          'AB-',
                          'O+',
                          'O-',
                          controllers['groupeSanguin']!.text,
                        })
                          DropdownMenuItem(
                            value: value,
                            child: Text(
                              value.isEmpty ? 'Non renseigné' : value,
                            ),
                          ),
                      ],
                      onChanged: (v) =>
                          controllers['groupeSanguin']!.text = v ?? '',
                    ),
                    const _Label('Pathologies suivies'),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('Diabète'),
                            selected: pathologie?.contains('diabete') ?? false,
                            onSelected: (v) => toggleCondition('diabete', v),
                          ),
                          FilterChip(
                            label: const Text('Hypertension'),
                            selected:
                                pathologie?.contains('hypertension') ?? false,
                            onSelected: (v) =>
                                toggleCondition('hypertension', v),
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Vous pouvez sélectionner les deux pour adapter votre suivi.',
                        style: AppDecor.t(12, c: AppColors.textMuted),
                      ),
                    ),
                    for (final key in [
                      'email',
                      'telephone',
                      'dateNaissance',
                      'adresse',
                      'ville',
                      'pays',
                      'languePreferee',
                      'personneAContacter',
                      'telephoneUrgence',
                      'allergies',
                      'antecedents',
                    ])
                      field(key),
                    const SizedBox(height: 30),
                    GradientButton(
                      text: 'Enregistrer',
                      onPressed: save,
                      isLoading: saving,
                    ),
                  ],
                  TextButton(
                    onPressed: saving ? null : load,
                    child: const Text('Recharger le profil'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
      child: Text(text, style: AppDecor.t(13, w: FontWeight.w600)),
    ),
  );
}

class _Avatar extends StatelessWidget {
  final VoidCallback onAdd;
  final bool loading;
  const _Avatar({required this.onAdd, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            gradient: AppDecor.gradient,
            shape: BoxShape.circle,
          ),
          child: const PatientAvatar(radius: 58),
        ),
        Positioned(
          right: 2,
          bottom: 6,
          child: IconButton.filled(
            tooltip: 'Choisir une photo',
            onPressed: loading ? null : onAdd,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(48, 48),
              side: const BorderSide(color: Colors.white, width: 3),
            ),
            icon: loading
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.add_rounded, color: Colors.white, size: 19),
          ),
        ),
      ],
    );
  }
}
