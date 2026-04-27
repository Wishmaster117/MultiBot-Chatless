# MultiBot - Roadmap commandes manquantes à ajouter

## Objectif

Ce document suit les commandes `mod-playerbots` encore intéressantes à intégrer dans l'addon MultiBot, en distinguant :

- les commandes utiles dans une interface joueur ;
- les commandes à garder uniquement en usage manuel ;
- les commandes serveur/admin à ne pas intégrer dans l'addon ;
- les priorités d'intégration bridge-first/chatless.

Le principe reste le même que pour Inventory, Spellbook, Glyphs, Talents, Stats, Quests, Outfits et RTI :  
**éviter le spam chat automatique**, utiliser le bridge quand c'est possible, et conserver les commandes manuelles utiles comme `who`, `co ?`, `nc ?`, `ss ?`.

---

## État d'avancement déjà réalisé

### Déjà migré / déjà présent en bridge-first

| Sujet | Statut | Notes |
|---|---:|---|
| Roster / Units | Fait | Peuplement via bridge, sans dépendre du spam `.playerbot bot list` côté UI. |
| States | Fait | Récupération structurée via bridge. |
| Inventory | Fait | Fenêtre inventaire alimentée par `GET~INVENTORY`, sans parsing chat automatique. |
| Spellbook | Fait | Migré vers bridge, avec logs serveur, sans spam chat automatique. |
| Glyphs | Fait | Endpoint bridge ajouté et UI alimentée par payloads structurés. |
| Talent specs | Partiel/Fait | Liste/specs présentes côté UI/bridge, à consolider selon les prochains besoins. |
| Stats / PvP stats | Fait | Requêtes bridge présentes. |
| Quests | Présent | UI quêtes existante, pas à mélanger avec les commandes manuelles de diagnostic. |
| Outfits | Fait | Endpoint bridge + commandes outfits intégrées. |
| RTI / Target Icons | Fait | UI complète + bridge `RUN~RTI`, scopes `ALL`, `GROUP`, `BOT`. |

### Dernier lot terminé : RTI / Target Icons

Le système RTI a été intégré en mode bridge-first/chatless pour les usages UI. Les commandes manuelles playerbots restent utilisables séparément dans le chat.

Fonctionnalités terminées :

- endpoint addon -> bridge `RUN~RTI~<scope>~<target>~<token>~<command>` ;
- validation serveur des commandes RTI autorisées ;
- scopes supportés :
  - `ALL` pour tous les bots ;
  - `GROUP` avec groupe de raid ciblé ;
  - `BOT` pour un bot précis ;
- commandes autorisées côté bridge :
  - `rti <icon>` ;
  - `rti cc <icon>` ;
  - `attack rti target` ;
  - `pull rti target` ;
- panneau RTI global dans la barre Units ;
- bouton `All` à gauche du bouton RTI ;
- boutons groupes numérotés à droite du bouton RTI ;
- menu vertical vers le haut pour choisir l'icône RTI d'un scope ;
- remplacement visuel du bouton All/Groupe par l'icône RTI sélectionnée ;
- bouton/reset par défaut dans les menus RTI pour retirer l'icône mémorisée ;
- boutons `Attack` et `Pull` pour les RTI de groupe/global ;
- collapse/refermeture des everybars quand on ouvre un menu RTI ;
- bouton RTI dans chaque everybar de bot ;
- menu vertical vers le haut dans chaque everybar pour choisir l'icône RTI du bot ;
- remplacement visuel du bouton RTI du bot par l'icône choisie ;
- reset visuel correct vers l'icône par défaut ;
- mémoire d'affichage des RTI bot quand on ferme/réouvre la barre Units ;
- bouton d'action RTI personnel dans la main bar, placé à gauche de `Attaque Tank` ;
- menu vertical `Attaquer` / `Pull` pour envoyer en batch tous les bots ayant une RTI personnelle mémorisée ;
- tooltips RTI passés en variables AceLocale ;
- traductions RTI ajoutables dans les fichiers locale.

Notes fonctionnelles importantes :

- `rti <icon>` ou `rti cc <icon>` ne doit servir qu'à mémoriser l'icône RTI que le bot ou le groupe doit focus.
- `attack rti target` et `pull rti target` consomment ensuite cette configuration pour déclencher l'action.
- Pour éviter les attaques involontaires, l'UI ne doit pas poser de marque sur un mob : elle configure seulement l'icône préférée côté bots.
- Si `skull` déclenche un comportement automatique côté playerbots selon configuration/stratégie, éviter d'utiliser le crâne comme icône par défaut visuelle dans l'UI.

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
| `attack rti target` | Fait | Haute | Bouton Attack global/groupe + bouton batch bots personnels |
| `pull rti target` | Fait | Haute | Bouton Pull global/groupe + bouton batch bots personnels |

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

#### Everybar de bot

```text
[RTI bot]
  └─ menu vertical : Star / Circle / Diamond / Triangle / Moon / Square / Cross / Skull / Default
```

- Chaque bot peut recevoir son RTI personnel.
- Le choix est mémorisé visuellement pendant l'ouverture/fermeture des Units.
- Le bouton batch de la main bar permet d'envoyer tous les bots personnels en même temps.

#### Main bar

```text
[Bot RTI Action] [Attaque Tank]
  └─ Attaquer
  └─ Pull
```

- `Attaquer` envoie `attack rti target` à tous les bots ayant une RTI personnelle mémorisée.
- `Pull` envoie `pull rti target` à tous les bots ayant une RTI personnelle mémorisée.

---

## Priorité 2 - Pull Control

### Statut

**Partiellement fait grâce à RTI.**  
Les actions `attack rti target` et `pull rti target` sont intégrées. Le vrai panneau `Pull Control` reste à faire pour les stratégies et temporisations.

### Pourquoi

Les pulls propres demandent plusieurs commandes combinées. Une UI dédiée éviterait les macros manuelles.

### Commandes à couvrir

| Commande playerbots | Statut MultiBot | Priorité | Proposition UI |
|---|---:|---:|---|
| `pull rti target` | Fait | Haute | Bouton Pull RTI global/groupe/bot personnel |
| `attack rti target` | Fait | Haute | Bouton Attack RTI global/groupe/bot personnel |
| `wait for attack time <seconds>` | Manquant | Haute | Champ numérique 0-10 sec |
| `co +focus` / `co -focus` | Manquant ou non exposé clairement | Haute | Toggle Focus |
| `co -aoe` / `co +aoe` | Partiel | Haute | Toggle AoE during pull |
| `co +assist` | Partiel | Haute | Toggle Assist |
| `co +tank assist` | Partiel | Moyenne | Toggle Tank Assist |

### Proposition UI restante

Créer une section `Pull Control` :

| Option UI | Commande |
|---|---|
| Wait before attack | `wait for attack time X` |
| Single target pull | `co +focus,-aoe,+assist` |
| Enable AoE again | `co +aoe,-focus` |
| Attack RTI target | Déjà fait via RTI |
| Pull RTI target | Déjà fait via RTI |
| Tank assist | `co +tank assist` |

### Notes

Cette section peut envoyer plusieurs commandes en séquence.  
Il faudra éviter les retours chat automatiques inutiles.

---

## Priorité 3 - Stratégies combat avancées

### Pourquoi

Ces stratégies existent côté playerbots mais ne sont pas toutes exposées clairement dans MultiBot. Elles ont une vraie utilité en raid/donjon.

### Commandes à couvrir

| Stratégie | Commande | Statut MultiBot | Priorité | Intérêt |
|---|---|---:|---:|---|
| Focus | `co +focus` / `co -focus` | Manquant | Haute | Focus mono-cible |
| Avoid AoE | `co +avoid aoe` / `co -avoid aoe` | À vérifier | Haute | Évite les AoE dangereuses |
| Save Mana | `co +save mana` / `co -save mana` | Manquant | Haute | Gestion mana healers |
| Threat | `co +threat` / `co -threat` | Manquant | Haute | Réduit la prise d'aggro |
| Tank Face | `co +tank face` / `co -tank face` | Manquant | Moyenne | Gestion cleave/breath |
| Behind | `co +behind` / `co -behind` | Manquant | Moyenne | Placement melee |
| Healer DPS | `co +healer dps` / `co -healer dps` | À vérifier | Moyenne | DPS des healers hors danger |
| Boost | `co +boost` / `co -boost` | Probablement partiel | Moyenne | Burst cooldowns |
| Wait for attack | `wait for attack time X` | Manquant | Haute | Pull contrôlé |

### Proposition UI

Créer une page `Advanced Combat` ou ajouter un panneau repliable dans les stratégies.

Ne pas afficher tous les boutons dans la barre principale pour éviter de surcharger l'interface.

---

## Priorité 4 - Disperse

### Pourquoi

Très utile pour les mécaniques AoE ou les combats où les bots doivent s'espacer.

### Commandes à couvrir

| Commande playerbots | Statut MultiBot | Priorité | Proposition UI |
|---|---:|---:|---|
| `disperse set <yards>` | Manquant | Moyenne | Champ distance + bouton Apply |
| `disperse disable` | Manquant | Moyenne | Bouton Disable |

### Proposition UI

Section simple :

```text
Disperse distance: [ 8 ] yards
[Apply] [Disable]
```

---

## Priorité 5 - Loot Rules / Loot List

### Pourquoi

Le contrôle du loot est utile, mais moins prioritaire que RTI/pull.

### Commandes à couvrir

| Commande playerbots | Statut MultiBot | Priorité | Proposition UI |
|---|---:|---:|---|
| `nc +loot` | Partiel | Moyenne | Toggle Loot |
| `nc -loot` | Partiel | Moyenne | Toggle Loot |
| `ll all` | Manquant | Moyenne | Profil Loot All |
| `ll normal` | Manquant | Moyenne | Profil Normal |
| `ll gray` | Manquant | Moyenne | Profil Gray |
| `ll quest` | Manquant | Moyenne | Profil Quest |
| `ll skill` | Manquant | Moyenne | Profil Skill |
| `ll [item]` | Manquant | Basse | Ajouter item depuis inventaire |
| `ll -[item]` | Manquant | Basse | Retirer item depuis inventaire |

### Proposition UI

Créer une section `Loot Rules` avec profils prédéfinis.

Les commandes `ll [item]` et `ll -[item]` peuvent être ajoutées plus tard via clic droit sur item dans l'inventaire bridge.

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

L'inventaire bridge-first est déjà en place. Ces commandes sont des améliorations secondaires.

### Commandes à couvrir

| Commande playerbots | Statut MultiBot | Priorité | Proposition UI |
|---|---:|---:|---|
| `open items` | À vérifier | Moyenne | Bouton dans inventaire |
| `roll` | Manquant | Moyenne | Bouton Roll |
| `roll [item]` | Manquant | Moyenne | Clic droit item |
| `s vendor` | À vérifier | Moyenne | Bouton Sell Vendor |
| `s *` | À vérifier | Moyenne | Bouton Sell Gray |
| `bank [item]` | Manquant | Basse | Clic droit item |
| `bank -[item]` | Manquant | Basse | UI banque |
| `gb [item]` | Manquant | Basse | Clic droit item |
| `gb -[item]` | Manquant | Basse | UI guild bank |
| `b [item]` | Manquant | Basse | UI vendor |

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
| 2 | Pull Control avancé | Nouvelle UI + séquences commandes | Haute | À faire |
| 3 | Advanced Combat Strategies | UI toggles | Haute/Moyenne | À faire |
| 4 | Disperse | Petite UI | Moyenne | À faire |
| 5 | Loot Rules | Petite UI profils | Moyenne | À faire |
| 6 | Trainer / Maintenance extras | UI maintenance | Moyenne/Basse | À faire |
| 7 | Items avancés | Extensions inventaire | Basse/Moyenne | À faire |

---

## Notes d'architecture

- Toute nouvelle commande utilisée automatiquement par l'addon devrait passer par le bridge quand possible.
- Les commandes manuelles informatives doivent rester fonctionnelles en whisper/party/raid.
- Ne pas réintroduire de parsing chat automatique pour peupler l'UI.
- Pour les commandes qui ne nécessitent aucun retour structuré, un endpoint générique de type `RUN~COMMAND` ou un endpoint spécialisé comme `RUN~RTI` peut suffire.
- Pour les commandes qui doivent alimenter une frame, préférer un endpoint structuré dédié.
- Les commandes serveur/admin ne doivent pas être exposées dans l'addon utilisateur.
- Les boutons ajoutés dans les barres doivent conserver une position cohérente avec `MultiBotLeftCoreUI.lua` et la position par défaut de `MultiBar` dans `MultiBotInit.lua` / reset dans `MultiBotMainUI.lua`.
- Les tooltips nouvellement ajoutés doivent passer par AceLocale, comme les tooltips RTI.
