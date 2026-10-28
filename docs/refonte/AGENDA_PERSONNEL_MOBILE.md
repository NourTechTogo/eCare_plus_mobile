# Agenda personnel mobile — 28 octobre 2026

L’agenda utilise désormais les routes personnelles du backend commun. Les cartes, le bandeau bleu, Poppins, les couleurs, les arrondis et la navigation eCare+ sont conservés.

## Calendrier visuel

La carte mensuelle permet de changer de mois, revenir à aujourd’hui ou choisir directement une date. Les repères sont calculés depuis les rendez-vous du compte, pour le filtre actif. Choisir un jour affiche ses rendez-vous et préremplit la date du formulaire d’ajout. Les numéros des jours gardent sept colonnes sur petit écran, y compris avec texte agrandi ; leur libellé complet et leur action restent disponibles aux lecteurs d’écran.

Le premier chargement ouvre le premier jour avec rendez-vous à partir d’aujourd’hui (y compris des horaires déjà passés aujourd’hui), ou la dernière date active passée. Si l’agenda est vide, il ouvre aujourd’hui. Une notification ouvre la date de son rendez-vous. Après une sélection manuelle, l’actualisation garde ce jour. Les filtres Mes dates et Annulées portent sur le jour sélectionné. Le bouton d’ajout est unique.

## Parcours

- Rendez-vous → Ajouter une date : motif, professionnel facultatif, date et heure de l’appareil, lieu, note et rappel facultatifs.
- Création, modification et annulation annoncées uniquement après l’accusé du serveur. Les dates confirmées sont rechargées après connexion. Une annulation reste dans Annulées et invalide le rappel associé.
- Les changements de version provoquent un conflit visible et une actualisation ; aucune modification concurrente n’est écrasée automatiquement.
- Une réponse incertaine conserve la commande et sa référence UUID. Les champs sont gelés jusqu’au réessai identique ou à une sortie explicite. Après une sortie incertaine, actualiser l’agenda avant de recréer une date.
- L’onglet recharge les données lorsqu’il redevient actif et au retour de l’application. Le formulaire masque et efface ses champs au retrait du consentement.
- Les notifications RENDEZ_VOUS_PERSONNEL ouvrent la date actuelle, y compris lorsqu’elle a été annulée. Les gestes de lecture, suppression et archivage de la boîte restent inchangés.

## Contrat et limites

Les heures sont saisies et affichées dans le fuseau de l’appareil. Le formulaire affiche le décalage UTC à la date sélectionnée. Le transport envoie l’instant et le fuseau UTC ; une édition sans changement de date conserve exactement l’instant initial. Les heures locales inexistantes lors d’un changement d’heure sont refusées. Les dates acceptées vont des années 1 à 9999.

Les états des rappels viennent du serveur : planifié, publié dans eCare+, lu, terminé, annulé ou en échec. « Publié » ne garantit pas une réception push/SMS. Les fournisseurs externes et les alarmes système hors connexion nécessitent leur configuration et une recette distincte.

Cet agenda est personnel : aucune disponibilité fictive ni réservation médicale n’est créée. Il fonctionne sans médecin ni structure affectés. Les professionnels ne reçoivent pas implicitement ces données dans le web. L’entrée depuis une fiche médecin ne fait que préremplir son nom.

L’ancien agenda en mémoire dans CareData est retiré pour éviter deux sources de vérité. Les anciennes dates locales de session n’avaient pas de stockage durable et ne peuvent pas être récupérées. Les commandes incertaines restent limitées à l’écran/session ; la file hors connexion durable est un lot ultérieur.

Le backend et le frontend web sont inchangés dans ce lot. Les nouveaux travaux sont locaux, sans publication GitHub supplémentaire automatique.
