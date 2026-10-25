> Document conservé des étapes précédentes. Voir [la validation de livraison](../VALIDATION.md) pour les résultats et limites à la publication. Les fichiers `.maintenance` cités ne sont pas inclus.

# Pages de suivi et futur branchement backend

Les trois pages réutilisent le même écran et les mêmes composants de saisie,
graphique, période et historique. Les variantes spécialisées masquent le
sélecteur et fixent le type de mesure.

| Suivis configurés pour le patient | Route Flutter | Page |
| --- | --- | --- |
| Glycémie et tension | `AppRoutes.followUp` (`/follow-up`) | `FollowUpPage` |
| Glycémie seule | `AppRoutes.glucoseFollowUp` (`/follow-up/glucose`) | `GlucoseFollowUpPage` |
| Tension seule | `AppRoutes.bloodPressureFollowUp` (`/follow-up/blood-pressure`) | `BloodPressureFollowUpPage` |

Pour l’instant, les raccourcis existants ouvrent le suivi complet. Les deux
nouvelles routes sont enregistrées dans `ECarePlusApp` et peuvent être ouvertes
avec `Navigator.pushNamed`.

Lors du branchement au backend, utiliser les suivis explicitement activés dans
le profil patient pour choisir cette route depuis tous les points d’entrée
(accueil et notifications). Une configuration absente ou pas encore chargée
doit avoir un état dédié ; elle ne doit pas être interprétée comme une
autorisation des deux suivis. Le schéma exact de l’API reste à définir.

`CareData.readings` et `CareData.bloodPressureReadings` séparent déjà les mesures.
Elles sont actuellement conservées en mémoire pendant la session. Le futur
service patient devra charger et enregistrer les mesures, contrôler les types
autorisés côté serveur et gérer les erreurs de synchronisation.

Ces pages ne constituent pas un contrôle d’accès : la route est un choix
d’affichage, à compléter par les autorisations du backend.
