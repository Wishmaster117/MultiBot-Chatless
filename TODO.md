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
* Quêtes : dans la liste des quêtes, corriger les cas où l'ID de quête apparaît à la place du titre. quand on rouvre c'est ok
* Talents / glyphes : revoir `UI/MultiBotTalent`, car il y a eu des modifications dans le fichier `.conf` de MultiBot.
* J'ai l'impression que le disperse ne fait rien
* Refaire uns passe pour que toutes les frames respectent le strata de la config.
* Retravailler la frame pvp stats qu'elle ressemble aux autres, et ajuster l'alignement du texte
* Faire une UI pour enchanter les objets à moins qu'on arrive à faire le bot caster le spell sur la fenêtre de trade.
* Refaire le layout de la frame pvp stats pour harmoniser avec les autres frames
* voire si on peux ajouter l'avancement de la quête d'un bot


## Informations bot
* Dans les frames métier ajout d'un bouton pour faire le bot acheter les composants manquants pour crafter l'item.
* Infos personnage : onglets style Blizzard pour compétences, réputations et monnaies.
 

## Inventaire Bot étendu
* Ajout d'un bouton Pour déposer des objets dans la banque du bot.
* Ajout d'une frame pour afficher le contenu de la banque du bot, avec un bouton pour retirer les objets de la banque.
* Ajout d'un bouton pour déposer des objets dans la banque de guilde.
* Ajout d'une frame pour afficher le contenu de la banque de guilde.

** TODO
* Afficher les sous de la guilde dans la frame BDG

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

## Améliorations UI encore ouvertes

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
* Frames de quêtes `all`, `completed` et `incompleted` uniformisées avec fond interne sombre, marges cohérentes et bouton `Abandonner` par quête de bot.
* Outfits bridge-first.
* Character Info bridge-first.
* Réputations bridge-first dans la frame Infos personnage.
* Monnaies / emblèmes bridge-first dans la frame Infos personnage, avec argent du bot.
* Banque bot bridge-first avec consultation, dépôt et retrait.
* Banque de guilde bot bridge-first avec consultation, dépôt et retrait protégé par les droits de guilde.
* Layout des frames banque bot et BDG uniformisé avec fond interne sombre.
* Trainer bridge-first :
  * bouton `Trainer` ajouté dans l'EveryBar après `Outfits` ;
  * frame harmonisée avec les frames de quêtes ;
  * consultation des sorts apprenables depuis le trainer sélectionné ;
  * apprentissage d'un sort ou de tous les sorts via bridge.
* Achat vendeur bridge-first depuis les composants manquants de recette métier.
* Profession recipes bridge-first.
* Craft de recettes métier via bridge `RUN~CRAFT_RECIPE`.
* Messages d'erreur détaillés pour le craft :
  * feu de cuisine requis ;
  * bot en mouvement ;
  * outil / focus requis ;
  * recette pas prête ou cast refusé.
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
