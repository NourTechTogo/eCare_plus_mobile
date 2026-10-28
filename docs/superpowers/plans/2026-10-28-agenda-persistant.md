# Agenda personnel persistant dans Flutter

> Exécution inline avec superpowers:executing-plans ; tests avant code, une revue ciblée finale.

**Goal:** Raccorder l'agenda personnel aux services déjà livrés, conserver les dates après reconnexion et permettre création/modification/annulation avec rappels réellement enregistrés.

**Architecture:** API personnelle /mobile/me/rendez-vous, références UUID conservées lors des réessais, version serveur pour modifier/annuler. Modèle et adaptateur dédiés ; état de page limité à une session, sans agenda métier parallèle en mémoire dans CareData. Le portail professionnel et ses rendez-vous restent séparés : aucun accès implicite à l'agenda personnel.

**Tech Stack:** Flutter, Provider, http et uuid déjà disponibles ; backend et frontend inchangés. Conserver CarePage, CareSummary, CareCard, AppDecor, Poppins, couleurs et navigation eCare+.

**Spec:** Suite de la fiabilité du suivi et des contrats backend PHASE_2_BACKEND_AGENDA/PHASE_3_BACKEND_RAPPELS_TRAITEMENTS. L'utilisateur demande l'étape suivante et une démonstration, en insistant sur la conservation du style visuel.

## Décisions

- Afficher et saisir les dates dans l'heure de l'appareil, avec décalage UTC explicite à la date choisie. Envoyer l'instant UTC et fuseau UTC au serveur, sans prétendre convertir un fuseau IANA arbitraire sans bibliothèque adaptée. Conserver exactement l'instant initial lors d'une modification sans changement de date/heure. Refuser une heure locale normalisée silencieusement lors d'un saut d'heure.
- Formulaire de même style, motif, professionnel libre facultatif, lieu/commentaire et rappel. Il s'agit d'un agenda personnel, pas d'une disponibilité publiée ou d'une réservation médicale.
- Réessai incertain : même commande, date et référence ; désactiver la modification des champs tant que son issue est incertaine. Une annulation est logique et reste dans l'historique. Un conflit 409 invite à recharger, sans écrasement silencieux.
- Rappels : lire /mobile/me/rappels et distinguer PLANIFIE, ENVOYE (publication dans l'application), LU, ECHEC, ANNULE, TERMINE. Ne pas présenter une échéance comme une livraison push/SMS ou une notification système hors ligne.
- Une réponse tardive, un changement de compte ou un retrait de consentement ne doit pas réafficher ni transmettre les données précédentes. Recharger au retour de l'application et quand l'onglet redevient actif ; paginer les données autorisées.
- Ce lot ne remplace pas la file hors connexion durable. Les commandes incertaines sont retenues pendant l'écran/session ; l'état confirmé reste durable sur le serveur. Préserver les nouveaux travaux localement pour démonstration, sans publication supplémentaire automatique.

## Tâches

- [x] Tests de contrat modèle/adaptateur : dates, références, versions, rappels, pagination et isolation de session.
- [x] API/modèles dédiés et formulaire réel dans le style existant ; supprimer l'ancien stockage local parallèle de rendez-vous.
- [x] Agenda connecté : liste/historique, création, édition, annulation confirmée, conflits/réessais, statut des rappels et rafraîchissement de l'onglet.
- [x] Relier les notifications RENDEZ_VOUS_PERSONNEL à leur événement et garder les gestes/présentation de boîte existants ; mettre à jour les textes « agenda pour la session ».
- [x] Tests widgets (petit écran/texte agrandi, succès seulement après accusé, consentement/session), régressions complètes, analyse et compilation.
- [x] Revue, recette réelle sans médecin, reconnexion et démonstration dans le navigateur ; captures et bilans Markdown datés.

## Registre

Ruling : rester sur les trois dossiers actuels, dont les versions précédentes sont publiées et les arbres propres ; aucun worktree parallèle nécessaire pour cette adaptation de l'application locale. Aucun historique Git n'est réécrit.

Ruling : ne pas modifier le web pour afficher l'agenda personnel. Il est privé par contrat ; sa présence dans la synthèse PDF relève du choix de copie déjà livré au patient.


## Avancement vérifié

- API RED (fichier manquant), puis GREEN : cinq tests de contrat, pagination, références immuables, versions et garde de compte.
- Widgets RED sur l’ancien agenda en mémoire, puis branchement effectif à l’API. Le test 320 px / texte 1,6 doit faire défiler le contenu avant d’appuyer sur le bouton : le formulaire et les cartes restent accessibles par défilement.
- Revue indépendante : aucun point critique. Formulaire restant visible après retrait de consentement, validation Unicode et borne du sélecteur de date reproduits chacun par un test RED, puis corrigés. Les champs sont vidés et masqués, les limites UTF-16 du contrat sont validées sans exception non gérée, le sélecteur couvre 1–9999.
- Régression complète après correction : 197 réussites, 2 tests réseau optionnels ignorés ; analyse Flutter sans anomalie. Le test de fiche médecin emploie le nouveau libellé « Ajouter à mon agenda » et vérifie la garde de connexion, au lieu d’un calendrier de disponibilités fictives.
- Les aspects laissés à la recette réelle par le relecteur sont vérifiés séparément ci-dessous : rendu, reconnexion, API et compilation. Le changement d’heure sur un appareil réel, la livraison push/SMS et le contrôle professionnel côté serveur ne sont pas revendiqués comme testés dans ce lot client. Les tests backend de la livraison précédente restent la référence pour l’isolement professionnel.

Décision de revue : traiter les exceptions locales Unicode comme un défaut à corriger, car une saisie pourtant autorisée par le champ ne doit pas provoquer d’erreur non gérée. Aucune correction mineure volontairement reportée parmi les trois points examinés.


## Recette finale et clôture locale

- Après harmonisation du formulaire : analyse sans anomalie, 197 tests réussis / 2 optionnels ignorés. Web release et APK debug locaux compilés avec API_URL=http://127.0.0.1:8081/api/v1.
- Playwright / Edge sur l’API réelle et le compte fictif autonome : création 201 avec rappel stocké, modification 200 avec version augmentée, fermeture puis nouvelle connexion et date retrouvée, annulation 200, événement retrouvé dans Annulées. Captures 320/390/605 px ; aucune erreur de console ou de page.
- Les deux erreurs de sélection initiales du script provenaient des rôles d’accessibilité : menuitem pour le choix de rappel et checkbox pour le filtre Annulées. La recette finale emploie ces rôles réels. Aucun défaut de contrôle n’a été masqué par un clic forcé.
- Inspection visuelle des captures : bandeau et cartes eCare+ conservés ; formulaire blanc, champs arrondis et icônes bleues repris des conventions de l’application. Lecture 320 px sans débordement horizontal ; formulaire défilant.
- Backend et frontend professionnel : arbres Git propres, aucune modification dans ce lot. Branche mobile conservée en l’état, changements locaux non publiés. Aucun appareil physique installé/testé dans ce lot.
- Aucun point critique ou important restant identifié par la revue ; les limites de livraison externe, de reprise durable hors connexion et de changement d’heure réel restent explicites. Aucun autre relecteur n’a été relancé après la correction et la suite verte.

Coûts des décisions : conserver les dossiers existants évite de dupliquer les serveurs locaux mais exige de garder le travail non publié ; maintenir la séparation des agendas empêche une réservation médicale implicite et nécessitera un parcours dédié si celle-ci est demandée ; transmettre UTC limite les ambiguïtés mais le fuseau d’origine n’est pas conservé comme préférence IANA ; l’absence de file durable impose une actualisation manuelle après fermeture d’une commande incertaine.
