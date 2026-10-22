# Adaptation tablette de eCare+

## Objectif

Rendre l’application eCare+ confortable à utiliser sur tablette, en portrait comme en paysage, tout en préservant l’expérience mobile existante. La barre de navigation principale reste en bas, conformément au choix de l’utilisateur.

## Constat

L’application s’appuie déjà sur `CarePage` pour limiter plusieurs pages de contenu à 680 dp et `AuthLayout` limite certaines cartes à 480 dp. Cependant, certaines pages gardent une présentation en colonne unique, des largeurs fixes ou des grilles conçues pour téléphone. La navigation principale est déjà centrée et limitée à 680 dp, donc elle sera conservée et vérifiée avec le nouveau cadre.

## Conception

1. **Cadre adaptatif commun** : utiliser les contraintes locales disponibles plutôt qu’une largeur d’écran globale. Centrer le contenu de lecture et de formulaire, avec une largeur maximale adaptée au type de page ; garder les fonds et la navigation pleine largeur.
2. **Disposition selon la largeur** : sur les pages de tableau de bord et de listes (accueil, médecins, documents, articles, rendez-vous et suivi), passer aux colonnes ou grilles quand l’espace le permet. Les cartes doivent garder une largeur lisible et ne pas s’étirer sur toute la tablette.
3. **Formulaires et fenêtres** : limiter la largeur des formulaires d’authentification et des dialogues, conserver leur défilement et vérifier qu’ils restent utilisables avec le clavier et en paysage.
4. **Pages secondaires** : appliquer le même principe aux paramètres, profil, notifications, messagerie et pages légales ; garder une colonne centrée là où une grille rendrait le contenu moins lisible.
5. **Navigation** : conserver la barre en bas, son action centrale et ses destinations. La rendre centrée avec une largeur de contenu stable sur grand écran.

Les seuils seront choisis selon les contraintes réellement disponibles dans chaque page (environ 600 dp pour commencer une disposition à plusieurs colonnes et 900 dp pour une grille plus dense), puis ajustés aux tailles minimales de cartes et aux textes. Les seuils ne changent pas le comportement sur téléphone.

## Portée de l’implémentation

- Ajouter un petit ensemble de règles réutilisables pour largeur maximale et seuils adaptatifs dans `lib/widgets/` ou `lib/utils/`, en cohérence avec l’architecture existante.
- Adapter les composants partagés (`CarePage`, navigation, layout d’authentification) et les vues listées ci-dessus.
- Préserver le fonctionnement des parcours, états, routes, actions et textes existants ; cette tâche porte sur la disposition et les contraintes d’affichage.
- Ne pas ajouter de dépendance.

## Vérification prévue

Analyser les changements, lancer l’analyse statique Dart, puis vérifier les parcours essentiels à plusieurs tailles de fenêtre (téléphone étroit, tablette portrait et tablette paysage) si un émulateur ou une cible disponible le permet. Corriger les débordements et contraintes de défilement observés. Aucun test automatisé nouveau n’est prévu sans demande explicite.

## Revue de la spécification

- La navigation reste en bas dans toutes les tailles : conforme à la préférence donnée.
- L’adaptation se fonde sur les contraintes locales et laisse les petits écrans inchangés.
- La disposition multi-colonnes n’est proposée que pour les listes et tableaux de bord ; les contenus longs restent centrés et limités en largeur.
- La portée couvre les écrans applicatifs principaux et secondaires sans modification des flux métier.
