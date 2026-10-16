import 'package:flutter/material.dart';
import 'legal_page.dart';

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

  @override
  Widget build(BuildContext context) => const LegalPage(
    title: 'Conditions générales d’utilisation',
    icon: Icons.description_outlined,
    introduction:
        'Les présentes conditions générales d’utilisation définissent le cadre d’usage de la version actuelle d’eCARE+, application permettant d’organiser un suivi personnel de santé, un agenda et un carnet de documents. Elles expliquent la portée des fonctions accessibles, les précautions à prendre et les responsabilités liées aux informations renseignées. Elles se lisent avec la politique de confidentialité, qui décrit plus précisément l’utilisation et la conservation des données.\n\n'
        'Le cadre retenu est celui du Togo, notamment la loi n° 2019-014 du 29 octobre 2019 pour les données personnelles et, pour les litiges relevant de son champ, la loi n° 2018-028 du 10 décembre 2018 instituant les juridictions commerciales, dans sa rédaction applicable. L’application reste en développement. L’identité juridique, l’adresse et le contact de l’éditeur restent à compléter avant l’ouverture d’un service réel.',
    sections: [
      LegalSection(
        'Objet de l’application',
        'eCARE+ propose un espace pour enregistrer vos constantes, consulter leur évolution, préparer votre agenda et classer vos documents médicaux. Vous pouvez aussi parcourir des informations, consulter des fiches de médecins et essayer les interfaces de messagerie ou d’appel. L’objectif est de vous aider à retrouver vos propres informations au quotidien, sans remplacer vos documents originaux ni les explications d’un professionnel.\n\n'
            'Les fonctions correspondent à l’état actuel de l’application. Le carnet fonctionne sur l’appareil, tandis que les mesures, rendez-vous et conversations reposent sur votre session. La présence d’un écran de connexion, d’un nom de médecin ou d’un bouton d’appel ne signifie pas qu’un compte sécurisé, une réservation ou une relation de soins ont été établis à distance. Distinguez toujours les éléments saisis dans votre espace de ceux effectivement confirmés par un professionnel.',
      ),
      LegalSection(
        'Accès et acceptation des conditions',
        'Vous pouvez lire ces conditions et la politique de confidentialité depuis l’inscription et les paramètres. Leur ouverture ne coche pas la case d’acceptation à votre place : une action explicite est requise pour poursuivre le formulaire. Vous devez disposer des autorisations nécessaires pour utiliser le téléphone et les fichiers ajoutés. Une personne agissant pour un tiers doit être habilitée à le faire et tenir compte du caractère sensible des informations concernées.\n\n'
            'Les formulaires d’inscription et de connexion ne sont pas encore reliés à un service distant de gestion des comptes. Une confirmation dans le parcours ne vaut donc pas création d’un compte médical authentifié ou vérification de votre identité. Les conditions d’un éventuel service connecté, d’une prestation payante ou d’un traitement supplémentaire devront être présentées avant leur utilisation. Elles ne sont pas acceptées par anticipation au moyen de ces seules conditions.',
      ),
      LegalSection(
        'Mesures, graphiques et limites médicales',
        'Vérifiez les valeurs, les unités et les dates avant d’enregistrer une mesure. Une erreur de saisie peut modifier une courbe. Les graphiques reflètent les données disponibles et peuvent être incomplets, notamment après une déconnexion ou un redémarrage complet. Ils ne constituent pas un résultat de laboratoire, une validation clinique ou une interprétation de votre état de santé. Les articles d’information ne prennent pas en compte l’ensemble de votre situation personnelle.\n\n'
            'N’utilisez pas l’application pour décider seul d’un diagnostic, modifier une prescription ou interrompre un traitement. Toute question sur une valeur ou une prise en charge doit être discutée avec un professionnel qualifié. eCARE+ ne surveille pas vos constantes en permanence et ne fournit pas de service d’urgence. Si votre situation nécessite une aide immédiate, adressez-vous à une structure de soins ou aux services d’urgence par les moyens habituels, sans attendre une réponse dans l’application.',
      ),
      LegalSection(
        'Agenda, rappels et contact avec un médecin',
        'Un rendez-vous enregistré dans eCARE+ sert à organiser votre agenda personnel. Il n’envoie pas de réservation au cabinet et ne garantit pas la disponibilité du professionnel. Confirmez directement la date et l’heure avec le médecin ou l’établissement. Les rappels dépendent des fonctions disponibles et de votre session ; ils ne garantissent pas une alarme du téléphone. Pour un événement important, prévoyez également un moyen de rappel indépendant.\n\n'
            'Les liens externes ouvrent des services tiers qui appliquent leurs propres règles. Les interfaces de chat et d’appel ne mettent pas en place une téléconsultation avec un professionnel distant dans cette version. Les textes, pièces jointes et messages vocaux ajoutés au chat restent dans le fonctionnement local décrit par la politique de confidentialité. Une animation d’appel ou une interface vidéo ne suffit pas à établir qu’un médecin a été joint ou qu’un acte médical a eu lieu.',
      ),
      LegalSection(
        'Carnet médical et gestion des documents',
        'Importez uniquement les documents que vous êtes autorisé à détenir et à utiliser. Vous pouvez leur associer un nom, une catégorie, une date et des suivis. Vérifiez le fichier choisi, notamment lorsqu’il contient des informations sur plusieurs personnes. Le classement facilite la recherche ; il ne certifie ni l’authenticité, ni l’actualité, ni la validité médicale des documents. Conservez les originaux utiles à votre prise en charge.\n\n'
            'L’importation crée une copie locale. L’ouverture peut utiliser une autre application du téléphone et l’export crée une copie à la destination choisie. Retirer un document du carnet supprime l’entrée et la copie qu’il gère, mais pas le fichier d’origine ou les copies exportées. Vérifiez les personnes ayant accès à ces emplacements. Le carnet ne constitue ni un archivage médical garanti ni une sauvegarde distante assurant la récupération automatique de vos documents sur un nouvel appareil.',
      ),
      LegalSection(
        'Utilisation loyale et respect des autres personnes',
        'Renseignez des informations aussi exactes que possible et respectez les droits des personnes concernées. N’utilisez pas le nom ou la photo d’un tiers pour vous faire passer pour lui et n’importez pas un dossier auquel vous n’avez pas le droit d’accéder. Les textes, images et fichiers doivent rester liés à un usage légitime. Un contenu frauduleux, injurieux ou portant atteinte à la vie privée ne devient pas autorisé parce qu’il est ajouté dans un espace personnel.\n\n'
            'Abstenez-vous de contourner les protections de l’appareil, de tenter d’accéder aux données d’un autre utilisateur ou de perturber le logiciel. Sur un téléphone partagé, la déconnexion ne sépare pas les documents du carnet entre plusieurs personnes. Vérifiez ce qui reste consultable avant de prêter l’appareil. Le suivi d’un mineur ou d’une personne représentée suppose une habilitation adaptée ; cette version ne propose pas de gestion vérifiée de plusieurs dossiers délégués.',
      ),
      LegalSection(
        'Données personnelles et confidentialité',
        'La politique de confidentialité détaille les données manipulées, leur utilité et leur conservation. Les mesures, rendez-vous, messages et photo affichée sont effacés de l’état de session à la déconnexion et ne sont pas restaurés comme un historique permanent après un redémarrage complet. Les documents et pathologies choisis restent sur le téléphone. Des copies temporaires et un indicateur du parcours de bienvenue peuvent subsister séparément : l’effacement de la session ne signifie donc pas celui de toutes les données de l’appareil.\n\n'
            'La loi n° 2019-014 constitue le cadre de référence pour les données personnelles. L’acceptation des présentes conditions ne fait pas renoncer aux droits qu’elle prévoit et n’autorise pas la vente de vos informations médicales ou leur transmission à tout nouveau destinataire. L’identité et le contact du responsable doivent encore être renseignés pour recevoir les demandes. Les possibilités de gestion locale et le rôle de l’IPDCP sont présentés dans la politique de confidentialité.',
      ),
      LegalSection(
        'Propriété intellectuelle et contenus personnels',
        'L’accès à l’application vous permet d’utiliser ses fonctions pour les usages décrits ici. Il ne transfère pas les droits éventuellement détenus sur le logiciel, les marques, les éléments graphiques ou les contenus éditoriaux. Leur réutilisation doit respecter les autorisations et licences applicables, y compris lorsqu’un composant provient d’un tiers. La consultation d’un article ou d’une fiche n’accorde pas une autorisation générale de publication ou d’exploitation commerciale de son contenu.\n\n'
            'Vous conservez les droits que vous détenez sur vos propres textes, photos et documents. Leur importation locale sert à permettre l’affichage, le classement ou la lecture demandés ; elle n’est pas présentée comme une cession de propriété à eCARE+. Assurez-vous d’être autorisé à utiliser les informations concernant un tiers. Toute future publication ou transmission distante devra préciser les destinataires et les autorisations nécessaires avant son activation.',
      ),
      LegalSection(
        'Disponibilité et responsabilités',
        'Le fonctionnement dépend du téléphone, de son espace disponible et des applications utilisées pour lire ou sélectionner les fichiers. Des fonctions peuvent être modifiées, interrompues ou indisponibles pendant le développement. Les liens externes dépendent des services concernés. Aucune disponibilité continue, récupération automatique ou conservation permanente n’est annoncée pour cette version. Conservez un moyen indépendant de retrouver les informations indispensables à vos soins ou à vos rendez-vous.\n\n'
            'Tenez compte des limites décrites et vérifiez les informations saisies. Ces précautions ne constituent pas une exclusion générale de responsabilité de l’éditeur et ne suppriment aucune obligation impérative prévue par le droit applicable. Les responsabilités s’apprécient selon les faits et les fonctions réellement proposées. Une évolution vers un service connecté nécessitera des conditions adaptées, notamment sur l’identification des intervenants, la sécurité et les engagements effectifs de disponibilité.',
      ),
      LegalSection(
        'Arrêt de l’utilisation et évolution du service',
        'Vous pouvez cesser d’utiliser eCARE+ et vous déconnecter. Avant une désinstallation ou une suppression des données de l’application, conservez séparément les documents à garder. Les copies exportées ou confiées à d’autres applications restent dans leurs emplacements respectifs. L’arrêt de l’utilisation ne vaut pas retrait de toutes ces copies ni demande adressée à l’éditeur. Aucun compte distant ne permet actuellement une suppression centralisée des informations.\n\n'
            'Les conditions peuvent être révisées pour refléter une évolution du logiciel ou du droit applicable. La date en tête de page identifie la rédaction affichée. Une modification substantielle devra être portée à votre connaissance de manière adaptée avant son application et, si nécessaire, faire l’objet d’une nouvelle acceptation. Conserver un document dans le carnet ne vaut pas accord pour une utilisation supplémentaire de son contenu.',
      ),
      LegalSection(
        'Droit applicable et règlement des différends',
        'Ces conditions sont rédigées dans le cadre juridique togolais, sous réserve des règles impératives applicables à une situation particulière. Une solution amiable pourra être recherchée par les coordonnées de l’éditeur, lorsqu’elles auront été renseignées. Cette possibilité ne fait pas renoncer au droit de saisir une autorité compétente et ne crée pas de démarche préalable obligatoire. Les questions relatives aux données peuvent notamment relever de l’IPDCP dans son domaine de compétence.\n\n'
            'La loi n° 2018-028 du 10 décembre 2018 institue les juridictions commerciales ; elle n’est pas une loi de protection des données. Elle ne peut intervenir que pour un différend relevant de ces juridictions, en tenant compte de sa rédaction et des modifications en vigueur. Ces conditions ne désignent donc pas automatiquement un tribunal de commerce pour tout litige impliquant un patient. La juridiction compétente dépend de la nature du différend et des règles applicables, sans clause d’exclusivité ajoutée au détriment des protections légales de l’utilisateur.',
      ),
      LegalSection(
        'Identification de l’éditeur et version du document',
        'Le nom légal, l’adresse et l’e-mail de l’éditeur d’eCARE+ restent à compléter. Aucun tiers cité comme source documentaire ne doit être considéré comme l’éditeur, l’hébergeur ou le support de l’application. Les coordonnées d’un autre site ne peuvent pas être utilisées pour exercer des droits auprès d’eCARE+. Ces informations devront être publiées avant l’ouverture du service, avec les modalités concrètes de réponse aux demandes et les mentions correspondant aux fonctions réellement déployées.\n\n'
            'Ce document développe les conditions de la phase actuelle sans annoncer de certification médicale, d’agrément de l’IPDCP ou de validation juridique déjà obtenus. Les références sont la loi n° 2019-014 pour les données personnelles et la loi n° 2018-028 pour les seules questions de compétence commerciale pertinentes. Leurs modifications applicables devront être prises en compte lors de la validation définitive, sans limiter les droits impératifs de l’utilisateur.',
      ),
    ],
  );
}
