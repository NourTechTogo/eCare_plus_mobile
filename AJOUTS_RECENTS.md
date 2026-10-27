# Ajouts et corrections récents — Mobile Flutter eCare+

## Phase 1 — patient autonome, 27 octobre 2026

- Accès au suivi avec dossier personnel sans médecin affecté ; authentification et consentement conservés.
- Rattachement présenté comme facultatif dans l'état du dossier et les textes d'aide, sans refonte visuelle ni suppression des appels/messages/articles.
- Déclaration d'un traitement existant depuis Mes traitements ; saisie du médicament, de la dose, des dates et d'une prise quotidienne explicitement en UTC.
- Distinction des déclarations personnelles dans le planning ; brouillon/réessai lié au compte initial et effacé en cas de changement de session.
- 177 tests réussis, 2 réseau optionnels ignorés, analyse sans anomalie ; compilations web/APK réussies et recette réelle du formulaire avec l'API.
- [Bilan et limites de phase 1](docs/refonte/PHASE_1_AUTONOMIE_PATIENT.md).


## Livraison du 26 octobre 2026 : messages vocaux dans la messagerie réelle

- Bouton microphone, minuterie, arrêt, annulation, écoute du brouillon et envoi explicite via la même API que le portail web. Enregistrement WAV mono 16 kHz ; arrêt avant 120 secondes sans envoi automatique.
- Bulles vocales compactes dans le style eCare+ : lecture/pause, durée et progression déplaçable. Chargement authentifié des vocaux reçus, un seul lecteur actif.
- Protection contre les permissions retardées, les changements de compte et les réponses obsolètes ; nettoyage des fichiers et ressources audio. Conservation du brouillon et des références lors d'un réessai.
- Annulation/pause lors de la navigation et du passage en arrière-plan ; microphone réservé aux appels actifs. Le parcours local de démonstration reste compatible.
- 171 tests réussis, 2 tests réseau optionnels ignorés, analyse sans anomalie ; web et APK recompilés. Échange vocal réel avec React vérifié avec microphone synthétique. [Validation et limites](docs/VALIDATION.md).

## Mise à jour graphique des pages annotées — 25 octobre 2026

- Recomposition des cinq pages de Paramètres : traitements, notes des mesures, synchronisation, référencement QR et préférences du compte. Cartes, résumés, champs et commandes utilisent les couleurs et la typographie eCare+.
- Appels audio/vidéo : suppression de l’illustration basse résolution étirée ; identité en initiales, vidéo encadrée, aperçu local limité et commandes regroupées. Le panneau reste fixe en affichage courant et devient défilable avec un texte très agrandi. Les actions API et le média restent raccordés.
- Ajout de constante : grille de types alignée sur écran large, liste déroulante sur petit écran, champs dans une zone défilable, fermeture et bouton d’enregistrement distincts ; en hauteur réduite, l’en-tête devient compact. Retoucher le type déjà sélectionné conserve la valeur saisie.
- Notifications : recherche compacte, grille régulière de catégories repliable, contraste de sélection corrigé.
- Notes liées : éditeur arrondi, actions distinctes et contenu défilable avec prise en compte du clavier.
- Vérification : 145 tests Flutter réussis, 2 optionnels ignorés ; analyse sans anomalie. Cas couverts : 320 pixels avec texte doublé, 633 × 628 et formulaire avec clavier ouvert.


## Dernière livraison : restauration complète et installation finale

- Accueil : retour du carrousel de cartes ; seuls les médecins réellement affectés sont affichés. Profil : grand avatar, champs arrondis et choix des pathologies d’origine. Notifications : recherche, catégories et cartes d’origine. Réinitialisation : style AuthLayout conservant les trois étapes API.
- Médecins, messages, appels audio/vidéo réutilisent les présentations eCare+ existantes et leurs nouvelles actions serveur.
- Un même brouillon conserve sa clé UUID de réessai ; les pièces déjà transmises ne sont pas réenvoyées inutilement. VIDEO active la caméra après le bouton explicite ; refus caméra : poursuite audio avec message.
- APK final installé sur Samsung A55 sous **eCare+ Local** ; ancienne application conservée, portrait maintenu, API 8081 via USB. Aperçu Flutter 5184 reconstruit et actualisé.
- Appels VIDEO puis AUDIO avec portail médecin : acceptation/connexion et flux physiques téléphone → web reçus, vidéo décodée ; fin web vérifiée. Les médias navigateur sont synthétiques pour cette recette, sans enregistrement.
- 134 tests réussis, 2 optionnels ignorés ; analyse Flutter sans anomalie. Bascule avant/arrière et conversion audio → vidéo en cours d’appel encore désactivées. Agenda mobile explicitement personnel/local.

Bilan actuel : [restauration et vérifications](docs/restauration/BILAN.md). Les sections ci-dessous décrivent aussi des étapes historiques antérieures à cette livraison.

État documenté le 25 octobre 2026. Ce fichier concerne l'application patient Flutter, y compris sa prévisualisation navigateur. La compilation Android et la validation sur un téléphone sont des étapes distinctes.

## Connexion et documents

- Session API commune avec le web : JSON, formulaires multipart et téléchargement privé authentifié.
- Isolation des réponses par session et correction des types MIME envoyés.
- Suppression d'un en-tête de requête incompatible avec CORS ; les réponses privées du serveur restent sans cache.
- Carnet de documents raccordé au backend : liste, import PDF/JPEG/PNG, téléchargement/export et retrait logique.
- Conservation des anciennes archives locales par session/patient ; transfert volontaire vers le serveur, sans migration silencieuse ni réattribution des fichiers non associés.
- Information explicite sur le partage des documents déposés avec l'équipe autorisée ; formats et limite annoncés alignés sur le serveur, 5 Mio par défaut.

## Traitements et suivi des prises

- Planning par jour et affichage des prescriptions fournies par le backend.
- Actions pris, reporter ou ignorer, avec contrôle de version, gestion des conflits et date de report.
- Affichage de l'observance calculée côté serveur.
- Route des traitements enregistrée et accès depuis l'accueil et les paramètres.

## Notifications, préférences et QR

- Boîte de notifications serveur du compte, lecture persistée et ouverture de la ressource correspondante.
- Préférences enregistrées sur le serveur.
- Demande d'effacement et retrait du consentement avec confirmation et explication de leurs effets.
- Écran du code temporaire/QR, expiration et régénération manuelle.
- Accès au référencement avant rattachement et depuis l'écran de consentement ; cette opération administrative ne donne pas automatiquement accès aux données cliniques.

## Messages, notes et appels

- Pièces jointes privées PDF/images dans la messagerie et téléchargement authentifié.
- Notes ciblées sur messages, appels, mesures et alertes, avec visibilité explicite.
- Parcours d'appel : création, acceptation/refus, fin, historique et appel entrant au premier plan.
- Intégration du SDK LiveKit ; connexion média après acceptation et action utilisateur, contrôles microphone/caméra et nettoyage des pistes.
- Correction de la reconnexion après déconnexion terminale : nouvelle autorisation et nouvelle salle.
- Arrêt immédiat du média local au clic Terminer, même si la confirmation serveur tarde.
- Permissions Android et descriptions d'usage iOS pour caméra/microphone.

## Réessais et cohérence des données

- File d'opérations en mémoire de session, acquittements partiels et conflits visibles.
- Après une réponse incertaine d'une ancienne route directe, reprise de la même route, du même contenu et de la même référence ; aucune conversion silencieuse vers une nouvelle opération susceptible de créer un doublon.
- Nettoyage à la déconnexion ou au changement de compte.
- Mise à jour des textes d'aide, confidentialité et conditions, version du 25 octobre 2026 partagée avec les parcours d'inscription et consentement.

La file actuelle n'est pas un stockage hors ligne durable : elle est perdue à la fermeture. Les rappels système natifs et l'acquisition depuis une montre restent à réaliser/valider.

## Dépendances et vérifications enregistrées

- Ajout/intégration de `livekit_client` 2.13.1 et `qr_flutter` 4.1.0 ; déclaration directe de `http_parser` 4.1.2 pour les types MIME.
- **122 tests Flutter réussis** dans la recette ; deux tests réseau optionnels ignorés par défaut ne sont pas comptés comme exécutés.
- Test d'adaptateur réseau exécuté séparément contre le backend commun.
- Analyse Flutter, build web et compilation APK Android debug vérifiés lors de la recette précédente.
- Prévisualisation navigateur : connexion, import/téléchargement de documents et vérification de leur présence côté professionnel.

Ces preuves ne valent pas validation de tous les parcours natifs sur téléphone. La rédaction de ce fichier ne relance pas les suites.

## Compilation pour le téléphone local

L'APK demandé pour le téléphone cible `http://127.0.0.1:8081/api/v1` avec :

```powershell
flutter build apk --debug --no-pub --dart-define=API_URL=http://127.0.0.1:8081/api/v1
adb -s <numero-du-telephone> reverse tcp:8081 tcp:8081
adb -s <numero-du-telephone> install -r -t build/app/outputs/flutter-apk/app-debug.apk
```

Le tunnel USB relie le port local du téléphone au backend de l'ordinateur. Le backend et la connexion USB doivent rester actifs. Le manifeste debug autorise déjà HTTP sur la boucle locale ; aucune ouverture du backend sur le réseau local n'est nécessaire.

### Installation à côté de la version existante

À la demande du propriétaire, les compilations Android **debug** utilisent désormais l'identifiant `com.example.ecare_plus_mobile.local`, le nom visible **eCare+ Local** et le suffixe de version `-local`. L'identifiant de la version release reste inchangé. Cette séparation permet de conserver l'ancienne application et ses données malgré la différence de signature. Les données locales des deux applications sont indépendantes ; la nouvelle utilise le backend local commun.

La compilation correspondante est journalisée dans `../.maintenance/integration-clients/android-local-side-by-side-build.log`. Le lancement se fait avec l'activité `com.example.ecare_plus_mobile.local/com.example.ecare_plus_mobile.MainActivity`.

**Compilation spécifique au téléphone réussie le 25 octobre 2026 à 16:18 UTC.** L'APK debug est disponible dans `build/app/outputs/flutter-apk/app-debug.apk`, compilé avec l'adresse locale ci-dessus. Le journal est conservé dans `../.maintenance/integration-clients/android-telephone-build.log`. Il remplace à cet emplacement l'ancien APK destiné à l'émulateur (`10.0.2.2`).

**Installation effectuée le 25 octobre 2026 à 16:28 UTC sur Samsung Galaxy A55 (SM-A556E).** Après autorisation USB, la tentative de mise à jour de l'ancienne application a été refusée pour différence de signature. Le propriétaire a choisi la coexistence : l'APK debug a été recompilé avec l'identifiant distinct décrit ci-dessus, puis installé avec succès. Les deux paquets sont présents ; aucune désinstallation ni suppression des données de l'ancienne application n'a été effectuée.

Lancement Android confirmé (`Status: ok`), processus actif et écran d'accueil de présentation observé. Le backend répond en HTTP 200 sur son OpenAPI ; le tunnel USB `tcp:8081` est actif. La connexion à un compte et les parcours métier complets sur ce téléphone ne sont pas encore vérifiés. Preuve locale : `../.maintenance/integration-clients/telephone-installation.json`.

## Mise à jour : portrait et connexion de développement

- Verrouillage Flutter sur `DeviceOrientation.portraitUp` avant l'affichage de l'application.
- Orientation Android `portrait` imposée dans le manifeste dès le démarrage de l'activité.
- Configuration iOS limitée au portrait pour iPhone/iPad ; compilation et validation iOS non effectuées sur Windows.
- Test du verrouillage ajouté : échec reproduit avant correction, puis six tests ciblés de démarrage/profil réussis après correction.
- Compte patient local simplifié : `p@e.test`. Comptes professionnels du même backend : `m@e.test` et `a@e.test`. Reconnexion nécessaire après changement du mot de passe ; aucune perte des données du compte serveur.
- L'APK portrait est compilé avec la même adresse API USB et le même identifiant `com.example.ecare_plus_mobile.local`, pour mettre à jour la version locale sans désinstaller l'ancienne application.

Mise à jour installée et lancée sur le Samsung A55 le 25 octobre 2026 à 16:37 UTC. Android confirme `requestedOrientation=SCREEN_ORIENTATION_PORTRAIT` pour l'activité locale. Analyse Flutter : aucune anomalie signalée. La preuve de cette mise à jour est conservée dans `.maintenance/integration-clients/telephone-portrait-proof.json` à la racine du workspace ; le journal de compilation est `android-portrait-build.log` dans ce même dossier. Les connexions des trois comptes courts ont été vérifiées par API, et la configuration a été relancée sans création de nouveaux comptes.

## Restauration du design des médecins, messages et appels

À la demande du propriétaire, la présentation des écrans existants reste la référence : aucune nouvelle refonte graphique n'est autorisée par les travaux de raccordement API. Le modèle d'origine a été retrouvé dans l'archive `eCare_plus_mobile-main (2).zip`. Les fichiers de conversation et d'appel de démonstration présents dans le projet correspondaient encore exactement à cette archive.

- **Mes médecins** : rétablissement des cartes arrondies, de la recherche, du filtre de spécialité, du bouton Message et de l'accès au profil/agenda. Les données proviennent uniquement des professionnels affectés au patient ; aucun profil fictif n'est ajouté pour remplir l'écran. Une illustration générique est utilisée quand le serveur ne fournit pas de portrait.
- **Messages** : retour de l'en-tête bleu, de l'avatar, des menus, des bulles bleues/grises et de la barre de saisie arrondie avec émojis et pièces jointes. La prise de photo utilise le sélecteur caméra existant et le même dépôt privé d'image. Les messages et accusés de lecture restent ceux du serveur ; pas d'exemples insérés dans la conversation réelle.
- **Appels** : réutilisation des écrans audio et vidéo d'origine, des avatars et des commandes rondes. Les états serveur, accepter/refuser/terminer, l'historique, les notes et les contrôles LiveKit sont raccordés à cette présentation. Les contrôles média sont actifs après connexion réelle ; l'indisponibilité du fournisseur reste explicite.
- **Fonctions conservées** : transport authentifié, fichiers privés, notes ciblées, brouillon conservé après erreur, réessai stable de création d'appel, reconnexion média et arrêt local immédiat à la fin de l'appel.
- **Affichage** : portrait forcé conservé ; recherche et commandes vérifiées sur petit écran et texte agrandi. Les actions ajoutées peuvent revenir à la ligne/défiler pour éviter les débordements, sans changer la structure visuelle des écrans.

La suite Flutter de cette restauration compte **128 tests réussis**, avec deux tests réseau optionnels ignorés par défaut. Les tests de présentation vérifient aussi le maintien des opérations réelles du backend. Les appels audio/vidéo entre deux appareils restent soumis à la configuration LiveKit mentionnée ci-dessous.

Analyse Flutter sans anomalie ; compilations APK debug et web réussies. La version a été installée et lancée sur le Samsung A55, avec maintien des deux applications et du tunnel USB. La prévisualisation 5184 servait une copie dans `build/integration-web` : ce dossier a été actualisé et son JavaScript correspond désormais à la nouvelle compilation. Recette navigateur contre le vrai backend local : connexion patient, cartes/recherche des médecins affectés, conversation réelle avec pièces jointes, ouverture de l'écran audio et erreur explicite en l'absence de fournisseur ; aucune erreur JavaScript relevée. Les captures des trois écrans ont été inspectées. Preuves locales : `.maintenance/integration-clients/restored-design-proof.json` et `restored-design-browser-proof.json`.

## Services restant à configurer

Les fournisseurs de notifications et LiveKit ne sont pas encore choisis/configurés. La réception réelle de push, les appels audio/vidéo entre deux appareils et les appels en arrière-plan ne sont pas validés. Les interfaces et adaptateurs préparés ne suffisent pas à attester leur fonctionnement réel. La compilation iOS n'a pas été effectuée sur cet environnement Windows.

## Références

- [Bilan commun et limites](docs/integration-clients/BILAN.md)
- [Preuves de vérification](docs/VALIDATION.md)
- [Configuration](docs/integration-clients/CONFIGURATION.md)
- [Ajouts backend](https://github.com/NourTechTogo/eCare_plus_backend/blob/ecare_backend_stable/AJOUTS_RECENTS.md) et [ajouts web](https://github.com/NourTechTogo/eCare_plus_frontend/blob/ecare_frontend_stable/AJOUTS_RECENTS.md)

## Livraison GitHub et retouches demandées — 25 octobre 2026

- Agenda : résumé bleu eCare+, bouton d'ajout explicite, dates triées et repères jour/mois sur les cartes. Il reste un agenda personnel de session, sans réservation médicale distante.
- Notifications : remplacement des huit catégories dispersées par un sélecteur compact ; recherche, filtrage, ouverture et marquage lu conservent les routes serveur existantes. Compteur et actualisation sont réunis sur une ligne.
- Appels audio/vidéo : commandes rondes et bouton de fin circulaire ; aucun bouton de fin ni contrôle média désactivé sur l'écran prêt à appeler. Les commandes média restent disponibles selon l'état réel de connexion.
- Test ajouté : écran de préappel sur 320 px avec texte agrandi, sans faux bouton de raccrochage. Le test de coupure immédiate du média avant une réponse serveur lente reste réussi.
- Validation : analyse Flutter sans anomalie ; suite existante de 145 tests réussis, deux tests réseau optionnels ignorés, puis deux tests ciblés réussis incluant le nouveau cas. Compilations web et APK debug réussies. Recette navigateur : filtre Appels, formulaire de tension à 633/320 px, création et terminaison AUDIO/VIDEO avec l'API locale, sans erreur JavaScript. Captures agenda/notifications/appel inspectées.
- L'APK final est compilé mais n'a pas été réinstallé : le Samsung est actuellement signalé « unauthorized » par ADB.
- Publication séparée sur `ecare_mobile_stable` dans le dépôt mobile. Les contrats, bilans et exemples de configuration sont copiés dans ce dépôt ; aucun dossier backend/frontend, secret, base privée ni fichier compilé n'est inclus.

La validation des médias physiques et les limites iOS/Internet/push sont décrites dans [docs/VALIDATION.md](docs/VALIDATION.md). Les paragraphes historiques « services à configurer » décrivent l'état de leurs étapes ; LiveKit local a depuis été configuré et testé.

## Corrections des annotations appels et conversation — 25 octobre 2026

La référence fournie remplace la disposition précédente : vidéo plein écran avec aperçu local superposé, cinq commandes rondes dans une barre compacte, conversation claire avec bulles ajustées à leur contenu et séparation des jours. Aucun portrait fictif n'est injecté à la place d'un flux distant absent.

- Historique, actualisation et notes de l'appel déplacés dans Options de l’appel (trois points).
- Correction de la coupure du média : Messages ouvre la conversation au-dessus de la route d'appel au lieu de fermer le propriétaire LiveCallRoom. Le bandeau Revenir à l’appel retrouve cette même session ; le bouton téléphone de cette conversation retrouve l'appel existant.
- Le retour depuis un appel actif ouvre aussi cette conversation en conservant le média. La fin explicite arrête toujours localement le média avant la confirmation serveur.
- Conversation : en-tête clair, composeur compact turquoise, bulles entrantes turquoise/sortantes blanches, heures et dates réelles. Les notes d'un message sont accessibles par appui long ; l'information sur les urgences est déplacée dans le menu de conversation.
- Analyse Flutter sans anomalie et 147 tests réussis (2 réseau optionnels ignorés). Compilations web et APK debug réussies.
- Recette contre l'API et LiveKit réels : affichage en 604/360/320 px, vidéo distante et locale avec périphériques de test du navigateur, passage appel → messages → appel et retour sans nouveau jeton de connexion ni requête de fin, menu historique, puis terminaison explicite ; création et terminaison audio. Aucune erreur JavaScript observée. Cette recette ne remplace pas une validation réseau Internet ni iOS.

Le [processus corrigé](docs/MISE_A_JOUR_APPELS_MESSAGES.md) est détaillé dans la documentation. Les captures et journaux restent locaux. Le téléphone a ensuite autorisé le débogage USB : l'APK final a été réinstallé avec succès et l'application eCare+ Local a été lancée sur le profil principal du Samsung. Les tunnels API 8081 et LiveKit 7880/7881 sont rétablis ; l'aperçu 5184 est actualisé.

## Agenda simplifié et notifications compactes avec gestes — 25 octobre 2026

- Agenda : un seul bouton Ajouter une date dans le résumé ; suppression du bouton flottant redondant et texte d'état vide raccourci. L'agenda reste personnel à la session, sans réservation médicale confirmée.
- Notifications : liste compacte inspirée de la référence fournie, recherche repliable, filtre de catégorie, date et indicateur de lecture, onglets Toutes / Non lues / Archivées.
- Glisser à gauche : suppression via DELETE serveur ; glisser à droite : archivage (ou désarchivage depuis les archives). Annuler rétablit l'état approprié au serveur.
- Toucher une ligne : marquer lue et griser la ligne, uniquement après confirmation du serveur. Détail complet accessible par appui long ou menu ; accès à la ressource liée conservé.
- Boîte alimentée par les véritables notifications du compte, y compris celles liées aux alertes ; aucun mélange redondant avec les enregistrements cliniques d'alerte. Les ressources cliniques liées ne sont pas supprimées par ces gestes.
- Petits écrans : masquage temporaire des filtres pendant la saisie avec clavier pour laisser les résultats accessibles. Les confirmations d'anciennes actions ne s'accumulent pas.
- 151 tests Flutter réussis (2 réseau optionnels ignorés), analyse sans anomalie ; recette navigateur/API réussie en 604/360/320 px avec lecture, suppression/annulation, archives/désarchivage, recherche et détail.
- Aperçu 5184 actualisé et APK debug compilé. Le Samsung n'est plus détecté par USB à cette étape : cette nouvelle version n'a pas été réinstallée sur le téléphone.
