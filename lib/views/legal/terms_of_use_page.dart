import 'package:flutter/material.dart';
import 'legal_page.dart';

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});
  @override
  Widget build(BuildContext context) => const LegalPage(
    title: 'Conditions générales d’utilisation',
    icon: Icons.description_outlined,
    introduction:
        'eCARE+ est une application de suivi patient reliée à un serveur commun aux applications patient et professionnel. Ces conditions décrivent la version de développement du 25 octobre 2026. L’identité juridique et les coordonnées de l’éditeur doivent être complétées avant ouverture publique. Le fonctionnement dépend de la disponibilité du serveur et du réseau.',
    sections: [
      LegalSection(
        'Objet de l’application',
        'L’application permet de créer un compte, compléter son profil, transmettre des constantes et documents, déclarer ses traitements personnels, répondre aux prises et échanger avec un professionnel affecté. Une déclaration personnelle ne constitue pas une prescription médicale. Le carnet principal est conservé sur le serveur commun ; les archives locales anciennes sont préservées séparément. Le suivi personnel exige un dossier actif et votre consentement. Il est disponible sans médecin ni établissement. Le rattachement à un professionnel reste facultatif et soumis aux autorisations du serveur. Un code administratif temporaire peut faciliter ce rattachement sans accorder de consentement clinique.',
      ),
      LegalSection(
        'Accès et acceptation des conditions',
        'Vous devez lire ces conditions et la politique de confidentialité jusqu’à la fin avant de cocher la case d’acceptation. Une validation explicite est ensuite enregistrée par le serveur avec la version des documents. Les identifiants sont personnels. La session reste en mémoire et vous devez vous reconnecter après un redémarrage. Ne communiquez pas votre mot de passe à un tiers. La réinitialisation utilise un code envoyé par e-mail puis un jeton de réinitialisation vérifié par le serveur.',
      ),
      LegalSection(
        'Saisie et transmission des informations',
        'Vérifiez vos coordonnées, les valeurs, les unités et la date de vos mesures avant de les envoyer. La glycémie utilise mg/dL ; la tension mmHg ; le poids kg ; la fréquence cardiaque bpm ; la température °C et la saturation %. Le serveur peut refuser une valeur, un compte non autorisé ou un dossier sans consentement. Une erreur laisse la saisie disponible pour correction. Une transmission n’est annoncée comme réussie qu’après la réponse positive du serveur. L’application ne garantit pas une transmission lorsque le réseau est absent.',
      ),
      LegalSection(
        'Messagerie et limites des fonctions',
        'Les messages et leurs pièces sont destinés aux participants habilités de la conversation. L’affichage envoyé signifie réception par le serveur ; lu dépend de la confirmation du destinataire. Aucun délai de réponse médicale n’est garanti. Les appels audio/vidéo exigent un fournisseur configuré et des permissions micro/caméra ; un échec n’est pas présenté comme une communication réussie. Les messages vocaux, la montre et les rappels système hors ligne ne sont pas intégrés. L’agenda personnel ne réserve pas de consultation auprès d’un établissement.',
      ),
      LegalSection(
        'Précautions médicales et urgences',
        'Les graphiques et les alertes facilitent la consultation des données ; ils ne constituent pas un diagnostic ou une prescription. Les seuils de démonstration sont indicatifs et doivent être validés par un professionnel. Ne modifiez pas un traitement à partir d’une seule valeur ou d’une notification. Cette application ne surveille pas votre état en permanence et ne traite pas les urgences. En cas de situation urgente, utilisez immédiatement les moyens habituels de prise en charge sans attendre une réponse dans la messagerie.',
      ),
      LegalSection(
        'Documents, déconnexion et conservation',
        'Les documents du carnet serveur sont accessibles selon les droits du dossier. Les archives locales par compte ne sont transmises que sur votre action. La déconnexion retire les données affichées et demande la révocation de la session sans supprimer les données serveur. Les fichiers exportés restent à l’emplacement choisi et sous votre responsabilité. Le retrait du consentement et la demande d’effacement sont disponibles dans les paramètres ; la demande n’exécute pas une destruction immédiate. Vérifiez la file de synchronisation avant de fermer l’application : ses opérations non confirmées restent uniquement en mémoire.',
      ),
    ],
  );
}
