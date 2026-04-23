# MultiBot / Bridge — roadmap chatless mise à jour

## Objectif exact

Rendre **MultiBot non dépendant du retour chat pour construire et rafraîchir l’UI**.

Important :

- on **ne cherche pas à supprimer les commandes manuelles** que l’utilisateur peut volontairement envoyer aux bots ;
- les commandes comme `who`, `co ?`, `nc ?`, `ss ?` **doivent rester disponibles** ;
- la cible est de **retirer le spam chat utilisé comme bus de données UI**, pas de casser les commandes utiles.

En pratique :

- **commande volontaire** : peut encore exister ;
- **alimentation des fenêtres et refresh UI** : doit passer par le bridge.

---

## Base réellement auditée

Analyse faite sur les ZIP actuellement fournis :

### Bridge
- `mod-multibot-bridge/src/MultiBotBridge.cpp`
- `mod-multibot-bridge/conf/MultiBotBridge.conf.dist`

### Addon
- `MultiBot/Core/MultiBot.lua`
- `MultiBot/Core/MultiBotComm.lua`
- `MultiBot/Core/MultiBotHandler.lua`
- `MultiBot/Core/MultiBotEvery.lua`
- `MultiBot/UI/MultiBotUnitsRootUI.lua`
- `MultiBot/UI/MultiBotInventoryFrame.lua`
- `MultiBot/UI/MultiBotInventoryItem.lua`
- `MultiBot/UI/MultiBotSpell.lua`
- `MultiBot/UI/MultiBotSpellBookFrame.lua`
- `MultiBot/UI/MultiBotOutfitUI.lua`
- `MultiBot/UI/MultiBotTalentFrame.lua`
- `MultiBot/UI/MultiBotQuestsMenu.lua`

---

## État global actuel

Le chantier a bien avancé, mais le module n’est **pas encore totalement chatless**.

### Ce qui est déjà acquis

- socle bridge stable : handshake + heartbeat ;
- bootstrap principal du panneau **Units** en bridge-first ;
- refresh **roster/states** via bridge ;
- inventaire d’un bot : **ouverture et contenu principal** désormais fournis par le bridge.

### Ce qui n’est pas encore acquis

- fallback login legacy via `.playerbot bot list` toujours présent ;
- `CHAT_MSG_SYSTEM` reste encore une source de vérité utile à certains moments ;
- spellbook encore entièrement nourri par le chat ;
- plusieurs panneaux secondaires restent encore chat-driven ;
- certaines réactions post-action inventory reposent encore sur des messages système / loot.

---

## 1) Ce qui est effectivement fait

## M0 — socle bridge

### Fait
- [x] `HELLO` / `HELLO_ACK`
- [x] `PING` / `PONG`
- [x] `GET~ROSTER`
- [x] `GET~STATE~<bot>`
- [x] `GET~STATES`
- [x] application des states bridge dans l’UI Units

### Commentaire
Le bridge expose déjà un noyau exploitable pour le roster et les strategies combat / non-combat.

**Statut** : fait

---

## M1 — Units bridge-first

### Fait
- [x] bootstrap bridge au login ;
- [x] refresh manuel du bouton Units via bridge ;
- [x] hydratation des everybars à partir de `GET~STATES` ;
- [x] réduction des refreshs parasites côté panneau Units.

### Encore présent
- [ ] fallback `.playerbot bot list` si le bootstrap bridge n’aboutit pas assez vite ;
- [ ] parser `CHAT_MSG_SYSTEM` legacy toujours actif pour une partie du cycle roster / add / remove / offline ;
- [ ] dépendance chat pour certains flux de détail / resynchro fine.

### Diagnostic
Le panneau Units est **bien avancé**, mais **pas encore 100% chatless** dans le code actuel.

**Statut** : en grande partie fait, pas terminé

---

## M2 — Inventory principal en bridge

### Fait
- [x] endpoint bridge `GET~INVENTORY~<bot>~<token>` ;
- [x] réponses bridge :
  - [x] `INV_BEGIN`
  - [x] `INV_SUMMARY`
  - [x] `INV_ITEM`
  - [x] `INV_END`
- [x] ouverture de la fenêtre inventaire sur requête bridge ;
- [x] remplissage des items depuis les paquets bridge ;
- [x] restauration de l’ouverture d’inspection avec la fenêtre inventaire.

### Encore présent
- [ ] certains refreshs après action item utilisent encore des déclencheurs chat (`equipping`, `using`, `destroyed`, `opened`, `CHAT_MSG_LOOT`) ;
- [ ] le parser inventory legacy existe encore comme compatibilité / secours.

### Diagnostic
Le **gros spam de construction de fenêtre inventory** n’est plus le chemin nominal.
En revanche, la **boucle complète post-action inventory** n’est pas encore totalement sortie du chat.

**Statut** : fait pour l’ouverture et le contenu principal, finition encore à faire

---

## 2) Ce qui reste encore chat-dépendant dans le code actuel

## R1 — fallback login legacy

Toujours présent côté addon :

- `.playerbot bot list` peut encore partir au login / bootstrap ;
- le roster legacy peut encore être reconstruit par `CHAT_MSG_SYSTEM`.

### Conséquence
Tant que ce fallback reste dans le chemin nominal, on ne peut pas dire que Units est totalement découplé du chat.

---

## R2 — parser `CHAT_MSG_SYSTEM` encore utile

Le handler contient encore de la logique fonctionnelle pour :

- `add:` / `remove:` ;
- `player already logged in` ;
- bot offline / not online ;
- divers refreshs opportunistes historiques.

### Conséquence
Le chat système n’est pas encore réduit à un simple rôle de debug / compatibilité.

---

## R3 — détail bot encore chat-driven

Les flux de détail reposent encore sur les réponses à :

- `who`
- `co ?`
- `nc ?`
- `ss ?`

### Important
Ces commandes **doivent rester disponibles** pour un usage manuel.
Ce qu’il faut supprimer, c’est leur rôle de **source obligatoire de données UI**.

### Conséquence
Le détail d’un bot n’a pas encore son endpoint bridge propre.

---

## R4 — Spellbook encore 100% chat

Dans le code actuel, l’ouverture du spellbook fait encore :

- `SendChatMessage("spells", "WHISPER", nil, botName)` ;
- parsing séquentiel via `handleSpellbookChatLine`.

### Conséquence
C’est encore une source majeure de spam et de dépendance au retour texte.

---

## R5 — Stats / talents / outfits / quêtes / PVP encore legacy

Restent encore principalement alimentés par chat, ou au minimum orchestrés autour de réponses texte :

- stats ;
- talents / specs custom / glyphes ;
- outfits ;
- quêtes ;
- PVP stats.

### Conséquence
Le bridge ne couvre pas encore la majorité des panneaux secondaires.

---

## 3) Ce qui a changé depuis la roadmap précédente

### Avancement réel supplémentaire
- l’inventaire a franchi une vraie étape : il n’est plus construit uniquement à partir des whispers `items` ;
- le bridge sait maintenant transporter un snapshot inventory exploitable par l’UI ;
- le flux principal Units reste stable en bridge-first.

### Point important
La précédente roadmap pouvait laisser entendre que **spellbook** était déjà dans la prochaine phase logique.
Dans le code actuellement fourni, c’est bien toujours vrai :

- **inventory principal : oui, déjà migré en grande partie** ;
- **spellbook : non, toujours legacy**.

---

## 4) Priorisation recommandée à partir de l’état actuel

## Phase A — finir vraiment Units

À faire :

- [ ] retirer le fallback `.playerbot bot list` du chemin normal ;
- [ ] faire du bridge la seule source normale pour roster + states ;
- [ ] laisser le parser système uniquement en compat/debug transitoire.

### Résultat visé
Le panneau Units doit rester fonctionnel même si aucun retour texte legacy n’est exploité.

---

## Phase B — migrer Spellbook

À faire côté bridge :

- [ ] `GET~SPELLBOOK~<bot>~<token>` ;
- [ ] réponses du type `SPELL_BEGIN`, `SPELL_ITEM`, `SPELL_FOOTER`, `SPELL_END` ou payload équivalent plus structuré.

À faire côté addon :

- [ ] remplacer `SendChatMessage("spells", ...)` par une requête bridge ;
- [ ] remplir `MultiBot.spellbook` à partir des payloads bridge ;
- [ ] garder le parser chat seulement en fallback temporaire.

### Pourquoi maintenant
Le spellbook est **la plus grosse source de spam restante** parmi les panneaux déjà ciblés.

---

## Phase C — sortir le détail bot du chat

À faire côté bridge :

- [ ] `GET~DETAIL~<bot>` ou équivalent.

Payload à couvrir :

- infos actuellement déduites de `who` ;
- strategies combat / non-combat détaillées ;
- état utile pour afficher / rafraîchir les everybars sans parser les whispers.

### Contrainte de projet
Même après migration :

- `who`
- `co ?`
- `nc ?`
- `ss ?`

restent disponibles manuellement.

### But réel
Ne plus avoir besoin de leurs **réponses chat** pour faire marcher l’UI.

---

## Phase D — finir inventory post-action

À faire :

- [ ] remplacer les refreshs déclenchés par texte après equip / use / destroy / loot ;
- [ ] faire recharger l’inventory via bridge après action connue côté addon ;
- [ ] réduire `CHAT_MSG_LOOT` à un rôle optionnel.

### Résultat visé
Inventory totalement chatless, y compris après interaction sur les items.

---

## Phase E — stats / talents / specs / glyphes / outfits / quêtes / PVP

À faire côté bridge, par blocs :

- [ ] `GET~STATS~<bot>`
- [ ] `GET~TALENTS~<bot>`
- [ ] `GET~GLYPHS~<bot>`
- [ ] `GET~OUTFITS~<bot>`
- [ ] `GET~QUESTS~<bot>~all|completed|incompleted`
- [ ] `GET~PVP~<bot>`

### Note
Il vaut mieux migrer **panneau par panneau**, puis supprimer son parser chat dédié seulement une fois la version bridge validée.

---

## 5) Tableau de suivi compact

| Milestone | Sujet | État actuel |
|---|---|---|
| M0 | Handshake / roster / states bridge | Fait |
| M1 | Units bridge-first | Fait en grande partie |
| M1b | Units 100% chatless | À finir |
| M2 | Inventory principal bridge | Fait en grande partie |
| M2b | Inventory post-action 100% chatless | À finir |
| M3 | Spellbook bridge | À faire |
| M4 | Détail bot bridge | À faire |
| M5 | Stats / talents / glyphes / specs | À faire |
| M6 | Outfits / quêtes / PVP | À faire |
| M7 | Nettoyage final des parsers legacy | À faire |

---

## 6) Prochain pas recommandé

Le prochain pas le plus rentable, au vu du code actuel, est :

1. **migrer Spellbook sur le bridge** ;
2. ensuite **sortir le détail bot (`who`, `co ?`, `nc ?`, `ss ?`) de la dépendance UI** ;
3. puis **finir inventory post-action** ;
4. enfin attaquer stats / talents / outfits / quêtes.

Pourquoi cet ordre :

- inventory principal est déjà largement sorti du chat ;
- spellbook reste une grosse source de spam ;
- le détail bot est important, mais moins volumineux que le flux spellbook ;
- terminer inventory post-action après ça permettra d’avoir un bloc inventory vraiment propre de bout en bout.

---

## 7) Point de vérité final

### Ce qu’on peut affirmer aujourd’hui
- **Units** : bridge-first, mais pas encore 100% chatless ;
- **Inventory** : principale ouverture/lecture migrée en bridge, mais pas totalement finie ;
- **Spellbook** : encore legacy ;
- **reste des panneaux** : encore majoritairement legacy.

### Donc
Le projet a déjà dépassé le simple prototype bridge : il a maintenant un vrai noyau exploitable.
Mais il reste encore **plusieurs dépendances chat structurelles** avant de pouvoir dire que MultiBot est réellement chatless.
