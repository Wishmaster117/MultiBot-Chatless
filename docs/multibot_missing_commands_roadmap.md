# MultiBot - Roadmap commandes manquantes à ajouter

## Objectif

Ce document suit les commandes `mod-playerbots` encore intéressantes à intégrer dans l'addon MultiBot, en distinguant :

- les commandes utiles dans une interface joueur ;
- les commandes à garder uniquement en usage manuel ;
- les commandes serveur/admin à ne pas intégrer dans l'addon ;
- les priorités d'intégration bridge-first/chatless.

Le principe reste le même que pour Inventory, Spellbook, Glyphs, Talents, Stats, Quests, Outfits, RTI, Pull Control, Combat Strategies, Disperse, Loot Rules, Character Info, Reputations, Monnaies, Profession Recipes, Craft, Loot Master, Bot Bank, Guild Bank et Vendor Buy :
**éviter le spam chat automatique**, utiliser le bridge quand c'est possible, et conserver les commandes manuelles utiles comme `who`, `co ?`, `nc ?`, `ss ?`.

---

## État d'avancement déjà réalisé

### Déjà migré / déjà présent en bridge-first

| Sujet | Statut | Notes |
|---|---:|---|
| Roster / Units | Fait | Peuplement via bridge, sans dépendre du spam `.playerbot bot list` côté UI. |
| States | Fait | Récupération structurée via bridge. |
| Inventory | Fait | Fenêtre inventaire alimentée par `GET~INVENTORY`, sans parsing chat automatique. |
| Spellbook | Fait | Migré vers bridge, avec logs serveur, sans spam chat automatique, et filtrage des recettes métiers hors spellbook combat. |
| Glyphs | Fait | Endpoint bridge ajouté et UI alimentée par payloads structurés. |
| Talent specs | Partiel/Fait | Liste/specs présentes côté UI/bridge, à consolider selon les prochains besoins. |
| Stats / PvP stats | Fait | Requêtes bridge présentes. |
| Quests | Présent | UI quêtes existante, pas à mélanger avec les commandes manuelles de diagnostic. |
| Outfits | Fait | Endpoint bridge + commandes outfits intégrées. |
| Character Info / Skills | Fait | Nouvelle frame infos personnage alimentée par `GET~BOT_SKILLS`, catégories skills/professions/armes, noms localisés via le client quand possible. |
| Character Info / Reputations | Fait | Onglet réputations alimenté par `GET~BOT_REPUTATIONS`, sans spam chat `rep all`. |
| Character Info / Monnaies | Fait | Onglet monnaies alimenté par `GET~BOT_EMBLEMS`, avec emblèmes et argent du bot. |
| Profession recipes | Fait | Nouvelle frame recettes par métier via `GET~PROFESSION_RECIPES`, composants, compte craftable, recettes à résultat direct ou indirect. |
| Profession recipe craft | Fait | Bouton `Créer` via `RUN~CRAFT_RECIPE`, support recettes classiques et résultats aléatoires/indirects, erreurs détaillées. |
| Bot bank / Guild bank / Vendor buy | Fait/Partiel | `GET~BANK`, `GET~GBANK` et `RUN~ITEM_ACTION` pour banque bot, banque de guilde bot avec retrait protégé, achat vendeur et actions inventaire avancées validées. |
| RTI / Target Icons | Fait | UI complète + bridge `RUN~RTI`, scopes `ALL`, `GROUP`, `BOT`. |
| Pull Control | Fait | Mini-frame MainBar + bridge `RUN~COMBAT`, séquences de commandes, scopes et presets. |
| Combat Strategies | Fait | Toggles individuels dans les EveryBars + mini-frame Party/Raid, via `RUN~COMBAT`. |
| Disperse | Fait | Mini-frame MainBar + bridge `RUN~POSITION`, distance 1-100 yards et disable. |
| Loot Rules | Fait | Mini-frame MainBar + bridge `RUN~LOOT`, profils prédéfinis, bouton masquable via switch persistant. |
| Loot Master | Fait | Nouvelle frame de gestion master loot côté addon, debug désactivé pour éviter le spam chat. |
| MainBar switches | Fait | Switch Creator, Beast Master, Disperse et Loot Rules persistants, avec relayout des boutons visibles. |

---

## Derniers lots terminés : Pull Control + Combat Strategies + Disperse + Loot Rules + Character Info + Craft + Loot Master + Reputations + Monnaies + Items avancés

### Pull Control

Le panneau `Pull Control` a été ajouté comme mini-frame ouverte depuis la MainBar. Il utilise le bridge et ne repose pas sur le parsing chat automatique.

Fonctionnalités terminées :

- bouton `Pull Control` ajouté dans l'ordre de la MainBar ;
- mini-frame dédiée au contrôle de pull ;
- scopes supportés :
  - `BOT` / Selected pour un bot ciblé ;
  - `GROUP` / Party pour le groupe ;
  - `ALL` / Raid pour tous les bots ;
- slider `wait for attack time` avec affichage de la valeur en secondes ;
- toggle `Wait` envoyant `wait for attack time X` ou `wait for attack time 0` ;
- toggle `Focus` envoyant `co +focus` / `co -focus` ;
- toggle `DPS Assist` envoyant `co +dps assist` / `co -dps assist` ;
- toggle `DPS AoE` envoyant `co +dps aoe` / `co -dps aoe` ;
- preset `Single Target` ;
- preset `AoE Pack` ;
- preset `Safe Pull` ;
- preset `Reset` ;
- actions RTI depuis la frame :
  - `pull rti target` ;
  - `attack rti target` ;
- endpoint bridge `RUN~COMBAT~<scope>~<target>~<token>~<command>` ;
- validation serveur des commandes de combat autorisées ;
- routage serveur vers les bots selon le scope ;
- correction compilation liée à la résolution du scope combat ;
- commandes testées en jeu avec réception bridge visible côté serveur.

À fignoler plus tard :

- ajustement visuel définitif de la mini-frame si nécessaire ;
- harmonisation finale de tous les textes hardcodés restants vers AceLocale ;
- vérification de chaque preset en conditions réelles donjon/raid ;
- éventuelle sauvegarde persistante du dernier scope et de la dernière valeur de wait.

### Combat Strategies

Le bloc `Combat Strategies` a été ajouté pour les stratégies permanentes ou semi-permanentes qui ne sont pas strictement liées au pull.

Fonctionnalités terminées :

- les stratégies déjà couvertes par des boutons dédiés n'ont pas été dupliquées inutilement ;
- les nouvelles stratégies ajoutées sont :
  - `co +avoid aoe` / `co -avoid aoe` ;
  - `co +save mana` / `co -save mana` ;
  - `co +threat` / `co -threat` ;
  - `co +behind` / `co -behind` ;
- côté individuel, les toggles sont ajoutés dans le menu/mini-frame déjà lié au bouton `Strategies DPS` de chaque EveryBar ;
- côté groupe/raid, une mini-frame séparée depuis la MainBar permet d'appliquer les mêmes toggles en scope `GROUP` ou `ALL` ;
- le bridge accepte maintenant ces commandes dans la whitelist `RUN~COMBAT` ;
- les commandes sont routées sans parsing automatique du retour `co ?`.

Choix volontaire :

- `co +tank face` / `co -tank face` n'a pas été ajouté ici, car le comportement tank a déjà des boutons dédiés dans les EveryBars ;
- `co +healer dps` / `co -healer dps` n'a pas été ajouté ici, car un contrôle dédié existe déjà côté EveryBar ;
- `co +boost` / `co -boost` n'a pas été ajouté ici, car `Boost` est déjà exposé ailleurs.

Notes fonctionnelles importantes :

- Les commandes `co ?`, `nc ?`, `ss ?` restent manuelles et ne doivent pas devenir une source de parsing automatique.
- Le fait qu'une stratégie apparaisse ou non dans `co ?` dépend du nom exact réellement reconnu côté playerbots.
- `wait for attack time X` n'est pas une stratégie `co`, donc il ne faut pas attendre qu'elle apparaisse forcément dans `co ?`.
- Pour les nouvelles stratégies, le test principal est le comportement réel du bot et la présence d'un `COMBAT_ACK` côté bridge, pas uniquement l'affichage dans `co ?`.

### Disperse

Le bloc `Disperse` a été ajouté pour contrôler rapidement l'espacement collectif des bots sans repasser par le chat.

Fonctionnalités terminées :

- bouton `Disperse` ajouté dans la MainBar ;
- mini-frame compacte ouverte depuis le bouton `Disperse` ;
- input distance configurable ;
- validation addon des distances autorisées entre `1` et `100` yards ;
- refus des valeurs invalides ou supérieures à `100`, sans clamp silencieux ;
- bouton `Set` envoyant `disperse set <yards>` ;
- bouton `Disable` envoyant `disperse disable` ;
- clic droit sur le bouton principal pour désactiver rapidement `Disperse` ;
- endpoint bridge `RUN~POSITION~<scope>~<target>~<token>~<command>` ;
- whitelist serveur limitée aux commandes `disperse set <yards>` et `disperse disable` ;
- application native côté serveur via les valeurs playerbots de dispersion, sans parser une réponse chat ;
- ACK bridge `POSITION_ACK` ;
- confirmation en message système après ACK : distance définie ou dispersion désactivée ;
- état visuel normal au login : bouton principal grisé, input et boutons secondaires cachés ;
- ouverture du menu dès le premier clic après login.

À tester plus largement :

- comportement en groupe complet et raid ;
- interaction avec les mécaniques de déplacement existantes des bots ;
- lisibilité/position exacte de la mini-frame selon les résolutions et skins UI.

### Loot Rules

Le bloc `Loot Rules` a été ajouté pour gérer rapidement les profils de loot sans repasser par le chat.

Fonctionnalités terminées :

- bouton `Loot Rules` ajouté dans la MainBar ;
- mini-frame compacte avec profils de loot prédéfinis ;
- endpoint bridge `RUN~LOOT~<scope>~<target>~<token>~<command>` ;
- whitelist serveur limitée aux commandes de loot attendues ;
- activation/désactivation loot via `nc +loot` / `nc -loot` ;
- profils `ll all`, `ll normal` et `ll gray` ;
- ACK bridge `LOOT_ACK` ;
- bouton principal masquable par un switch dédié dans la barre de contrôle ;
- état du switch mémorisé dans les SavedVariables.

À garder en tête :

- `ll quest` et `ll skill` doivent rester à traiter avec prudence, car ils ne correspondent pas à de vrais profils natifs distincts dans l'état actuel vérifié côté `mod-playerbots` ;
- `ll [item]` et `ll -[item]` restent des améliorations futures possibles depuis l'inventaire.

### Character Info / Skills

La nouvelle frame `Infos personnage` expose les compétences du bot sans dépendre d'un spellbook trop large ni d'un parsing chat.

Fonctionnalités terminées :

- endpoint bridge `GET~BOT_SKILLS~<bot>~<token>` ;
- payloads structurés `BOT_SKILLS_BEGIN`, `BOT_SKILLS_ITEM`, `BOT_SKILLS_END` ;
- catégories `class`, `profession`, `secondary`, `weapon`, `armor` ;
- barres de niveau actuelles/max comme dans une frame Blizzard ;
- noms localisés via les données du client quand c'est possible ;
- fallback texte serveur conservé si le client ne sait pas localiser une compétence ;
- compatibilité AddClass bots, altbots et randombots groupés ;
- clic sur un métier ou une compétence secondaire pour ouvrir la frame recettes quand des recettes existent.

### Character Info / Reputations / Monnaies

La frame `Infos personnage` expose maintenant les réputations et monnaies dans des onglets séparés, sans lancer automatiquement `rep all` ou `emblems` en chat.

Fonctionnalités terminées :

- endpoint bridge `GET~BOT_REPUTATIONS~<bot>~<token>` ;
- payloads structurés `BOT_REPUTATIONS_BEGIN`, `BOT_REPUTATION_ITEM`, `BOT_REPUTATIONS_END` ;
- endpoint bridge `GET~BOT_EMBLEMS~<bot>~<token>` ;
- payloads structurés `BOT_EMBLEMS_BEGIN`, `BOT_EMBLEM_ITEM`, `BOT_EMBLEMS_MONEY`, `BOT_EMBLEMS_END` ;
- affichage des réputations visibles du bot ;
- affichage des emblèmes dans l'ordre WotLK attendu ;
- affichage de l'argent du bot en bas de l'onglet monnaies ;
- onglets style Blizzard en bas de la frame.

### Profession Recipes / Craft

La frame recettes métier permet maintenant de consulter et lancer les crafts connus par un bot via bridge.

Fonctionnalités terminées :

- endpoint bridge `GET~PROFESSION_RECIPES~<bot>~<skillId>~<token>` ;
- payloads structurés `PROFESSION_RECIPES_BEGIN`, `PROFESSION_RECIPES_ITEM`, `PROFESSION_RECIPES_END` ;
- affichage des recettes connues par métier ;
- composants requis et quantité disponible côté bot ;
- compte craftable calculé depuis l'inventaire du bot ;
- coloration/état du bouton `Créer` selon la possibilité de craft ;
- support des recettes à résultat direct via `itemId` ;
- support des recettes à résultat indirect ou aléatoire via `spellId`, par exemple les cartes de calligraphie ;
- endpoint bridge `RUN~CRAFT_RECIPE~<bot>~<token>~<skillId>~<spellId>~<itemId>` ;
- retour structuré `PROFESSION_RECIPE_CRAFT` avec `OK` ou `ERR` et raison ;
- messages d'échec plus parlants côté addon, notamment feu de cuisine requis, déplacement du bot, outil/focus requis, sort non prêt ou cast refusé ;
- refresh différé de la liste après un craft réussi.

### Loot Master

La frame `Master Loot` a été ajoutée côté addon pour préparer une attribution plus lisible du loot.

Fonctionnalités terminées :

- frame dédiée au Master Loot ;
- affichage des candidats ;
- score/préférences/historique récent côté addon ;
- exploitation des données déjà remontées par le bridge quand disponibles : inventaire, détails, équipement, professions ;
- ouverture/usage séparé des règles de loot ;
- debug désactivé pour éviter le spam chat à chaque loot.

### MainBar switches

La barre de contrôle a été ajustée pour éviter d'encombrer la MainBar avec des boutons rarement nécessaires.

Fonctionnalités terminées :

- switch `Creator` existant conservé ;
- switch `Beast Master` existant conservé ;
- nouveau switch `Disperse` ;
- nouveau switch `Loot Rules` ;
- tooltips multilangues `Switch Disperse` et `Switch Loot Rules` ;
- persistance SavedVariables de l'état visible/caché ;
- relayout des boutons visibles pour que `Flee` et `Stay/Follow` restent directement après `Formation` quand les boutons optionnels sont cachés.

### Items avancés banque / guild bank / buy

Le bloc inventaire avancé couvre maintenant les usages banque, banque de guilde et achat vendeur les plus utiles sans parsing chat automatique.

Fonctionnalités terminées :

- endpoint bridge `GET~BANK~<bot>~<token>` ;
- payloads structurés `BANK_BEGIN`, `BANK_ITEM`, `BANK_ERROR`, `BANK_END` ;
- endpoint bridge `GET~GBANK~<bot>~<token>` ;
- payloads structurés `GBANK_BEGIN`, `GBANK_ITEM`, `GBANK_ERROR`, `GBANK_END` ;
- endpoint bridge `RUN~ITEM_ACTION~<bot>~<token>~<action>~<itemId>~<count>` ;
- dépôt dans la banque du bot ;
- retrait depuis la banque du bot ;
- dépôt en banque de guilde du bot ;
- retrait depuis la banque de guilde du bot, avec garde-fous sur les droits de retrait ;
- achat de composants chez un vendeur proche ;
- messages d'échec plus précis, notamment vendeur sans monnaie compatible ou banquier introuvable ;
- consultation de la banque de guilde du bot sans exiger que le joueur soit dans la même guilde ;
- harmonisation visuelle des frames banque bot et BDG avec fond interne sombre.

À garder pour plus tard :

- affichage de l'argent de guilde ;

---

## Priorité 1 - RTI / Target Icons

### Statut

**Terminé côté MultiBot + bridge.**

Le sujet reste dans la roadmap uniquement comme référence technique et UX, car c'est le premier gros bloc de commandes manquantes ajouté dans cette phase.

### Pourquoi

Le système RTI est très utile pour contrôler les bots en donjon/raid :

- assigner une cible prioritaire ;
- forcer l'attaque d'une cible marquée ;
- définir une cible de contrôle de foule ;
- améliorer les pulls propres et le focus mono-cible.

### Commandes couvertes

| Commande playerbots | Statut MultiBot | Priorité | Proposition UI |
|---|---:|---:|---|
| `rti skull` | Fait | Haute | Sélecteur RTI All/Groupe/Bot |
| `rti cross` | Fait | Haute | Sélecteur RTI All/Groupe/Bot |
| `rti circle` | Fait | Haute | Sélecteur RTI All/Groupe/Bot |
| `rti star` | Fait | Haute | Sélecteur RTI All/Groupe/Bot |
| `rti square` | Fait | Haute | Sélecteur RTI All/Groupe/Bot |
| `rti triangle` | Fait | Haute | Sélecteur RTI All/Groupe/Bot |
| `rti diamond` | Fait | Haute | Sélecteur RTI All/Groupe/Bot |
| `rti moon` | Fait | Haute | Sélecteur RTI All/Groupe/Bot |
| `rti cc <icon>` | Fait côté bridge | Haute | Commande autorisée, UI CC à réévaluer si besoin dédié |
| `attack rti target` | Fait | Haute | Bouton Attack global/groupe + bouton batch bots personnels + Pull Control |
| `pull rti target` | Fait | Haute | Bouton Pull global/groupe + bouton batch bots personnels + Pull Control |

### Flux bridge final

```text
RUN~RTI~ALL~~<token>~rti star
RUN~RTI~GROUP~1~<token>~rti square
RUN~RTI~GROUP~2~<token>~rti star
RUN~RTI~BOT~Dollu~<token>~rti square
RUN~RTI~BOT~Zakinje~<token>~rti star
RUN~RTI~ALL~~<token>~attack rti target
RUN~RTI~GROUP~1~<token>~pull rti target
RUN~RTI~BOT~Dollu~<token>~attack rti target
```

### UX actuelle

#### Barre Units

```text
[All] [RTI] [1] [2] [3] [4] ... [Attack] [Pull]
```

- `All` ouvre un menu vertical vers le haut pour choisir le RTI de tous les bots.
- Chaque bouton groupe ouvre un menu vertical vers le haut pour choisir le RTI du groupe.
- L'icône choisie remplace l'icône par défaut du bouton.
- Le reset remet l'icône par défaut.
- `Attack` / `Pull` déclenchent les groupes configurés ou tous les bots selon le scope.

#### EveryBar de bot

```text
[RTI bot]
  └─ menu vertical : Star / Circle / Diamond / Triangle / Moon / Square / Cross / Skull / Default
```

- Chaque bot peut recevoir son RTI personnel.
- Le choix est mémorisé visuellement pendant l'ouverture/fermeture des Units.
- Le bouton batch de la MainBar permet d'envoyer tous les bots personnels en même temps.

#### MainBar

```text
[Bot RTI Action] [Pull Control] [Combat Strategies] [Attaque Tank]
  └─ Bot RTI Action : Attaquer / Pull pour les bots ayant une RTI personnelle
  └─ Pull Control : mini-frame de pull, wait, focus, assist, AoE et actions RTI
  └─ Combat Strategies : mini-frame Party/Raid pour stratégies combat avancées
```

- `Attaquer` envoie `attack rti target` à tous les bots ayant une RTI personnelle mémorisée.
- `Pull` envoie `pull rti target` à tous les bots ayant une RTI personnelle mémorisée.
- `Pull Control` permet d'envoyer les mêmes actions RTI avec un scope choisi.
- `Combat Strategies` permet d'appliquer les stratégies avancées au groupe ou au raid.

---

## Priorité 2 - Pull Control

### Statut

**Terminé côté MultiBot + bridge, à fignoler côté UX uniquement.**

Le panneau dédié existe et couvre les commandes principales de pull propre. Les actions RTI restent aussi disponibles via les boutons RTI existants.

### Commandes couvertes

| Commande playerbots | Statut MultiBot | Priorité | UI actuelle |
|---|---:|---:|---|
| `pull rti target` | Fait | Haute | Bouton Pull RTI global/groupe/bot personnel + Pull Control |
| `attack rti target` | Fait | Haute | Bouton Attack RTI global/groupe/bot personnel + Pull Control |
| `wait for attack time <seconds>` | Fait | Haute | Slider 0-10 sec + toggle Wait |
| `co +focus` / `co -focus` | Fait | Haute | Toggle Focus + presets |
| `co +dps aoe` / `co -dps aoe` | Fait | Haute | Toggle DPS AoE + presets |
| `co +dps assist` / `co -dps assist` | Fait | Haute | Toggle DPS Assist + presets |
| `co +tank assist` | Non exposé dans Pull Control | Moyenne | Déjà couvert ailleurs par les contrôles tank/assist existants, à réévaluer si doublon utile |

### UX actuelle

```text
MainBar
└─ Pull Control
   ├─ Scope: Selected / Party / Raid
   ├─ Wait slider 0-10s avec valeur affichée
   ├─ Toggles: Wait, Focus, DPS Assist, DPS AoE
   ├─ Presets: Single Target, AoE Pack, Safe Pull, Reset
   └─ Actions: Pull RTI Target, Attack RTI Target
```

### Flux bridge final

```text
RUN~COMBAT~BOT~Sahkaal~<token>~co +focus
RUN~COMBAT~GROUP~~<token>~co +dps assist
RUN~COMBAT~ALL~~<token>~co +dps aoe
RUN~COMBAT~GROUP~~<token>~wait for attack time 3
```

### Notes

- Le panneau peut envoyer plusieurs commandes en séquence pour les presets.
- Les retours chat automatiques restent évités.
- Le test fonctionnel principal est le comportement des bots en combat/pull, pas uniquement l'affichage dans `co ?`.

---

## Priorité 3 - Stratégies combat avancées

### Statut

**Terminé côté MultiBot + bridge, à tester en conditions réelles.**

Pull Control a posé la base technique avec `RUN~COMBAT`. Cette étape a été utilisée pour exposer les stratégies combat utiles qui ne sont pas strictement liées au pull.

### Pourquoi

Ces stratégies existent côté playerbots mais n'étaient pas toutes exposées clairement dans MultiBot. Elles ont une vraie utilité en raid/donjon, mais ne doivent pas encombrer la MainBar.

### Commandes couvertes

| Stratégie | Commande | Statut MultiBot | Priorité | Intérêt |
|---|---|---:|---:|---|
| Avoid AoE | `co +avoid aoe` / `co -avoid aoe` | Fait | Haute | Évite les AoE dangereuses |
| Save Mana | `co +save mana` / `co -save mana` | Fait | Haute | Gestion mana healers/casters |
| Threat | `co +threat` / `co -threat` | Fait | Haute | Limite la prise d'aggro selon comportement playerbots |
| Behind | `co +behind` / `co -behind` | Fait | Moyenne | Placement melee derrière la cible |
| Tank Face | `co +tank face` / `co -tank face` | Non ajouté volontairement | Moyenne | Déjà couvert par boutons dédiés EveryBar |
| Healer DPS | `co +healer dps` / `co -healer dps` | Non ajouté volontairement | Moyenne | Déjà couvert par boutons dédiés EveryBar |
| Boost | `co +boost` / `co -boost` | Non ajouté volontairement | Moyenne | Déjà exposé ailleurs |
| Focus | `co +focus` / `co -focus` | Fait via Pull Control | Référence | Focus mono-cible |
| DPS Assist | `co +dps assist` / `co -dps assist` | Fait via Pull Control | Référence | Assist DPS |
| DPS AoE | `co +dps aoe` / `co -dps aoe` | Fait via Pull Control | Référence | Autorise AoE DPS |
| Wait for attack | `wait for attack time X` | Fait via Pull Control | Référence | Pull contrôlé |

### UX actuelle

#### EveryBar / bot individuel

Les stratégies individuelles sont ajoutées au menu existant `Strategies DPS` de chaque bot.

```text
EveryBar bot
└─ Strategies DPS
   ├─ Avoid AoE
   ├─ Save Mana
   ├─ Threat
   └─ Behind
```

Ce choix évite d'ajouter une mini-frame globale pour du fine-tuning individuel : chaque bot reste configurable depuis sa propre barre.

#### MainBar / groupe et raid

Une mini-frame séparée sert uniquement aux scopes collectifs.

```text
MainBar
└─ Combat Strategies
   ├─ Scope: Party / Raid
   ├─ Avoid AoE
   ├─ Save Mana
   ├─ Threat
   └─ Behind
```

Recommandation UX conservée :

- ne pas ajouter ces toggles directement sur la MainBar ;
- garder les actions individuelles dans les EveryBars ;
- garder la frame MainBar pour les actions Party/Raid ;
- réutiliser les scopes `GROUP` et `ALL` déjà validés par Pull Control ;
- garder `co ?` comme vérification manuelle, sans parser automatiquement son retour.

---

## Priorité 4 - Disperse

### Statut

**Terminé côté MultiBot + bridge, à tester en conditions réelles.**

### Pourquoi

Très utile pour les mécaniques AoE ou les combats où les bots doivent s'espacer.

### Commandes couvertes

| Commande playerbots | Statut MultiBot | Priorité | UI actuelle |
|---|---:|---:|---|
| `disperse set <yards>` | Fait | Moyenne | Input distance + bouton Set |
| `disperse disable` | Fait | Moyenne | Bouton Disable + clic droit sur le bouton principal |

### UX actuelle

```text
MainBar
└─ Disperse
   ├─ Distance: [ 10 ]
   ├─ Set
   └─ Disable
```

### Flux bridge final

```text
RUN~POSITION~ALL~~<token>~disperse set 10
RUN~POSITION~ALL~~<token>~disperse disable
POSITION_ACK~ALL~~<token>~<executed>~disperse set 10
POSITION_ACK~ALL~~<token>~<executed>~disperse disable
```

### Notes

- `Disperse` utilise un endpoint séparé `RUN~POSITION` pour éviter de mélanger le positionnement collectif avec les stratégies combat `RUN~COMBAT`.
- La distance est validée entre `1` et `100` yards côté addon et côté bridge.
- Les valeurs invalides ou supérieures à `100` sont refusées avec un message d'erreur localisé.
- La confirmation utilisateur est affichée seulement après réception du `POSITION_ACK`.
- Aucun parsing automatique de réponse chat n'est nécessaire.

---

## Priorité 5 - Loot Rules / Loot List

### Statut

**Terminé côté MultiBot + bridge pour les profils fiables et l'activation/désactivation loot.**

Le sujet reste ouvert uniquement pour les ajouts/retraits d'items précis et la décision autour des profils `Quest`, `Skill` et `Disenchant`.

### Pourquoi

Le contrôle du loot est utile, mais moins prioritaire que RTI/pull/combat/disperse.

### Commandes à couvrir

| Commande playerbots | Statut MultiBot | Priorité | Proposition UI |
|---|---:|---:|---|
| `nc +loot` | Fait | Moyenne | Bouton Enable Loot via `RUN~LOOT` |
| `nc -loot` | Fait | Moyenne | Bouton Disable Loot via `RUN~LOOT` |
| `ll all` | Fait | Moyenne | Profil Loot All via `RUN~LOOT` |
| `ll normal` | Fait | Moyenne | Profil Normal via `RUN~LOOT` |
| `ll gray` | Fait | Moyenne | Profil Gray via `RUN~LOOT` |
| `ll quest` | À corriger / à vérifier | Moyenne | Ne pas considérer fiable tant que le profil natif n'est pas confirmé côté `mod-playerbots` |
| `ll skill` | À corriger / à vérifier | Moyenne | Ne pas considérer fiable tant que le profil natif n'est pas confirmé côté `mod-playerbots` |
| `ll disenchant` | À ajouter si besoin | Moyenne | Profil natif à préférer si l'UI expose un profil désenchantement |
| `ll [item]` | Manquant | Basse | Ajouter item depuis inventaire |
| `ll -[item]` | Manquant | Basse | Retirer item depuis inventaire |

### Proposition UI

`Loot Rules` est désormais exposé par une mini-frame de profils prédéfinis.

Les commandes `ll [item]` et `ll -[item]` peuvent être ajoutées plus tard via clic droit sur item dans l'inventaire bridge.

Note à conserver pour une itération ultérieure :

- après vérification du code `mod-playerbots`, `ll quest` et `ll skill` ne correspondent pas à de vrais profils natifs distincts ;
- il faudra soit remplacer les boutons/profils `Quest` et `Skill` par le profil réellement supporté `Disenchant` ;
- soit ajouter de vraies stratégies `quest` et `skill` côté `mod-playerbots` avant de les exposer proprement dans MultiBot ;
- en attendant, éviter de considérer `Quest` et `Skill` comme des profils `ll` fiables côté UI.

---

## Priorité 6 - Trainer / Maintenance extras

### Pourquoi

Utile ponctuellement, surtout pour les altbots.

### Commandes à couvrir

| Commande playerbots | Statut MultiBot | Priorité | Proposition UI |
|---|---:|---:|---|
| `trainer` | Manquant | Moyenne/Basse | Bouton Check Trainer |
| `trainer learn` | Manquant | Moyenne/Basse | Bouton Learn |
| `maintenance` | Déjà présent ou partiel | Moyenne | À consolider |
| `autogear` | Déjà présent ou partiel | Moyenne | À consolider |
| `talents spec list` | Partiel | Moyenne | À vérifier dans UI talents |
| `talents spec <spec>` | Partiel | Moyenne | Sélecteur spec |
| `talents apply <link>` | Partiel | Basse | Champ/import lien |

### Notes

Ces actions peuvent rester en commandes bridge-first simples.  
Pas besoin de parsing automatique de réponses longues, sauf si une future UI veut afficher les résultats.

---

## Priorité 7 - Items avancés

### Pourquoi

L'inventaire bridge-first est déjà en place, le craft de recettes métier passe par le bridge, et les actions banque/guild bank/buy principales sont maintenant couvertes. Les commandes restantes sont des améliorations secondaires autour des items ponctuels, de la vente, de l'ouverture d'objets et des enchantements ciblant un item.

### Commandes à couvrir

| Commande playerbots | Statut MultiBot | Priorité | Proposition UI |
|---|---:|---:|---|
| `roll` | Manquant | Moyenne | Bouton Roll |
| `roll [item]` | Manquant | Moyenne | Clic droit item |
| `s *` | Déjà présent côté addon, legacy whisper, pas encore bridge-first | Moyenne | Bouton Sell Gray existant |
| `s vendor` | Déjà présent côté addon inventaire, legacy whisper item par item, pas encore bridge-first | Moyenne | Bouton Sell Vendor existant |
| `open items` | Déjà présent côté addon, legacy whisper | Moyenne | Bouton dans inventaire existant |
| Craft recette métier | Fait | Moyenne | Frame recettes + bouton `Créer` via `RUN~CRAFT_RECIPE` |
| Craft recette à résultat aléatoire / indirect | Fait | Moyenne | Support `spellId` sans `itemId`, par exemple cartes de calligraphie |
| Enchanter un item | Manquant / à étudier | Moyenne | UI dédiée probable, avec cible item/sort et garde-fous |
| `bank [item]` | Fait via bridge | Basse | Dépôt banque bot via action item |
| `bank -[item]` | Fait via bridge | Basse | Retrait depuis la frame banque bot |
| `gb [item]` | Fait via bridge | Basse | Dépôt banque de guilde du bot |
| `gb -[item]` | Fait via bridge | Basse | Retrait BDG depuis la frame banque de guilde avec garde-fous de droits |
| `b [item]` | Fait via bridge | Basse | Achat vendeur proche depuis composants manquants |

---

## Commandes à garder manuelles

Ces commandes restent utiles pour s'informer ou diagnostiquer un bot, mais ne doivent pas forcément être parsées automatiquement par MultiBot.

| Commande | Décision |
|---|---|
| `who` | Garder manuel |
| `who <profession>` | Garder manuel |
| `co ?` | Garder manuel |
| `nc ?` | Garder manuel |
| `ss ?` | Garder manuel |
| `spells` | Manuel possible, UI bridge déjà présente |
| `glyphs` | Manuel possible, UI bridge déjà présente |
| `talents` | Manuel possible, UI talents présente |
| `stats` | Manuel possible, UI stats bridge présente |
| `quests` | Manuel possible, UI quêtes existante |

---

## Commandes à ne pas intégrer dans l'addon

Ces commandes sont plutôt serveur/admin/debug ou trop dangereuses pour une UI utilisateur normale.

| Commande | Raison |
|---|---|
| `playerbot pmon toggle` | Console/debug performance |
| `playerbot pmon stack` | Console/debug performance |
| `playerbot pmon tick` | Console/debug performance |
| `playerbot pmon reset` | Console/debug performance |
| `playerbot rndbot reset` | Admin serveur |
| `playerbot rndbot stats` | Admin serveur |
| `playerbot rndbot reload` | Admin serveur |
| `playerbot rndbot update` | Admin serveur |
| `playerbot rndbot init` | Dangereux / reroll rndbots |
| `playerbot rndbot clear` | Dangereux |
| `playerbot rndbot level` | Admin serveur |
| `playerbot rndbot refresh` | Admin serveur |
| `playerbot rndbot teleport` | Admin serveur |
| `playerbot rndbot revive` | Buggué selon wiki |
| `playerbot rndbot grind` | Buggué/crash selon wiki |
| `playerbot rndbot change_strategy` | Admin serveur |
| `playerbot bot initself` | Dangereux |
| `playerbot bot tweak` | Peu utile / ancien |
| `playerbot bot lookup` | Peu utile |
| `playerbot bot self` | Debug/expérimental |
| `.playerbots account setKey` | Setup compte, pas gameplay |
| `.playerbots account link` | Setup compte, pas gameplay |
| `.playerbots account linkedAccounts` | Setup compte, pas gameplay |
| `.playerbots account unlink` | Setup compte, pas gameplay |

---

## Commandes non prioritaires ou à éviter

| Commande | Décision |
|---|---|
| `runaway` | Wiki indique actuellement non fonctionnel |
| `do loot` | Wiki indique actuellement non fonctionnel |
| `do add all loot` | Wiki indique actuellement non fonctionnel |
| `rpg status` | Niche |
| `rpg do quest` | Niche |
| `spell rpg` | Niche |
| `log` | Debug |
| `debug spell` | Debug |
| `los` | Utile ponctuellement, mais manuel suffit pour le moment |
| `home` | Niche |
| `taxi` | Niche |
| `chat` | Niche |

---

## Synthèse des prochaines étapes conseillées

| Ordre | Sujet | Type | Priorité | Statut |
|---:|---|---|---:|---:|
| 1 | RTI bridge-first | UI + bridge command | Haute | Fait |
| 2 | Pull Control avancé | Nouvelle UI + séquences commandes | Haute | Fait / à fignoler |
| 3 | Advanced Combat Strategies | EveryBars + mini-frame Party/Raid via `RUN~COMBAT` | Haute/Moyenne | Fait |
| 4 | Disperse | Petite UI + commande positionnement via `RUN~POSITION` | Moyenne | Fait |
| 5 | Loot Rules | Petite UI profils + bridge `RUN~LOOT` | Moyenne | Fait, profils `Quest`/`Skill` à corriger si conservés |
| 6 | Character Info / Skills | Nouvelle frame + endpoint skills | Moyenne | Fait |
| 7 | Profession recipes / Craft | Frame recettes + `RUN~CRAFT_RECIPE` | Moyenne | Fait |
| 8 | Loot Master | Nouvelle frame addon + données bridge disponibles | Moyenne | Fait |
| 9 | Roll | Commandes ponctuelles loot/items | Moyenne | À faire |
| 10 | Ventes / Open items bridge-first | Migration de commandes déjà exposées côté addon | Moyenne | À faire |
| 11 | Enchantements d'items | UI dédiée et garde-fous | Moyenne | À étudier |
| 12 | Trainer / Maintenance extras | UI maintenance | Moyenne/Basse | À faire |
| 13 | Items avancés banque/guild bank/buy | Extensions inventaire | Basse/Moyenne | Fait/partiel |

---

## Notes d'architecture

- Toute nouvelle commande utilisée automatiquement par l'addon devrait passer par le bridge quand possible.
- Les commandes manuelles informatives doivent rester fonctionnelles en whisper/party/raid.
- Ne pas réintroduire de parsing chat automatique pour peupler l'UI.
- Pour les commandes qui ne nécessitent aucun retour structuré, un endpoint générique de type `RUN~COMMAND` ou un endpoint spécialisé comme `RUN~RTI` / `RUN~COMBAT` / `RUN~POSITION` / `RUN~LOOT` peut suffire.
- Pour les commandes qui doivent alimenter une frame, préférer un endpoint structuré dédié.
- Pour les actions de craft, garder un retour structuré avec raison d'échec exploitable par l'addon, comme `PROFESSION_RECIPE_CRAFT`.
- Les commandes serveur/admin ne doivent pas être exposées dans l'addon utilisateur.
- Les boutons ajoutés dans les barres doivent conserver une position cohérente avec `MultiBotLeftCoreUI.lua` et la position par défaut de `MultiBar` dans `MultiBotInit.lua` / reset dans `MultiBotMainUI.lua`.
- Les tooltips nouvellement ajoutés doivent passer par AceLocale, comme les tooltips RTI, Pull Control, Combat Strategies, Switch Disperse et Switch Loot Rules.
- `RUN~COMBAT`, `RUN~POSITION` et `RUN~LOOT` doivent rester whitelistés côté bridge : ne pas en faire des exécuteurs libres de n'importe quelle commande chat.
- Éviter les doublons UI : si une stratégie dispose déjà d'un bouton EveryBar dédié, ne pas la rajouter dans une nouvelle frame sauf besoin UX clairement identifié.

---

## Point logique suivant

Le prochain bloc logique conseillé est **Roll + migration optionnelle des ventes/open items vers bridge + étude des enchantements d'items**.

Raison : les blocs RTI, Pull Control, Combat Strategies, Disperse, Loot Rules, Character Info, Reputations, Monnaies, Profession Recipes, Craft, Loot Master et Items avancés banque/guild bank/buy couvrent maintenant le ciblage, le pull, les stratégies combat, le positionnement collectif, les profils de loot, les compétences, les réputations, les monnaies, les recettes métier, le craft, la préparation du master loot et les actions banque/achat principales. Après vérification du code actuel, la vente grise, la vente vendor et `open items` existent déjà côté addon, mais restent en legacy whisper et ne sont pas encore bridge-first.

État précis des commandes items/loot ponctuelles :

- `roll` : Manquant ;
- `roll [item]` : Manquant ;
- `s *` : Déjà présent côté addon, legacy whisper, pas encore bridge-first ;
- `s vendor` : Déjà présent côté addon inventaire, legacy whisper item par item, pas encore bridge-first ;
- `open items` : Déjà présent côté addon, legacy whisper ;
- banque bot : Consultation, dépôt et retrait via bridge ;
- banque de guilde bot : Consultation, dépôt et retrait via bridge, avec garde-fous de droits ;
- achat vendeur : Disponible via bridge depuis les composants manquants de recette ;
- enchantement d'un item précis : manquant / à étudier avec une UI dédiée ;
- `ll [item]` / `ll -[item]` : manquant, amélioration possible depuis l'inventaire.

Proposition de prochaine itération, plus tard :

- ajouter `roll` / `roll [item]`, car c'est le vrai manque fonctionnel restant dans le bloc loot ponctuel ;
- ne pas recréer de boutons `s *`, `s vendor` ou `open items`, car ils existent déjà côté addon ;
- décider si les ventes existantes doivent passer par un endpoint dédié ou par un endpoint existant whitelisté ;
- éviter toute vente automatique dangereuse sans action explicite de l'utilisateur ;
- étudier une UI d'enchantement d'item séparée du craft métier classique, car elle doit cibler un item et prévoir plus de garde-fous ;
- garder les commandes informatives manuelles inchangées ;
- noter que `Quest` et `Skill` devront être remplacés plus tard par `Disenchant`, ou devenir de vrais profils ajoutés côté `mod-playerbots` avant exposition définitive.
