import 'package:flutter/material.dart';
import 'legal_page.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});
  @override
  Widget build(BuildContext context) => const LegalPage(
    title: 'Politique de confidentialité',
    icon: Icons.privacy_tip_outlined,
    introduction:
        'Cette notice décrit la version connectée de développement eCARE+. Le service utilise un compte patient et un serveur commun aux applications patient et professionnel. Les coordonnées juridiques de l’éditeur et les modalités de prise en charge des demandes restent à compléter avant une ouverture publique. Cette version ne constitue pas un service d’urgence.',
    sections: [
      LegalSection(
        'Données utilisées',
        'Votre nom, vos prénoms, vos coordonnées et votre profil patient sont transmis au serveur lorsque vous vous inscrivez ou enregistrez vos modifications. Le profil peut comprendre votre date de naissance, votre adresse, vos contacts d’urgence et les données médicales que vous choisissez de renseigner. Les constantes, les réponses aux prises, les documents transmis et les messages avec leurs pièces sont conservés par le serveur après confirmation de leur réception. Les erreurs réseau ne sont pas présentées comme une transmission réussie.',
      ),
      LegalSection(
        'Finalités et fonctionnement du suivi',
        'Les données permettent de constituer votre dossier, de consulter l’historique des constantes et d’échanger avec les professionnels qui vous sont affectés. La lecture des données cliniques dépend de votre consentement et des droits contrôlés par le serveur. Les alertes affichées proviennent du serveur ; les seuils de démonstration sont indicatifs et nécessitent une validation clinique. La lecture d’un message ou d’une notification ne vaut pas confirmation de prise d’un médicament.',
      ),
      LegalSection(
        'Consentement aux données de santé',
        'Avant l’accès clinique, vous devez parcourir les conditions d’utilisation et cette politique jusqu’à leur fin, puis confirmer explicitement votre accord au traitement de vos données de santé. Le serveur enregistre la version des documents et l’acceptation. Votre compte dispose d’un dossier personnel utilisable avec votre consentement, sans médecin ni établissement. Un rattachement ultérieur à un professionnel reste facultatif et soumis aux autorisations du serveur.',
      ),
      LegalSection(
        'Conservation sur le serveur et sur l’appareil',
        'Le jeton de connexion reste en mémoire et n’est pas enregistré dans les préférences de l’appareil. Un redémarrage impose une nouvelle connexion. La déconnexion retire les données de la session et demande la révocation du jeton au serveur. Elle ne supprime pas votre dossier ni les données confirmées. Le carnet principal utilise le serveur ; les archives locales par compte restent conservées séparément et leur transmission est volontaire. Les fichiers historiques non attribués ne sont pas associés au prochain utilisateur. La file de réessai reste en mémoire : elle ne survit pas à la fermeture ou à la déconnexion.',
      ),
      LegalSection(
        'Partage, communications et limites',
        'Un document transmis au carnet serveur peut être consulté par les professionnels habilités de votre dossier. Les pièces jointes d’un message sont accessibles aux participants autorisés. Les notes privées restent réservées à leur auteur ; les notes partagées suivent les droits de leur cible. Les copies exportées restent indépendantes d’un retrait du carnet. La photo de profil reste limitée à la session. Les appels nécessitent un fournisseur configuré et votre permission d’accès au microphone ou à la caméra ; aucun enregistrement média n’est prévu par défaut. La réception push/WhatsApp exige un service configuré et les permissions ou accords nécessaires. La montre, les messages vocaux et les rappels système hors ligne restent non intégrés.',
      ),
      LegalSection(
        'Vos choix et vos demandes',
        'Vous pouvez relire ces documents depuis les paramètres, modifier votre profil, gérer vos préférences et fermer votre session. Dans Notifications et données, vous pouvez retirer votre consentement au suivi ou déposer une demande d’effacement. La demande n’annonce pas une suppression immédiate : les obligations de conservation restent à définir avec le responsable du traitement. Le code de référencement administratif n’accorde aucun consentement clinique. Évitez d’importer des informations concernant des tiers sans nécessité. Toute question médicale doit être adressée à votre professionnel et toute urgence doit suivre les moyens habituels de prise en charge.',
      ),
    ],
  );
}
