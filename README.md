# eCare+

Calendrier mensuel eCare+ disponible dans Rendez-vous : navigation, jours avec rendez-vous, liste du jour et date préremplie à l’ajout. Charte et backend conservés. Validation : 201 tests réussis, 2 optionnels ignorés ; compilation web et Android locale. [Détails du calendrier](docs/superpowers/plans/2026-10-28-agenda-calendrier-visuel.md).

Agenda personnel connecté en local le 28 octobre 2026 : dates et rappels persistants, modification et annulation via le backend commun, style eCare+ conservé. [Parcours et limites](docs/refonte/AGENDA_PERSONNEL_MOBILE.md), [validation](docs/VALIDATION.md). Le lot agenda/calendrier est regroupé sur `ecare_mobile_autonomie_rapports`.

Rapports de consultation intégrés en local le 28 octobre 2026 : [parcours et limites](docs/refonte/RAPPORTS_CONSULTATION.md), [validation](docs/VALIDATION.md). Branche de publication : `ecare_mobile_autonomie_rapports`, sans fusion dans main.

Phase 1 : le suivi patient fonctionne sans médecin ni structure obligatoires. [Bilan de l’autonomie patient](docs/refonte/PHASE_1_AUTONOMIE_PATIENT.md).

Messages vocaux privés disponibles : enregistrement, brouillon, envoi explicite et lecture avec progression, via le backend commun. Voir [les ajouts récents](AJOUTS_RECENTS.md) et [la validation du 26 octobre 2026](docs/VALIDATION.md).

## Livraison indépendante du 25 octobre 2026

Branche `ecare_mobile_stable`, reliée uniquement à son dépôt GitHub. Les [ajouts détaillés](AJOUTS_RECENTS.md), [contrats API](docs/backend/API.md) et [validation / limites](docs/VALIDATION.md) sont disponibles dans ce dépôt.

### Lancer le client patient

Prérequis : Flutter compatible avec `pubspec.yaml` et SDK Android. Exécuter `flutter pub get`, puis `flutter run --dart-define=API_URL=http://127.0.0.1:8081/api/v1`. Sur téléphone USB, configurer `adb reverse tcp:8081 tcp:8081` ; LiveKit local nécessite aussi les ports 7880/7881 selon sa configuration. Hors USB, fournir une URL joignable depuis le téléphone. Ne jamais inclure les clés LiveKit côté Flutter.

Analyse et tests : `flutter analyze` et `flutter test`. Compilation : `flutter build apk --debug --dart-define=API_URL=http://127.0.0.1:8081/api/v1`.


> Présentation : conserver le design mobile existant lors des intégrations fonctionnelles. Les écrans Mes médecins, Messages et Appels ont été restaurés à partir de l'archive d'origine en gardant le backend commun. Toute nouvelle modification de design doit être demandée explicitement. Voir [AJOUTS_RECENTS.md](AJOUTS_RECENTS.md).

> Intégration au backend commun du 25 octobre 2026 : [bilan et preuves](docs/integration-clients/BILAN.md), [configuration des services](docs/integration-clients/CONFIGURATION.md), [contrats API](docs/backend/API.md). Le carnet principal est distant ; les archives locales sont préservées. La prévisualisation Flutter navigateur utilise 5184 et le backend 8081. Les descriptions historiques ci-dessous ne valent pas preuve de disponibilité du push, des rappels natifs ou des fournisseurs d'appel.

**eCare+** est une application mobile de suivi et d'accompagnement des patients atteints de maladies chroniques, notamment le diabète et l'hypertension artérielle.

L'application permet aux patients de suivre leurs constantes de santé, consulter leur historique et leurs statistiques, recevoir des rappels et accéder à des contenus éducatifs afin de mieux gérer leur santé au quotidien.

---

## Objectifs du projet

eCare+ a pour objectif de faciliter le suivi quotidien des patients chroniques grâce à une solution mobile simple, accessible et centralisée.

L'application vise notamment à :

* Faciliter l'enregistrement et le suivi de la glycémie ;
* Permettre le suivi de la tension artérielle ;
* Présenter l'évolution des mesures sous forme de statistiques et de graphiques ;
* Gérer des rappels pour les prises de médicaments et les mesures ;
* Fournir des contenus éducatifs sur le diabète et l'hypertension ;
* Envoyer des notifications et rappels ;
* Gérer le profil et les informations du patient ;
* Faciliter le suivi et l'accompagnement médical du patient.

---

## Fonctionnalités principales

### Authentification

* Inscription ;
* Connexion ;
* Déconnexion ;
* Réinitialisation du mot de passe ;
* Gestion du profil utilisateur.

### Suivi de la glycémie

L'utilisateur peut :

* Enregistrer une mesure de glycémie ;
* Consulter son historique ;
* Visualiser l'évolution de sa glycémie ;
* Identifier les valeurs normales, basses ou élevées.

### Suivi de la tension artérielle

L'application permet d'enregistrer :

* La pression systolique ;
* La pression diastolique ;
* Le pouls ;
* La date et l'heure de la mesure.

Les données peuvent ensuite être consultées dans l'historique et les statistiques.

### Statistiques

eCare+ permet de visualiser les données de santé sous forme de :

* Graphiques ;
* Statistiques quotidiennes ;
* Statistiques hebdomadaires ;
* Statistiques mensuelles ;
* Historique des mesures.

### Rappels

L'utilisateur peut programmer des rappels pour :

* Les médicaments ;
* Les mesures de glycémie ;
* Les mesures de tension ;
* Les rendez-vous médicaux.

### Éducation sanitaire

L'application propose des contenus éducatifs permettant aux utilisateurs de mieux comprendre :

* Le diabète ;
* L'hypertension ;
* L'alimentation ;
* L'activité physique ;
* La prévention des complications ;
* Les bonnes pratiques de suivi.

### Notifications

Les notifications permettent notamment de rappeler à l'utilisateur :

* Une mesure à effectuer ;
* La prise d'un médicament ;
* Un rendez-vous ;
* Un nouveau contenu éducatif.

---

# Architecture du projet

Le projet utilise une architecture **Model – View – Service**, permettant de séparer clairement les données, l'interface utilisateur et la logique métier.

```text
lib/
│
├── main.dart
│
├── models/
│   ├── user_model.dart
│   ├── patient_model.dart
│   ├── glucose_model.dart
│   ├── blood_pressure_model.dart
│   ├── appointment_model.dart
│   ├── notification_model.dart
│   └── education_model.dart
│
├── views/
│   │
│   ├── auth/
│   │   ├── login_page.dart
│   │   ├── register_page.dart
│   │   └── forgot_password_page.dart
│   │
│   ├── dashboard/
│   │   └── dashboard_page.dart
│   │
│   ├── measurements/
│   │   ├── glucose_page.dart
│   │   ├── blood_pressure_page.dart
│   │   └── measurement_history_page.dart
│   │
│   ├── statistics/
│   │   └── statistics_page.dart
│   │
│   ├── reminders/
│   │   └── reminders_page.dart
│   │
│   ├── education/
│   │   └── education_page.dart
│   │
│   ├── notifications/
│   │   └── notifications_page.dart
│   │
│   └── profile/
│       └── profile_page.dart
│
├── services/
│   ├── auth_service.dart
│   ├── patient_service.dart
│   ├── glucose_service.dart
│   ├── blood_pressure_service.dart
│   ├── statistics_service.dart
│   ├── notification_service.dart
│   ├── reminder_service.dart
│   └── api_service.dart
│
├── widgets/
│   ├── measurement_card.dart
│   ├── statistic_card.dart
│   ├── custom_button.dart
│   ├── custom_textfield.dart
│   └── bottom_navigation.dart
│
├── utils/
│   ├── constants.dart
│   ├── validators.dart
│   └── helpers.dart
│
└── routes/
    └── app_routes.dart
```

## Description des dossiers

| Dossier     | Description                                                    |
| ----------- | -------------------------------------------------------------- |
| `models/`   | Contient les modèles représentant les données de l'application |
| `views/`    | Contient les différentes interfaces et pages de l'application  |
| `services/` | Contient la logique métier et la communication avec l'API      |
| `widgets/`  | Contient les composants réutilisables de l'interface           |
| `utils/`    | Contient les constantes, validateurs et fonctions utilitaires  |
| `routes/`   | Centralise la navigation entre les différentes pages           |
| `main.dart` | Point d'entrée de l'application Flutter                        |

---

# Technologies utilisées

## Application mobile

* Flutter
* Dart

## Base de données

* PostgreSQL

PostgreSQL est utilisé pour stocker les données utilisateurs, patients, mesures de glycémie, mesures de tension, rendez-vous, rappels, notifications et contenus éducatifs.

## Communication avec le backend

* API REST
* HTTP / HTTPS
* JSON

## Architecture

* Model – View – Service
* Séparation des responsabilités
* Composants Flutter réutilisables

## Outils de développement

* Git
* GitHub
* Visual Studio Code
* Android Studio
* Postman

---

# Dépendances Flutter

Les principales dépendances utilisées ou prévues dans le projet sont notamment :

```yaml
dependencies:
  flutter:
    sdk: flutter

  http: ^1.0.0
  provider: ^6.0.0
  flex_color_scheme: ^8.0.0
```

Les versions exactes des packages peuvent être consultées dans le fichier `pubspec.yaml`.

---

# Installation du projet

## 1. Cloner le projet

```bash
git clone https://github.com/VOTRE_USERNAME/ecare_plus_mobile.git
```

Puis :

```bash
cd ecare_plus_mobile
```

## 2. Installer les dépendances

```bash
flutter pub get
```

## 3. Vérifier l'environnement Flutter

```bash
flutter doctor
```

## 4. Lancer l'application

Pour lancer l'application sur un appareil connecté ou un émulateur :

```bash
flutter run
```

---

# Configuration de la base de données

Le projet utilise PostgreSQL.

La base de données doit être configurée côté backend avec les informations suivantes :

```text
Database: ecare_plus
Host: localhost
Port: 5432
Username: votre_utilisateur
Password: votre_mot_de_passe
```

Ne jamais placer les identifiants réels de la base de données directement dans le dépôt GitHub.

Les informations sensibles doivent être stockées dans des variables d'environnement ou dans une configuration sécurisée.

---

# Communication avec l'API

L'application Flutter communique avec le serveur via une API REST.

```text
Flutter Application
       |
       | HTTP / HTTPS
       v
    REST API
       |
       v
   PostgreSQL
```

Cette organisation permet de séparer :

* L'application mobile ;
* Le serveur et l'API ;
* La base de données.

---

# Sécurité

La sécurité constitue un élément important du projet.

Les mesures prévues comprennent notamment :

* Authentification des utilisateurs ;
* Validation des données ;
* Communication sécurisée avec l'API via HTTPS ;
* Protection des données personnelles ;
* Gestion des sessions ;
* Contrôle des accès ;
* Protection des informations médicales.

---

# Structure générale

```text
eCare+
│
├── Application Flutter
│   ├── Models
│   ├── Views
│   ├── Services
│   ├── Widgets
│   ├── Utils
│   └── Routes
│
├── API REST
│
└── PostgreSQL
```

---

# Équipe

**Projet : eCare+**

Application développée dans le cadre d'un projet visant à proposer une solution numérique pour améliorer le suivi des patients atteints de maladies chroniques.

---

# Statut du projet

**Projet en cours de développement**

Les fonctionnalités et l'architecture peuvent évoluer au fur et à mesure de l'avancement du projet.

---

# Licence

Ce projet est développé dans un cadre académique et de compétition.

Toute utilisation, modification ou distribution du projet doit respecter les conditions définies par l'équipe eCare+.
