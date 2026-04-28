# MultiBot - Roadmap commandes manquantes à ajouter

## Objectif

Ce document suit les commandes `mod-playerbots` encore intéressantes à intégrer dans l'addon MultiBot, en distinguant :

- les commandes utiles dans une interface joueur ;
- les commandes à garder uniquement en usage manuel ;
- les commandes serveur/admin à ne pas intégrer dans l'addon ;
- les priorités d'intégration bridge-first/chatless.

Le principe reste le même que pour Inventory, Spellbook, Glyphs, Talents, Stats, Quests, Outfits, RTI et Pull Control :  
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
| Pull Control | Fait / à fignoler | Mini-frame MainBar + bridge `RUN~COMBAT`, séquences de commandes, scopes et presets. |

---

## Dernier lot terminé : Pull Control

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

Notes fonctionnelles importantes :

- Les commandes `co ?`, `nc ?`, `ss ?` restent manuelles et ne doivent pas devenir une source de parsing automatique.
- Le fait qu'une stratégie apparaisse ou non dans `co ?` dépend du nom exact réellement reconnu côté playerbots. Pour le Pull Control, on garde les noms qui ont été validés via bridge/serveur.
- `wait for attack time X` n'est pas une stratégie `co`, donc il ne faut pas attendre qu'elle apparaisse forcément dans `co ?`.

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
[Bot RTI Action] [Pull Control] [Attaque Tank]
  └─ Bot RTI Action : Attaquer / Pull pour les bots ayant une RTI personnelle
  └─ Pull Control : mini-frame de pull, wait, focus, assist, AoE et actions RTI
```

- `Attaquer` envoie `attack rti target` à tous les bots ayant une RTI personnelle mémorisée.
- `Pull` envoie `pull rti target` à tous les bots ayant une RTI personnelle mémorisée.
- `Pull Control` permet d'envoyer les mêmes actions RTI avec un scope choisi.

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

**Prochaine étape logique.**

Pull Control a posé la base technique : l'addon sait maintenant envoyer des commandes combat simples via `RUN~COMBAT`. La suite naturelle est donc d'exposer les stratégies combat utiles qui ne sont pas strictement liées au pull.

### Pourquoi

Ces stratégies existent côté playerbots mais ne sont pas toutes exposées clairement dans MultiBot. Elles ont une vraie utilité en raid/donjon, mais ne doivent pas encombrer la MainBar.

### Commandes à couvrir

| Stratégie | Commande | Statut MultiBot | Priorité | Intérêt |
|---|---|---:|---:|---|
| Avoid AoE | `co +avoid aoe` / `co -avoid aoe` | À vérifier / probablement partiel | Haute | Évite les AoE dangereuses |
| Save Mana | `co +save mana` / `co -save mana` | Manquant | Haute | Gestion mana healers/casters |
| Threat | `co +threat` / `co -threat` | Manquant | Haute | Limite la prise d'aggro selon comportement playerbots |
| Tank Face | `co +tank face` / `co -tank face` | Manquant | Moyenne | Gestion orientation tank, cleaves, breaths |
| Behind | `co +behind` / `co -behind` | Manquant ou déjà visible selon states | Moyenne | Placement melee derrière la cible |
| Healer DPS | `co +healer dps` / `co -healer dps` | À vérifier | Moyenne | Autorise/interdit le DPS des healers |
| Boost | `co +boost` / `co -boost` | Probablement partiel | Moyenne | Burst cooldowns |
| Focus | `co +focus` / `co -focus` | Fait via Pull Control | Référence | Focus mono-cible |
| DPS Assist | `co +dps assist` / `co -dps assist` | Fait via Pull Control | Référence | Assist DPS |
| DPS AoE | `co +dps aoe` / `co -dps aoe` | Fait via Pull Control | Référence | Autorise AoE DPS |
| Wait for attack | `wait for attack time X` | Fait via Pull Control | Référence | Pull contrôlé |

### Proposition UI

Créer une page ou mini-frame `Advanced Combat`, séparée de Pull Control :

```text
Combat Strategies
├─ Scope: Selected / Party / Raid
├─ Survivability: Avoid AoE, Threat
├─ Positioning: Behind, Tank Face
├─ Resource: Save Mana
├─ Damage policy: Healer DPS, Boost
└─ Apply toggles via RUN~COMBAT
```

Recommandation UX :

- ne pas ajouter ces toggles directement sur la MainBar ;
- créer un panneau repliable ou une sous-page accessible depuis un bouton existant de stratégies/combat ;
- réutiliser les scopes `BOT`, `GROUP`, `ALL` déjà validés par Pull Control ;
- garder `co ?` comme vérification manuelle, sans parser automatiquement son retour.

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

### Note

À faire après `Advanced Combat`, sauf si un besoin immédiat de mécaniques AoE impose de le passer avant.

---

## Priorité 5 - Loot Rules / Loot List

### Pourquoi

Le contrôle du loot est utile, mais moins prioritaire que RTI/pull/combat.

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
| 2 | Pull Control avancé | Nouvelle UI + séquences commandes | Haute | Fait / à fignoler |
| 3 | Advanced Combat Strategies | UI toggles réutilisant `RUN~COMBAT` | Haute/Moyenne | Prochaine étape |
| 4 | Disperse | Petite UI + commande combat/mouvement | Moyenne | À faire |
| 5 | Loot Rules | Petite UI profils | Moyenne | À faire |
| 6 | Trainer / Maintenance extras | UI maintenance | Moyenne/Basse | À faire |
| 7 | Items avancés | Extensions inventaire | Basse/Moyenne | À faire |

---

## Notes d'architecture

- Toute nouvelle commande utilisée automatiquement par l'addon devrait passer par le bridge quand possible.
- Les commandes manuelles informatives doivent rester fonctionnelles en whisper/party/raid.
- Ne pas réintroduire de parsing chat automatique pour peupler l'UI.
- Pour les commandes qui ne nécessitent aucun retour structuré, un endpoint générique de type `RUN~COMMAND` ou un endpoint spécialisé comme `RUN~RTI` / `RUN~COMBAT` peut suffire.
- Pour les commandes qui doivent alimenter une frame, préférer un endpoint structuré dédié.
- Les commandes serveur/admin ne doivent pas être exposées dans l'addon utilisateur.
- Les boutons ajoutés dans les barres doivent conserver une position cohérente avec `MultiBotLeftCoreUI.lua` et la position par défaut de `MultiBar` dans `MultiBotInit.lua` / reset dans `MultiBotMainUI.lua`.
- Les tooltips nouvellement ajoutés doivent passer par AceLocale, comme les tooltips RTI et Pull Control.
- `RUN~COMBAT` doit rester whitelisté côté bridge : ne pas en faire un exécuteur libre de n'importe quelle commande chat.

---

## Point logique suivant

Le prochain bloc logique est **Advanced Combat Strategies**.

Raison : `RUN~COMBAT` existe maintenant, les scopes sont validés, et Pull Control a déjà prouvé que l'addon peut envoyer proprement des toggles de stratégie sans spam chat. Le plus rentable est donc d'ajouter une UI dédiée aux stratégies combat permanentes ou semi-permanentes : `avoid aoe`, `save mana`, `threat`, `behind`, `tank face`, `healer dps`, `boost`.

Ce bloc doit rester séparé de Pull Control : Pull Control sert aux séquences de pull, tandis qu'Advanced Combat sert aux comportements généraux des bots pendant les combats.
