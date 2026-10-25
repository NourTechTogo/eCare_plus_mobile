import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'care_date_time_picker.dart';
import '../models/medical_document.dart';
import '../services/document_library.dart';
import '../utils/app_colors.dart';
import '../utils/app_decor.dart';
import 'gradient_button.dart';

class DocumentImportSheet extends StatefulWidget {
  final DocumentLibrary library;
  final XFile file;
  const DocumentImportSheet({
    super.key,
    required this.library,
    required this.file,
  });
  @override
  State<DocumentImportSheet> createState() => _DocumentImportSheetState();
}

class _DocumentImportSheetState extends State<DocumentImportSheet> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(
    text: widget.file.name.replaceFirst(RegExp(r'\.[^.]+$'), ''),
  );
  late final Set<MedicalCondition> _conditions =
      widget.library.conditions.length == 1
      ? Set.of(widget.library.conditions)
      : {};
  DocumentCategory _category = DocumentCategory.prescription;
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.library.importFile(
        widget.file,
        title: _title.text,
        category: _category,
        conditions: _conditions,
        date: _date,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e is DocumentException
              ? e.message
              : 'Impossible d’enregistrer le document. Réessayez.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderDark,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Ajouter à mon carnet',
                style: AppDecor.t(
                  22,
                  w: FontWeight.w700,
                  c: AppColors.primaryDeep,
                ),
              ),
              const SizedBox(height: 6),
              if (widget.library.remote)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Ce document sera transmis à votre dossier et accessible aux professionnels habilités.',
                  ),
                ),
              Text(
                widget.file.name,
                style: AppDecor.t(12, c: AppColors.textMuted),
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _title,
                enabled: !_saving,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Nom du document',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Donnez un nom au document.'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<DocumentCategory>(
                initialValue: _category,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final category in DocumentCategory.values)
                    DropdownMenuItem(
                      value: category,
                      child: Text(category.label),
                    ),
                ],
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _category = value!),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _saving
                    ? null
                    : () async {
                        final date = await showCareDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                          helpText: 'Date du document',
                        );
                        if (date != null && mounted) {
                          setState(() => _date = date);
                        }
                      },
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(
                  'Date : ${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                ),
              ),
              const SizedBox(height: 16),
              if (!widget.library.remote) ...[
                Text('Concerne', style: AppDecor.t(14, w: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  'Sélectionnez les suivis concernés, ou laissez vide pour Général.',
                  style: AppDecor.t(12, c: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final condition
                        in (widget.library.conditions.isEmpty
                            ? MedicalCondition.values
                            : widget.library.conditions))
                      FilterChip(
                        label: Text(condition.label),
                        selected: _conditions.contains(condition),
                        onSelected: _saving
                            ? null
                            : (selected) => setState(() {
                                if (selected) {
                                  _conditions.add(condition);
                                } else {
                                  _conditions.remove(condition);
                                }
                              }),
                      ),
                  ],
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: AppDecor.t(12, c: AppColors.required),
                  ),
                ),
              const SizedBox(height: 24),
              GradientButton(
                text: 'Enregistrer le document',
                onPressed: _save,
                isLoading: _saving,
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'PDF, JPG ou PNG · 5 Mo maximum',
                  style: AppDecor.t(11, c: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
