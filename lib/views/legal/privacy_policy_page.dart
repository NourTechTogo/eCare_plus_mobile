import 'package:flutter/material.dart';
import 'legal_page.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) => const LegalPage(
    title: 'Politique de confidentialité',
    icon: Icons.privacy_tip_outlined,
    introduction:
        'La présente politique explique comment les informations personnelles sont utilisées dans la version actuelle d’eCARE+, application de suivi personnel de santé destinée notamment aux utilisateurs au Togo. Elle accompagne les conditions générales d’utilisation et décrit les données renseignées, leur utilité, leur conservation et les possibilités dont vous disposez pour en garder la maîtrise. Elle distingue les fonctions locales disponibles des services qui nécessiteraient une connexion à un professionnel ou à un serveur.\n\n'
        'Le cadre de référence retenu est la loi togolaise n° 2019-014 du 29 octobre 2019 relative à la protection des données à caractère personnel. Cette notice reste une version de travail : l’identité juridique, l’adresse et le contact de l’éditeur ne sont pas encore arrêtés. Leur absence est signalée afin de ne pas vous présenter un interlocuteur fictif ou un service de traitement des demandes qui ne serait pas opérationnel.',
    sections: [
      LegalSection(
        'Données utilisées',
        'Les informations que vous pouvez saisir comprennent vos nom et prénom, votre adresse e-mail, votre numéro de téléphone et les champs de votre profil. Le parcours d’inscription n’est pas encore relié à un serveur d’authentification. Un indicateur local associé à l’adresse e-mail saisie permet de reconnaître un premier passage dans le parcours de bienvenue ; cet indicateur peut subsister après la fermeture de l’application.\n\n'
            'Les fonctions de suivi utilisent vos valeurs de glycémie, vos mesures de tension, leurs dates, vos rendez-vous et les pathologies sélectionnées. Le carnet contient les fichiers importés et leurs informations de classement. La photo choisie ainsi que les textes, images, documents et enregistrements vocaux ajoutés au chat constituent aussi des informations personnelles. Certaines révèlent votre état de santé et appellent une attention particulière, y compris lorsqu’elles restent sur votre appareil.',
      ),
      LegalSection(
        'Finalités et fonctionnement du suivi',
        'Les mesures servent à afficher votre historique et vos courbes. Les rendez-vous permettent d’organiser votre agenda personnel. Les pathologies, catégories et dates facilitent le classement des documents, tandis que la photo personnalise votre espace. Le contenu du chat permet de consulter les éléments enregistrés dans votre session locale. Ces usages reposent sur les informations que vous choisissez de fournir et sur les fonctions que vous demandez à utiliser.\n\n'
            'Les graphiques ne produisent ni diagnostic, ni prescription, ni décision médicale automatisée. Le carnet n’est pas relié à un système hospitalier et aucune surveillance médicale à distance n’est assurée. Cette version n’exploite pas vos données de santé pour établir un profil publicitaire ou vendre des fichiers de patients. Il est préférable de ne saisir que les informations utiles à votre propre suivi, en évitant d’ajouter des renseignements sur des tiers sans nécessité.',
      ),
      LegalSection(
        'Vos choix et les données de santé',
        'Vous décidez des mesures à enregistrer, des rendez-vous à ajouter et des documents à importer. Une photo n’est pas nécessaire pour lire les écrans de suivi. Lorsqu’un champ est indispensable à une opération, le formulaire signale son absence. Refuser une autorisation du téléphone peut empêcher la fonction correspondante, sans autoriser l’application à rechercher les mêmes informations par un autre moyen.\n\n'
            'L’article 24 de la loi n° 2019-014 encadre les traitements de données de santé et prévoit notamment le consentement parmi leurs conditions de licéité. La case d’acceptation du formulaire porte sur les documents présentés ; elle ne vaut pas autorisation générale de tous les usages futurs de vos informations médicales. L’activation de nouveaux traitements devra s’accompagner d’une information adaptée et, lorsque nécessaire, d’un consentement distinct et des formalités applicables. Cette notice ne présente pas ces démarches comme déjà accomplies.',
      ),
      LegalSection(
        'Photos, documents et autorisations du téléphone',
        'La sélection d’une photo ou d’un document passe par les outils du téléphone lorsque vous demandez l’ajout d’un contenu. Le profil utilise l’image choisie dans la galerie. Le chat permet, selon la fonction sélectionnée, de choisir une photo, d’utiliser la caméra, d’ajouter un fichier ou de lancer un enregistrement vocal. Ces opérations ne signifient pas que l’application parcourt automatiquement toutes vos photos ou tous vos fichiers. Une image peut être redimensionnée ou compressée pour son affichage.\n\n'
            'Vous pouvez annuler une sélection et gérer les autorisations dans les paramètres de votre appareil. Le système ou les outils de sélection peuvent conserver des copies temporaires. Après une interruption sur Android, une récupération technique peut restituer une photo au redémarrage ; ce mécanisme ne constitue pas une sauvegarde générale de votre profil ou de vos conversations. Les documents ajoutés au carnet font, pour leur part, l’objet d’une copie locale destinée à leur consultation ultérieure.',
      ),
      LegalSection(
        'Stockage local et conservation des informations',
        'Les mesures, rendez-vous, notifications, messages et photo affichée sont conservés dans l’état de session. La déconnexion efface cet état et ces éléments ne sont pas restaurés comme un historique permanent après un redémarrage complet. Cette règle ne signifie pas que toute trace technique a disparu du téléphone : des copies temporaires et l’indicateur du parcours de bienvenue peuvent subsister séparément.\n\n'
            'Les documents du carnet, leurs informations de classement et les pathologies sélectionnées restent enregistrés dans l’espace local de l’application après déconnexion. Ils n’ont pas actuellement d’échéance automatique de suppression. Vous pouvez retirer les documents depuis le carnet et modifier vos suivis. Cette version ne fournit pas de sauvegarde distante eCARE+ : une panne, une désinstallation, une suppression des données de l’application ou un changement d’appareil peut entraîner leur perte. Conservez donc séparément les documents nécessaires à vos soins.',
      ),
      LegalSection(
        'Destinataires, export et services extérieurs',
        'Cette version n’envoie pas vos mesures, rendez-vous, conversations, documents ou photo à un serveur eCARE+ ou à un médecin. L’affichage d’un professionnel et l’ajout d’un message ne prouvent pas qu’il a reçu vos informations. Les boutons de connexion sociale ne réalisent pas encore d’authentification auprès de Google ou Facebook. Aucun hébergeur médical distant n’est annoncé pour les données de cette version.\n\n'
            'L’ouverture d’un document peut faire intervenir une autre application du téléphone. Un export crée une copie à l’emplacement choisi, qui peut dépendre d’un service de stockage configuré sur votre appareil. Un lien externe fait intervenir le site et le navigateur concernés. Vérifiez les destinataires et leurs règles avant de leur confier un contenu. Retirer ensuite un document du carnet ne retire ni son fichier d’origine ni les copies déjà créées dans ces autres espaces.',
      ),
      LegalSection(
        'Confidentialité et sécurité de l’appareil',
        'La conservation locale réduit les échanges avec un serveur eCARE+, mais elle ne garantit pas à elle seule la confidentialité des informations. Une personne utilisant votre téléphone déverrouillé ou accédant à vos fichiers exportés peut consulter des données sensibles. Protégez l’accès à votre appareil, installez ses mises à jour et faites attention aux dossiers partagés ainsi qu’aux sauvegardes du système. La déconnexion ne supprime pas le carnet local et ne constitue donc pas une séparation sécurisée entre plusieurs utilisateurs du même téléphone.\n\n'
            'Cette version ne revendique ni chiffrement médical spécifique des documents, ni hébergement certifié, ni audit de sécurité achevé. Elle ne garantit pas la récupération des données après une perte ou un vol. Si vous suspectez une exposition, limitez l’accès à l’appareil et aux copies concernées. Le futur canal de contact de l’éditeur devra permettre de lui signaler un incident ; les mesures de protection et de réponse devront être définies et vérifiées avant l’exploitation d’un service réel.',
      ),
      LegalSection(
        'Vos droits et leur exercice',
        'La loi n° 2019-014 prévoit des droits d’information, d’accès, d’opposition pour motifs légitimes, de rectification et de suppression, dans les conditions qu’elle fixe. Les articles 35, 39, 45 et 46 en précisent notamment le cadre. L’Instance de protection des données à caractère personnel, ou IPDCP, est l’autorité togolaise compétente. Ses informations et modalités de saisine sont accessibles sur son site officiel, ipdcp.tg.\n\n'
            'Vous pouvez consulter vos informations affichées, remplacer votre photo, retirer des documents, modifier vos suivis et effacer l’état de session en vous déconnectant. Ces actions ne remplacent pas un dispositif complet de traitement des demandes et ne suppriment pas les copies extérieures. L’identité et le contact du responsable devront être renseignés pour recevoir vos demandes et y répondre selon les règles applicables. Aucun e-mail fictif n’est proposé en attendant. Ne transmettez pas de pièce d’identité ou de dossier médical à une adresse non vérifiée.',
      ),
      LegalSection(
        'Mineurs et informations concernant un tiers',
        'eCARE+ est conçu comme un espace personnel. Si vous accompagnez un enfant ou une personne qui ne peut pas gérer elle-même ses informations, assurez-vous de disposer de l’autorité ou de l’habilitation nécessaire avant de renseigner ses données. Le carnet local n’est pas actuellement isolé par un compte distant authentifié : l’utilisation successive d’un même téléphone peut rendre des documents accessibles à la personne suivante.\n\n'
            'Cette version ne comporte pas de mécanisme vérifié de consentement parental ou de gestion de dossiers délégués. Elle ne doit donc pas être présentée comme un suivi familial sécurisé à plusieurs comptes. Les informations concernant un proche ou un professionnel doivent rester limitées à un usage légitime. Le seuil d’âge figurant dans une politique étrangère n’est pas repris comme une règle togolaise sans vérification du cadre applicable.',
      ),
      LegalSection(
        'Éditeur, évolution et références de la politique',
        'Le nom légal, l’adresse et l’e-mail de l’éditeur restent à compléter avant l’ouverture du service. Les éventuels prestataires, lieux d’hébergement et modalités des futures fonctions connectées devront aussi être documentés. L’activation d’une synchronisation, d’une transmission médicale ou d’un nouveau destinataire ne peut pas être déduite de cette notice : les informations et choix correspondants devront être présentés au moment utile. La date en tête de page identifie cette rédaction.\n\n'
            'La référence légale de cette politique est la loi togolaise n° 2019-014. Le document « Politique de confidentialité » d’APPLYMAGE Medical a servi de référence pour organiser les thèmes abordés, sans attribuer à eCARE+ ses coordonnées, son hébergeur ou ses engagements. La loi n° 2018-028 concerne les juridictions commerciales ; son rôle éventuel est expliqué dans les conditions générales d’utilisation. Les textes officiels et leurs modifications applicables prévalent sur cette présentation simplifiée.',
      ),
    ],
  );
}
