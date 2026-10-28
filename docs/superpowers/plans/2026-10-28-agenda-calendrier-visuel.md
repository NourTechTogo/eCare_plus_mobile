# Calendrier visuel de l’agenda — 28 octobre 2026

## Design et périmètre

Demande : donner un vrai style à l’agenda, avec un calendrier, dans la charte eCare+. Adaptation ciblée de l’écran Flutter existant : conserver Poppins, fond bleu très clair, surfaces blanches arrondies, bleu principal/dégradé et navigation basse. Le calendrier est un contrôle natif, sans image ou dépendance externe ; le reste des interfaces et le backend restent inchangés.

La grande carte récapitulative est remplacée par une carte calendrier mensuelle : lundi en première colonne, navigation précédente/suivante, accès direct à une date, retour à aujourd’hui, jour sélectionné bleu et repères des jours ayant des rendez-vous. Dessous : un seul bouton Ajouter une date, les filtres Mes dates/Annulées, date sélectionnée, compteur et liste du jour. Les cartes de rendez-vous prennent une présentation horaire compacte. Les annulations restent dans leur historique.

Premier chargement : ouvrir le premier jour actif à partir d’aujourd’hui si présent (ou la dernière date active passée), sinon aujourd’hui. Une notification cible sa propre date et son statut. Après sélection manuelle, actualiser ne change plus le jour choisi. Changer de mois conserve le numéro du jour, limité au dernier jour du mois. Le formulaire d’ajout préremplit le jour choisi et conserve l’accusé serveur, la version et les réessais existants.

## Étapes et vérification

- [x] Tests RED : grille lundi/dimanche, marqueurs, sélection, navigation mois/année/bornes, petit écran avec texte agrandi ; filtre réel du jour et préremplissage du formulaire.
- [x] Composant CareMonthCalendar contrôlé et présentation compacte des cartes ; branchement au jour/mois sélectionnés dans AppointmentsPage.
- [x] Préserver le comportement API, historique, consentement, réessais, notifications et navigation basse ; tests GREEN ciblés puis suite complète/analyse.
- [x] Compiler web et APK, recette navigateur sur API réelle, captures 320/390/605 et inspection visuelle. Un seul relecteur final, sans modification du code.
- [x] Bilan des ajouts/limites ; garder les changements locaux, sans push.

Décisions : réutiliser les dossiers et la branche mobile en cours, car le lot précédent local est nécessaire ; ne pas créer un second agenda ni modifier les routes API. Pas de rendez-vous fictif dans le code du calendrier : les repères proviennent des données autorisées du compte. Les données de démonstration restent dans un compte fictif dédié.


## Registre de vérification

- Composant et intégration : tests RED observés avant leur création, puis 9 tests ciblés GREEN. Grille 320 px/texte 1,6 ajustée pour que les numéros restent sur une ligne dans leurs sept colonnes, avec libellés complets accessibles.
- Première régression : analyse sans anomalie, 201 tests réussis et 2 réseau optionnels ignorés. Web release compilé.
- Revue finale indépendante : action d’activation manquante sur les dates pour les lecteurs d’écran reproduite par une assertion sémantique RED ; ajout de onTap sur le nœud Semantics. Aucun point critique identifié.
- Décision de revue : conserver l’ouverture sur le premier jour avec rendez-vous aujourd’hui compris, plutôt que sauter le jour courant dès qu’un horaire est passé. Le calendrier affiche tous les rendez-vous du jour ; le plan précise désormais cette règle. Coût : le premier jour présenté peut contenir uniquement des horaires déjà passés, accessibles avec le reste de la journée.
- Le rendu navigateur, la recette API réelle et la compilation finale relèvent des vérifications de l’implémenteur, non de la revue statique. La livraison effective push/SMS et un lecteur d’écran sur téléphone physique ne sont pas revendiqués comme testés.


## Clôture vérifiée

Analyse finale : aucune anomalie. Régression complète : 201 réussites, 2 tests réseau optionnels ignorés. Web release et APK debug locaux compilés. La fuite de SemanticsHandle dans la première version du test d’accessibilité a été corrigée par un finally, sans masquer les assertions ; la régression à 200 % a été corrigée dans la disposition des numéros, puis la suite entière est repassée.

La présentation finale garde un bouton d’ajout unique d’au moins 48 px et une icône d’actualisation à côté des filtres. Les numéros ont été agrandis après inspection des premières captures. Le composant n’utilise aucune nouvelle dépendance, image de calendrier ou donnée fictive codée dans l’interface. Les exemples de la recette sont enregistrés dans le compte fictif par l’API réelle.

Aucun autre relecteur lancé après la correction. Aucun correctif mineur reporté : le choix de premier jour reste une décision de produit documentée. Backend et frontend professionnel inchangés ; modifications locales conservées, sans commit/push automatique.


Recette finale après les corrections : navigation des mois, retour à aujourd’hui, sélection et filtrage des jours, date de création préremplie, création 201, reconnexion, annulation 200 et historique validés sur l’API réelle. Captures finales 320/390/605 inspectées ; aucun débordement visible ni erreur de console/page. À 390 et 605 px, la première carte commence sous la date sélectionnée ; le reste de la liste et ses actions sont accessibles par défilement. Les exemples visibles appartiennent uniquement au compte fictif de recette.
