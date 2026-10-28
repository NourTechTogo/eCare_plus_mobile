# Rapports personnels de consultation - mobile

Livraison locale du 28 octobre 2026. Même backend Spring Boot, aucun changement de design des écrans existants, aucun commit/push.

## Parcours

Paramètres → Mes rapports (également accessible depuis Explorer mon espace dans la page eCare+). Choisir une période civile de 1 à 90 jours et un fuseau IANA explicite (Africa/Lome proposé). Générer une synthèse, la retrouver dans la liste paginée, puis consulter son contenu enregistré. Les nouvelles données n'altèrent pas un ancien rapport ; une nouvelle génération volontaire reçoit une nouvelle référence.

Le détail présente les statistiques calculées par le serveur, les points des séries sans interpolation ni seuil ajouté, les valeurs consultables, traitements et horaires, réponses aux prises, alertes avec capture disponible, agenda et avertissements. Les dates d'événement de l'écran sont explicitement affichées en UTC ; la période et les jours sans saisie sont ceux calculés dans le fuseau du rapport par le serveur. Aucun calcul de diagnostic ni d'observance ajouté.

Le module est accessible sans médecin/structure, avec dossier personnel et consentement actif. Les couleurs, polices Poppins, CarePage/CareCard et entrées de paramètres existantes sont réutilisées ; la navigation principale et les messages/appels restent inchangés.

## PDF et copie dans le carnet

- Téléchargement privé via Bearer, sans token dans l'URL, validation de la signature et fin PDF, borne 16 Mio. Sélecteur de fichiers existant sur Android/desktop ; téléchargement navigateur dans la version web Flutter. Une annulation native n'annonce pas un fichier enregistré. Nettoyage du fichier intermédiaire iOS prévu par le mécanisme existant, mais recette iOS non réalisée.
- « Déposer une copie dans mon carnet » demande une confirmation indiquant l'accès des professionnels autorisés selon affectation/consentement. Cette action utilise le dépôt documentaire existant : COMPTE_RENDU, date de génération en UTC, nom PDF propre au rapport, limite 5 Mio. Le JSON personnel d'origine reste privé ; générer/télécharger ne transmet rien au médecin.
- Un envoi incertain conserve les octets, la date et sa référence pendant la durée de l'écran/session pour réessayer sans changer de contenu. Un succès est annoncé uniquement après identifiant de document confirmé. Le carnet est rechargé après le dépôt.
- Une nouvelle action volontaire après avoir quitté l'écran ou redémarré peut créer une nouvelle copie. Ce module ne constitue pas une file hors connexion durable et ne déduplique pas globalement toutes les copies de rapports.
- En cas de changement/expiration de session ou retrait du consentement, les données et octets transitoires sont purgés ; une réponse tardive ne s'affiche pas et ne déclenche pas de dépôt/téléchargement sur le compte suivant.

## Contrats utilisés

POST /api/v1/mobile/me/rapports-consultation (sourceRef UUID, du, au, fuseau) ; GET collection paginée, GET /{id}, GET /{id}/pdf. POST /api/v1/mobile/me/documents multipart pour une copie confirmée. Aucune nouvelle route ou permission backend.

## Fichiers

services/consultation_reports_api.dart ; views/reports/consultation_reports_page.dart et consultation_report_detail.dart ; main.dart, routes/app_routes.dart et entrées paramètres/guide. Tests de contrat et widgets consultation_reports_*.

## Validation

Voir [le bilan daté](../VALIDATION.md). L'APK debug local utilise API_URL=http://127.0.0.1:8081/api/v1 ; sur un téléphone relié par USB, le port doit être redirigé avec adb reverse tcp:8081 tcp:8081. L'installation et le sélecteur système sur téléphone ne sont pas validés dans ce lot. Les avertissements Gradle/AGP/Kotlin existants sont conservés dans les journaux ; aucune montée de version non nécessaire à ce lot.
