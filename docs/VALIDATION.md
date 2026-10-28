# Validation et limites des livraisons eCare+

## Publication de l’agenda — 28 octobre 2026

Le lot agenda personnel et calendrier est regroupé sur `ecare_mobile_autonomie_rapports`, dans le dépôt mobile uniquement, sans fusion dans main. Il comprend la persistance via le backend commun, les commandes versionnées et idempotentes, les rappels enregistrés, l’historique des annulations, le calendrier mensuel et son intégration au formulaire. Les mentions « local / non publié / aucun push » des entrées précédentes décrivent l’état avant cette publication.

## 28 octobre 2026 — calendrier mensuel eCare+

- Analyse finale sans anomalie ; **201 tests réussis, 2 réseau optionnels ignorés, aucun échec**. Nouveaux tests : grille et libellés français, sélection et repères serveur, changement d’année et bornes, 320 px avec texte à 200 %, filtrage par jour, date préremplie et sélection conservée lors d’une actualisation.
- Revue indépendante : absence d’action sémantique sur les dates reproduite RED, correction onTap et vérification GREEN. La régression à 200 % a aussi révélé une hauteur insuffisante des numéros ; ils restent maintenant sur une ligne dans une zone contrainte, avec libellé accessible complet. Tests complets repassés après correction. Pas de recette TalkBack/VoiceOver sur téléphone physique dans ce lot.
- Web release et APK debug locaux recompilés. Les avertissements de maintenance AGP/Kotlin préexistants ne bloquent pas la compilation ; l’APK n’est pas installé dans ce lot.
- Recette réelle via navigateur : calendrier alimenté par un compte fictif autonome, sélection des jours, changement de mois et retour à aujourd’hui, préremplissage de date, création 201, reconnexion persistante, annulation 200 et historique. Captures 320/390/605 px inspectées ; aucune erreur de console ou de page.
- Premier jour présenté : premier jour actif à partir d’aujourd’hui, horaires passés du jour compris, sinon dernière date active passée ou aujourd’hui si vide. Une sélection manuelle est conservée lors des rechargements. Les filtres portent sur le jour sélectionné ; une annulation ne supprime pas le rendez-vous de l’historique.
- API, droits et confidentialité inchangés. Le calendrier représente l’agenda personnel, pas des disponibilités publiées ni une réservation auprès d’un professionnel. Aucun push supplémentaire.

## 28 octobre 2026 — agenda personnel connecté

- Analyse Flutter finale : aucune anomalie. Suite complète finale : **197 tests réussis, 2 tests réseau optionnels ignorés, aucun échec**. Contrats de pagination/UUID/version, annulation incertaine sans retrait optimiste, reprise identique, lien de notification, garde de session et affichage 320 px avec texte à 1,6 couverts.
- Revue indépendante : formulaire visible après retrait de consentement, validation Unicode non gérée et bornes de date reproduits RED puis corrigés GREEN. Les trois corrections sont incluses dans la suite finale. Un libellé de test de fiche médecin a été adapté à « Ajouter à mon agenda » et à la garde de connexion.
- Compilations finales web release et APK debug réussies. API locale : http://127.0.0.1:8081/api/v1. APK : build/app/outputs/flutter-apk/app-debug.apk ; son utilisation sur téléphone nécessite une liaison au backend (par exemple adb reverse tcp:8081 tcp:8081). Pas d’installation ni de recette physique Android/iOS dans ce lot. Avertissements AGP/Kotlin préexistants conservés.
- Recette finale Playwright / Edge avec un compte fictif autonome : création 201 avec rappel stocké, modification 200, nouvelle connexion et date retrouvée, annulation 200 puis historique retrouvé. Captures relues à 320, 390 et 605 px ; aucune erreur de console ou de page. Le lien de notification est couvert par les tests widgets ; le déclenchement effectif d’un rappel en temps réel n’a pas été attendu dans cette recette.
- Le push/SMS externe, le fonctionnement hors connexion durable et les changements d’heure sur téléphone réel restent des recettes/lots distincts. Les rappels publiés dans l’application ne sont pas présentés comme des notifications externes reçues.
- Travail local sur ecare_mobile_autonomie_rapports ; aucun push supplémentaire. Backend et frontend web inchangés.

## Publication sur la nouvelle branche - 28 octobre 2026

Contenu regroupé sur `ecare_mobile_autonomie_rapports`, sans fusion dans main. Vérification prépublication : 186 tests réussis, 2 optionnels ignorés ; aucun échec. Voir [le bilan de publication](PUBLICATION_2026-10-28.md). Les mentions « travail local / aucun push » des entrées antérieures décrivent leur état avant cette publication.

## 28 octobre 2026 - rapports personnels et PDF

- Flutter analyze : aucune anomalie. Suite complète : **186 tests réussis, 2 tests réseau optionnels ignorés**, aucun échec. Les 9 nouveaux tests couvrent contrat, dates civiles/borne, réessai stable puis nouvelle génération, PDF invalide, retrait du consentement/changement de session, réponse tardive, confirmation annulée et petit écran 320 px avec texte agrandi à 1,4 et graphique renseigné.
- Revue indépendante : conservation indue de la référence après génération confirmée détectée, test RED puis correction GREEN ; la référence reste conservée uniquement pour le réessai incertain. Relecture sans P1/P2 restant identifié. Le test avec graphique a aussi révélé un effet Ink masqué dans la carte ; ajout du Material approprié, suite complète repassée.
- Compilations web release et APK debug local réussies. L'APK est build/app/outputs/flutter-apk/app-debug.apk. Avertissements de maintenance AGP/Kotlin existants, sans montée de version dans ce lot. Pas d'installation ni de recette du sélecteur système sur téléphone/iOS dans ce lot.
- Recette Playwright sur l'API réelle : patient fictif affecté, deux mesures, génération 201 et moyenne 130, vrai PDF téléchargé, confirmation de dépôt annulable, copie COMPTE_RENDU déposée 201 puis téléchargée par le médecin autorisé dans le web. Comparaison des deux PDF identique octet par octet. Cas patient autonome sans médecin/structure également généré en 201, sans données inventées.
- Écrans Flutter contrôlés à 320/390/605 px ; captures relues, boutons actifs hors transfert, développement de la liste des valeurs vérifié après la dernière compilation. Aucun échec de requête ni erreur de page/console sur le parcours de consultation final. Browser plugin absent dans cette session : runtime Playwright/Edge existant utilisé, aucune dépendance navigateur ajoutée.
- Serveurs locaux laissés disponibles : Flutter 5184 et API commune 8081. Fichiers, captures, comptes fictifs, journaux et secrets de recette restent hors des dépôts. Aucun changement backend, commit ou push.

[Parcours, contrats et limites](refonte/RAPPORTS_CONSULTATION.md).

## Phase 1 — autonomie patient, 27 octobre 2026

- Backend : 186 tests validés, aucun échec, erreur ou test ignoré dans les derniers rapports de chaque classe. La suite complète PostgreSQL/H2 a été exécutée ; après adaptation de l'ancienne attente « nouveau compte sans dossier », les trois scénarios HTTP de cette classe ont été rejoués avec succès via `mvnw -o -Dtest=BackendParcoursCompletTests verify`. Aucun code de production n'a changé entre ces deux dernières exécutions.
- La migration PostgreSQL V32 est vérifiée sur base existante V31 : conservation des dossiers institutionnels et des affectations, création des espaces personnels et unicité du dossier personnel actif. Les tests de schéma, sauvegarde/restauration et concurrence restent inclus.
- Mobile : 177 tests réussis, 2 tests réseau optionnels ignorés ; analyse sans anomalie. Compilation web et APK Android debug réussies. Les outils Android signalent des versions Gradle/AGP/Kotlin à mettre à jour ultérieurement ; cette livraison n'effectue pas cette migration d'outillage.
- Portail web inchangé : 41 tests réussis, 1 test réseau optionnel ignoré, compilation réussie. Vite signale toujours la taille de certains bundles.
- Serveur local persistant : inscription fictive sans médecin, dossier personnel, tension/glycémie, réessais idempotents, traitement déclaré, confirmation/observance, refus d'accès croisés et reconnexion avec conservation des données vérifiés. Le médecin conserve l'accès à son patient affecté.
- Flutter compilé : connexion sans affectation, planning personnel, déclaration réellement envoyée par le formulaire (HTTP 201), historique retrouvé dans une nouvelle session navigateur et affichage à 320/390 px vérifiés sans erreur de page.
- Régressions de confidentialité : les mesures privées ne participent pas aux alertes institutionnelles ; les médicaments des déclarations personnelles ne peuvent pas être réutilisés par un professionnel ; un brouillon ne peut pas être envoyé sous un compte remplaçant la session initiale.

La base H2 locale a été sauvegardée avant adaptation et redémarrage. Les tests utilisent uniquement des données fictives. La recette Android physique/iOS de cette phase, les notifications externes et le hors connexion durable restent à réaliser. Les détails de périmètre et fichiers sont dans [le bilan de phase 1](refonte/PHASE_1_AUTONOMIE_PATIENT.md).


## Validation des messages vocaux — 26 octobre 2026

- Backend : 171 tests réussis, 0 échec et 0 ignoré, avec PostgreSQL 18.6 dédié et migrations V1 à V31.
- Mobile : 171 tests réussis, 2 tests réseau optionnels ignorés ; `flutter analyze` sans anomalie ; compilations Flutter web et APK Android debug réussies.
- Web : 41 tests réussis, 1 test réseau optionnel ignoré ; lint et compilation TypeScript/Vite réussis. Vite signale encore la taille de certains bundles.
- Recette réelle locale avec microphone synthétique : capture et annulation sans envoi sur chaque client, envoi web vers Flutter puis Flutter vers web, accès privé, durée calculée par le serveur, lecture/pause et déplacement de lecture. Contrôles visuels Flutter à 320, 360 et 604 px, web à 390 et 1280 px ; aucun débordement horizontal web constaté.
- Les tests de régression couvrent les permissions retardées, l'arrêt à la durée maximale sans envoi, les réessais, les changements de session et la concurrence entre lecteurs. Les contrôles backend refusent aussi les WAV falsifiés, trop courts, trop longs ou tronqués.

Ces essais utilisent des sons synthétiques et ne captent pas de conversation personnelle. Le microphone et la lecture sur téléphone physique Android et sur iOS restent à vérifier pour cette livraison vocale ; le Samsung n'était pas détecté par USB au contrôle final. L'APK est compilé, son installation physique n'est donc pas confirmée. Les limites historiques relatives aux fournisseurs de notifications, aux appels Internet TLS/TURN et aux réservations restent applicables.

Cette branche conserve les changements des travaux successifs du workspace eCare+.
Les journaux techniques, captures, bases et fichiers privés restent locaux et ne sont pas publiés.

- Backend : dernière recette complète avant publication, 167 tests réussis, dont les tests de migrations PostgreSQL 18.6 (V1 à V29).
- Web : 29 tests réussis, un test réseau optionnel ignoré ; compilation TypeScript/Vite et lint réussis. La recette navigateur précédente couvre les sept onglets patient de 320 à 1440 px.
- Mobile : 145 tests existants réussis (2 tests réseau optionnels ignorés), puis un test de régression ajouté pour les commandes de préappel. Portrait imposé ; backend commun pour les données de suivi et la messagerie.
- Appels : transport LiveKit local vérifié, avec médias synthétiques entre navigateurs et émission audio/vidéo du Samsung vers le navigateur. Cela ne valide pas tous les appareils ni les réseaux Internet.

## Limites explicites

Le push externe attend un fournisseur. Les tests iOS et les appels sur Internet (TLS/TURN, arrière-plan) restent à réaliser. L'agenda personnel mobile ne constitue pas une réservation médicale. Les interfaces de démonstration historiques ne prouvent pas l'existence d'un service réel. Les bilans historiques gardent leur date et doivent être lus avec ce document.

## Rejouer les contrôles

Backend : Java 21, `./mvnw test` depuis `backend_ecare_plus`. Les tests PostgreSQL nécessitent une instance dédiée et les variables ECARE_TEST_POSTGRES_URL, ECARE_TEST_POSTGRES_USER, ECARE_TEST_POSTGRES_PASSWORD.
Web : `npm ci`, `npm test`, `npm run lint`, `npm run build`.
Mobile : `flutter pub get`, `flutter analyze`, `flutter test`, puis compilation avec `--dart-define=API_URL=...`.

## Mise à jour finale des gestes de notification

Backend : 169 tests réussis, aucun ignoré, avec PostgreSQL 18.6 et migration V30.
Mobile : 151 tests réussis, 2 tests réseau optionnels ignorés ; analyse sans anomalie.
Recette navigateur avec l'API réelle sur 604/360/320 px : toucher pour lecture, gauche pour supprimer, Annuler pour restaurer, droite pour archiver, onglet Archivées et désarchivage, catégorie/recherche/détail. Aucune erreur JavaScript observée.
