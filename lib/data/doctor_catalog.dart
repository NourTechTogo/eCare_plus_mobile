import 'package:flutter/material.dart';

class CareDoctor {
  final String? serverId;
  final String name;
  final String specialty;
  final IconData icon;
  final Color color;
  final String imageAsset;
  final String biography;
  final List<DoctorCareerStep> career;
  final String? whatsappUrl;
  final String? facebookUrl;
  final String? tiktokUrl;
  final bool isDemo;
  const CareDoctor(
    this.name,
    this.specialty,
    this.icon,
    this.color,
    this.imageAsset, {
    this.biography = '',
    this.career = const [],
    this.whatsappUrl,
    this.facebookUrl,
    this.tiktokUrl,
    this.isDemo = true,
    this.serverId,
  });

  factory CareDoctor.fromServer(Map<String, dynamic> row) => CareDoctor(
    '${row['prenoms'] ?? ''} ${row['nom'] ?? ''}'.trim(),
    '${row['specialite'] ?? 'Professionnel de santé'}',
    Icons.medical_services_outlined,
    const Color(0xFFE4F2FF),
    'lib/data/Icon_medecin.png',
    serverId: '${row['id']}',
    isDemo: false,
  );
}

class DoctorCareerStep {
  final String title;
  final String description;
  final String period;
  const DoctorCareerStep(this.title, this.description, this.period);
}

// Illustrative profiles from the existing home screen, awaiting the directory.
const doctorCatalog = [
  CareDoctor(
    'Dr Johnson Mike',
    'Médecin généraliste',
    Icons.medical_services_outlined,
    Color(0xFFE4F2FF),
    'lib/data/Docteur1.png',
    biography:
        'Une approche fondée sur l’écoute et la prévention, pour accompagner chaque patient dans son quotidien. Le suivi du diabète et de l’hypertension se construit ensemble, avec des conseils simples et des objectifs adaptés.',
    career: [
      DoctorCareerStep(
        'Formation en médecine générale',
        'Un parcours consacré à la santé globale et aux soins de premier recours.',
        'Formation',
      ),
      DoctorCareerStep(
        'Accompagnement des maladies chroniques',
        'Prévention, suivi du diabète et de l’hypertension, et éducation thérapeutique.',
        'Expérience',
      ),
      DoctorCareerStep(
        'Suivi personnalisé',
        'Des consultations centrées sur les besoins et les habitudes de vie du patient.',
        'Aujourd’hui',
      ),
    ],
  ),
  CareDoctor(
    'Dr Lawson Jennifer',
    'Cardiologue',
    Icons.monitor_heart_outlined,
    Color(0xFFE4F5F1),
    'lib/data/Docteur 2.png',
    biography:
        'Prendre soin de son cœur commence par comprendre sa santé. Une approche attentive et pédagogique pour accompagner la prévention cardiovasculaire et aider chaque patient à mieux vivre avec sa maladie.',
    career: [
      DoctorCareerStep(
        'Formation en cardiologie',
        'Un parcours spécialisé dans la santé du cœur et du système cardiovasculaire.',
        'Formation',
      ),
      DoctorCareerStep(
        'Prévention cardiovasculaire',
        'Accompagnement des facteurs de risque et du suivi de la tension artérielle.',
        'Expérience',
      ),
      DoctorCareerStep(
        'Une prise en charge à votre écoute',
        'Des explications accessibles et un suivi adapté à chaque patient.',
        'Aujourd’hui',
      ),
    ],
  ),
];
