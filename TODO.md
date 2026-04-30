# TODO — MultiBot Chatless

## Bugs / corrections à vérifier

* Il semble y'avoir une regression, quand je me déconnecte et reconnecte l'UI du groupe nblizzard n'est pas refresh les bots restent en inconne je suis obligé de faire un reload
* Quand je fais addclass bots on m'envoi que des bots level 1 même si je suis level 80
* Nouveau outfit par bridge : vérifier le cas de deux armes à deux mains, le bot ne les équipe pas.
* Inventaire bridge : vérifier qu'il n'y a plus de limite visuelle ou logique à 16 emplacements.
* Recentrer les icônes des glyphes.
* Glyphes : analyser pourquoi l'affichage est lent.
* Quick Shaman / Quick Hunter : faire en sorte que la croix de fermeture reste à la même place quand on ferme la frame.
* Quick bars : ne pas faire apparaître les quick bars pour les joueurs humains.
* Raidus : rafraîchir correctement à l'ouverture et à la fermeture.
* Raidus : ajouter un bouton pour enlever les bots inconnus et les supprimer aussi des SavedVariables.
* Quêtes : dans la liste des quêtes, corriger les cas où l'ID de quête apparaît à la place du titre.
* Talents / glyphes : revoir `UI/MultiBotTalent`, car il y a eu des modifications dans le fichier `.conf` de MultiBot.
* Menus déroulants de la main bar : fermer automatiquement les autres menus quand on en ouvre un nouveau.
* J'ai l'impression que le disperse ne fait rien

## Frame Loot

* Tri intelligent des bots : afficher en haut les bots qui peuvent réellement utiliser l’objet selon classe, spé, type d’armure, arme, rôle.
* Filtre par rôle : boutons Tous, Tank, Heal, DPS, Caster, Mêlée, ou par classe.
* Suggestion automatique : préselectionner le bot le plus pertinent au lieu du premier candidat.
* Tooltip enrichi : survol du bot = classe, spé, rôle, niveau, équipement actuel comparable si l’addon connaît l’inventaire.
* Indicateur de pertinence : par exemple Excellent, Possible, Mauvais choix, avec couleur verte/orange/rouge.
* Avertissement avant erreur : confirmer si tu attribues une plaque à un mage, une arme inutilisable, ou un item épique à un bot non adapté.
* Bouton “Attribuer recommandé” : un seul clic pour donner l’objet au meilleur candidat.
* Historique des loots : petite liste “objet donné à X” pendant la session, utile en raid.
* Mémorisation des préférences : par exemple toujours donner tissu spell à tel bot, plaques tank à tel autre, etc.
* Masquer les bots non pertinents : option pour ne voir que ceux qui peuvent équiper/utiliser l’objet.
* Lien avec MultiBotInventoryFrame : clic droit sur un bot dans la dropdown = ouvrir son inventaire/équipement.
* Mode compact : pour les combats, n’afficher que icône item + nom + dropdown + bouton.
* Bouton refresh transformé en icône : garder la sécurité manuelle sans prendre autant de place.
* Attribution rapide par raccourcis : Alt+clic attribue au bot recommandé, Shift+clic ouvre détails.
* Debug discret : une option /mb lootdebug au lieu de spam chat permanent.

-- Avancement:

Fonction	Statut	Détail
Tri intelligent des bots	**oui / oui**	Score calculé selon armure, arme utilisable, profil principal des stats, rôle/spé estimé, et pénalité loot récent. !!! Je garderais juste une petite réserve mentale : ce n’est pas encore un simulateur BiS ou comparaison d’équipement, mais pour classer correctement les bots selon “qui peut vraiment utiliser l’objet”, la base est maintenant bonne.
Classe compatible	**oui**	Compatibilité évaluée via les tables de classe pour l’armure maximale, les boucliers et les armes utilisables. !!! La seule limite : ça vérifie la compatibilité “peut porter/utiliser”, pas encore la pertinence fine type “ce paladin peut porter cette masse caster mais ce n’est pas pour Vindicte”. Cette pertinence-là est couverte par le scoring stats/rôle.
Type d’armure compatible	**Oui**	cloth/leather/mail/plate/shield sont scorés.
Arme utilisable	**Oui**	Table d’armes par classe utilisée dans le score.
Stats utiles à la spé	**oui**	Le tooltip est scanné pour déterminer un profil principal d’objet : tank, physical, caster ou healer, puis comparé au rôle/spé estimé du bot. !!! Réserve : ça reste une lecture par grandes familles de stats. Ça ne compare pas encore les caps, le BiS, l’équipement actuel, ni les besoins exacts de chaque spé.
Rôle compatible	**Oui**	Le rôle du bot est estimé depuis sa classe et son arbre de talents/build, puis comparé au profil principal de l’objet dans le score. !!! Même réserve que les autres : c’est une compatibilité de rôle “logique” tank/heal/caster/physical, pas une évaluation ultra fine de chaque spécialisation.
Objet déjà attribué récemment	**Oui**	Pénalité temporaire via recentLootByCandidate, 120 sec.
Classe/spé non pertinente	**Partiel**	Malus de score, mais pas encore masquage ni avertissement clair.
Dropdown Nom Spé 92%	**Oui**	Présent dans BuildCandidateDropdownText.
Suggestion automatique	**Oui**	Les candidats sont triés par score, puis le premier est présélectionné.
Tooltip enrichi	**Partiel**	Nom, classe localisée, spé/build, score. Pas encore niveau ni équipement comparable.
Indicateur Excellent/Possible/Mauvais	**Partiel**	Il y a un % coloré, mais pas encore de libellé texte.
Avertissement avant mauvais choix	**Non**	Pas de confirmation si mage/plaque, arme inutilisable, etc.
Bouton “Attribuer recommandé”	**Partiel**	Le bouton actuel attribue le candidat présélectionné, donc le meilleur par défaut, mais pas de bouton dédié.
Historique des loots visible	**Oui**	Les derniers loots attribués apparaissent en bas de la frame pendant la session.
Mémorisation des préférences	**Oui**	Clic droit sur Attribuer mémorise le bot choisi pour les objets similaires et lui donne un bonus de score ensuite.
Masquer bots non pertinents	**Non**	Les mauvais choix restent visibles, seulement avec score bas.
Lien avec MultiBotInventoryFrame	**Oui**	clic droit pour ouvrir inventaire/équipement.
Mode compact	**Non**	Frame réduite/assombrie, mais pas de vrai mode compact.
Refresh en icône	**Non**	Le bouton texte Rafraîchir est encore là.
Raccourcis Alt/Shift clic	**Non**	Pas encore implémenté.
/mb lootdebug discret	**Non**	Il reste au moins un message debug chat direct quand aucun candidat n’est retourné.

**Ajouter en variables:

## Améliorations UI encore ouvertes

* Passer les gobject dans la bridge.
* Uniformiser le template des frames de quêtes avec le style d'Itemus.
* Uniformiser le template de la frame reward avec le style d'Itemus.
* Ajouter une option pour choisir la taille des icônes de la main bar et des Quick Shaman / Quick Hunter.
* Voir quelles autres options utiles peuvent être ajoutées à la frame options de MultiBot.
* Créer les traductions Ace3 pour les tooltips Quick Shaman / Quick Hunter, notamment `Show / Hide / Move Quick Shaman`.
* Finir les options de déplacement des boutons.
* Trouver un moyen de charger tous les skins des pets hunter.

## Loot / vendor / roll

* Remplacer dans le menu loot `Quest` et `Skill` par `Disenchant`, ou ajouter une vraie stratégie `quest` / `skill` côté playerbots.
* `roll` : manquant.
* `roll [item]` : manquant.
* `s *` : déjà présent côté addon, legacy whisper, pas encore bridge-first.
* `s vendor` : déjà présent côté addon inventaire, legacy whisper item par item, pas encore bridge-first.
* `open items` : déjà présent côté addon, legacy whisper.

## À reprendre plus tard

* Commandes par groupe pour `follow` et `attack`.
  * Les patches `RUN~ORDER` / `MultiBotGroupOrderUI.lua` ont été revert.
  * Reprendre seulement après validation manuelle exacte des commandes playerbots acceptées.
  * Tester d'abord en jeu :
    * `@tank attack`
    * `@group1 attack`
    * `@group1 follow`
    * `@group1 stay`
  * Commencer par une intégration addon-only minimale.
  * Ne pas réintroduire tout de suite un endpoint bridge générique.

## Fonctions déjà ajoutées / migrées

### Bridge / chatless

* Handshake bridge `HELLO` / `HELLO_ACK`.
* Liveness bridge `PING` / `PONG`.
* Roster / Units bridge-first.
* States bridge-first.
* Details / detail bot bridge-first.
* Stats simples bridge-first.
* PVP stats bridge-first.
* Inventory bridge-first.
* Inventory post-action refresh bridge-first.
* Spellbook bridge-first.
* Talents / sélection de specs bridge-first.
* Glyphes / Custom Glyphs bridge-first.
* Quêtes bridge-first :
  * incompleted ;
  * completed ;
  * all.
* Outfits bridge-first.
* RTI bridge-first.
* Pull Control bridge-first.
* Combat Strategies bridge-first.
* Disperse bridge-first.
* Loot Rules bridge-first.

### Inventory / Inspect / Outfits

* Gestion des outfits.
* Création / remplacement / suppression / équipement d'outfits via bridge.
* Déséquiper le stuff avec clic droit dans la fenêtre Inspect.
* Refresh de l'inventaire en live après action.
* Nouvelle interface inventaire.
* Correction des refresh trop précoces après `u`, `e`, `ue`, `destroy`, `loot`, etc.
* Suppression du spam automatique `items` quand la bridge est connectée.
* Fallback legacy inventory gardé uniquement en diagnostic.

### Spellbook / Talents / Glyphes

* Nouvelle interface Spellbook.
* Spellbook alimenté par bridge.
* Interface talents améliorée.
* Liste des specs alimentée par bridge.
* Interface glyphes alimentée par bridge.
* Affichage des icônes réelles des glyphes.
* Tooltips glyphes via item link, avec fallback spell.
* Correction de l'ordre visuel / ordre playerbots pour les glyphes.
* Suppression du debug local glyph equip après validation.

### Units / Raidus / Stats

* Unit bar dynamique avec auto-collapse.
* Peuplement des EveryBars via bridge.
* Roster/states/details sans spam `.playerbot bot list`.
* Nouvelle interface Raidus.
* Auto-Stats bridge-first.
* Corrections UI Autostats :
  * adaptation de la frame au texte ;
  * correction du texte sacs tronqué ;
  * correction du rond ovale ;
  * correction du fond bleu ;
  * décalage du nom du bot et de la ligne gold/sacs vers la droite.

### Main bar / options / profils

* Nouvelles fonctions de configuration de l'interface.
* Auto-masquage de la main bar avec réglage du temps.
* Gestion de profils UI.
* Bouton pour cacher Quick Shaman et Quick Hunter.
* Options de déplacement de boutons commencées.

### Iconos / Itemus / templates

* Nouvelle interface Iconos.
* Nouvelle interface Itemus.
* Données Iconos déplacées dans `Data/MultiBotIconos.lua`.
* Données Itemus déplacées dans `Data/MultiBotItemus.lua`.

### RTI

* Nouvelle interface et fonctions pour la gestion des RTI.
* Bouton `All`.
* Boutons de groupes RTI.
* Dropdowns RTI verticaux vers le haut.
* RTI par bot dans les EveryBars.
* Mémorisation visuelle des icônes RTI choisies.
* Séparation entre :
  * assigner une icône RTI préférée ;
  * déclencher `attack rti target` ;
  * déclencher `pull rti target`.
* Support bridge `RUN~RTI`.
* Allowlist bridge pour les commandes RTI.

### Pull / Combat / Position

* Focus.
* New Pull / Pull Control.
* Mini-frame Pull Control.
* Slider `wait for attack time`.
* Presets Pull Control.
* Actions `pull rti target` et `attack rti target` depuis Pull Control.
* Combat Strategies :
  * `avoid aoe` ;
  * `save mana` ;
  * `threat` ;
  * `behind`.
* Disperse :
  * `disperse set <yards>` ;
  * `disperse disable` ;
  * validation 1 à 100 yards ;
  * messages système de confirmation ;
  * correction du double-clic à l'ouverture ;
  * frame fermée et bouton gris par défaut au login.
* Loot Rules :
  * enable / disable loot ;
  * all ;
  * normal ;
  * gray ;
  * quest ;
  * skill.

### Quick bars / classes

* Bouton pour cacher Quick Shaman.
* Bouton pour cacher Quick Hunter.
* Quick Shaman / Quick Hunter branchées dans l'UI existante.
* Début de nettoyage des tooltips hardcodés vers AceLocale.

### Localisation / qualité

* Tooltips hardcodés de plusieurs fichiers déplacés vers les locales Ace3.
* Ajout / correction de clés de traduction pour RTI et LeftCore.
* Corrections Lua lint déjà traitées :
  * `table.getn` remplacé ;
  * variables inutilisées supprimées ;
  * champs globaux non définis corrigés selon les lots concernés.

## Règles de suivi

* Ne pas supprimer les commandes manuelles utiles :
  * `who`
  * `co ?`
  * `nc ?`
  * `ss ?`
* Ne pas réintroduire de parsing automatique de chat pour ouvrir ou peupler les fenêtres UI.
* Garder les chemins legacy uniquement comme fallback diagnostic quand la bridge est absente ou explicitement autorisée.
* Pour le README, ne pas casser le HTML existant : ajouter uniquement les lignes nécessaires.
* Pour les diffs, toujours se baser sur le zip/code actuel fourni dans le chat.
