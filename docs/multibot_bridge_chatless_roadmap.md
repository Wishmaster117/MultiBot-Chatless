# MultiBot / Bridge — roadmap chatless

## Objectif

Rendre MultiBot **bridge-first** pour toutes les fenêtres d’interface : l’addon ne doit plus dépendre des réponses chat des bots pour construire l’UI.

Les commandes manuelles doivent rester fonctionnelles :

- `who`
- `co ?`
- `nc ?`
- `ss ?`
- commandes utilisateur volontaires comme `items`, `spells`, `stats`, etc.

La cible n’est donc pas de supprimer les commandes playerbot, mais de ne plus les utiliser comme transport automatique pour ouvrir/remplir les fenêtres.

---

## État validé actuellement

### 1) Socle bridge

- [x] Handshake `HELLO` / `HELLO_ACK`.
- [x] `PING` / `PONG`.
- [x] Logs console bridge configurables via `MultiBotBridge.EnableConsoleLogs`.
- [x] Réception addon centralisée dans `MultiBotComm.lua`.
- [x] Fallback legacy conservé quand la bridge n’est pas disponible.

### 2) Roster / Units / states

- [x] `GET~ROSTER`.
- [x] `GET~STATE~<bot>`.
- [x] `GET~STATES`.
- [x] Envoi des states en paquets individuels `STATE` pour éviter les payloads trop gros avec beaucoup de bots.
- [x] Bootstrap Units bridge-first.
- [x] Refresh manuel Units bridge-first.
- [x] Reconnexion / `/reload` corrigés : les states reviennent sans dépendre du flux `Hello` legacy.
- [x] Régression everybars corrigée : `ApplyBridgeBotState()` ne place plus les bars trop tôt ; le placement est repris par le relayout Units.

### 3) Détail bot / données type `who`

- [x] Endpoint bridge ajouté : `GET~DETAIL~<bot>`.
- [x] Endpoint bridge ajouté : `GET~DETAILS`.
- [x] Réponse individuelle `DETAIL`.
- [x] Hydratation côté addon dans `MultiBot.bridge.details`.
- [x] Mise à jour de `MultiBotGlobalSave` via `MultiBot.ApplyBridgeBotDetail()`.
- [x] Raidus / roster peuvent récupérer les infos de base sans spam automatique `who`.

Données actuellement couvertes :

- nom ;
- race ;
- genre ;
- classe ;
- niveau ;
- points par arbre de talents ;
- score d’équipement approximatif.

Les commandes manuelles `who`, `co ?`, `nc ?`, `ss ?` restent utilisables.

### 4) Inventory snapshot

- [x] `GET~INVENTORY~<bot>~<token>`.
- [x] `INV_BEGIN`.
- [x] `INV_SUMMARY`.
- [x] `INV_ITEM`.
- [x] `INV_END`.
- [x] Ouverture inventory bridge-first.
- [x] Remplissage inventory bridge-first.
- [x] Fallback `items` conservé uniquement si la bridge n’est pas disponible.

### 5) Inventory post-action

- [x] Helper centralisé `MultiBot.RequestInventoryRefresh(botName, delay, options)`.
- [x] Helper post-action `MultiBot.RequestInventoryPostActionRefresh(botName, firstDelay, secondDelay, options)`.
- [x] Refresh après equip / use / destroy / loot bridge-first.
- [x] Refresh après déséquipement depuis Inspect bridge-first.
- [x] Correction du timing : refresh différé pour éviter de prendre un snapshot trop tôt.
- [x] Correction `u <item>` : décrément local pending pour éviter que le snapshot bridge trop précoce remette l’ancien stack.
- [x] Refresh après `TRADE_CLOSED` bridge-first.
- [x] Suppression du fallback chat `items` après trade quand la bridge est connectée.
- [x] Filtre du dump inventory legacy déclenché par le bouton Trade (`=== Inventory === ... Off with you`) quand la bridge est connectée.

Note importante : le dump legacy lié au trade peut encore être émis par le serveur/playerbot, mais l’addon ne l’utilise plus pour fonctionner et il est masqué côté UI quand la bridge est disponible.

### 6) Spellbook

- [x] `GET~SPELLBOOK~<bot>~<token>`.
- [x] `SB_BEGIN`.
- [x] `SB_ITEM`.
- [x] `SB_END`.
- [x] `Comm.RequestSpellbook(name)`.
- [x] Ouverture spellbook bridge-first.
- [x] Remplissage spellbook bridge-first.
- [x] Fallback `spells` conservé uniquement si la bridge n’est pas disponible.

---

## Tableau d’avancement

| Bloc | État actuel |
|---|---|
| Socle bridge | Fait |
| Roster bridge | Fait |
| States bridge | Fait |
| Units bridge-first | Fait |
| Everybars après `/reload` | Corrigé |
| Détail bot bridge | Fait |
| Inventory snapshot bridge | Fait |
| Inventory post-action bridge-first | Fait |
| Trade inventory dump visible | Masqué côté addon quand bridge connectée |
| Spellbook bridge | Fait |
| Stats classiques | À migrer |
| PVP stats | À migrer |
| Talents détaillés | À migrer |
| Glyphes | À migrer |
| Specs détaillées / switch specs | Partiellement legacy |
| Outfits | À migrer |
| Quêtes | À migrer |
| Nettoyage final parsers legacy | À faire en dernier |

---

## Legacy encore présent et accepté pour l’instant

Ces chemins restent volontairement présents tant que leur équivalent bridge n’est pas terminé :

- commandes d’action utilisateur : `u`, `e`, `ue`, `s`, `destroy`, `cast`, `talents apply`, etc. ;
- commandes manuelles de diagnostic : `who`, `co ?`, `nc ?`, `ss ?` ;
- fallback inventory `items` si bridge absente ;
- fallback spellbook `spells` si bridge absente ;
- fallback Units `.playerbot bot list` si bridge absente ou bootstrap incomplet ;
- certains signaux système `CHAT_MSG_SYSTEM` pour add/remove/offline ;
- stats / pvp stats / talents / glyphes / outfits / quêtes.

---

## Points techniques validés

### Paquets individuels au lieu de gros snapshots globaux

Pour les groupes/raids avec beaucoup de bots, les réponses globales trop longues sont fragiles. Les states et détails sont maintenant mieux traités avec des paquets individuels :

- `STATE~<bot>~...`
- `DETAIL~<bot>~...`

C’est le modèle à privilégier pour les prochains endpoints volumineux.

### UI : ne pas placer les frames depuis les handlers bridge

Les handlers bridge doivent hydrater les données, pas décider directement du layout final. Le placement visuel doit rester dans les modules UI dédiés, par exemple `MultiBotUnitsRootUI.lua` pour les bars Units.

### Inventory : bridge-first avec fallback strict

La règle actuelle est :

1. bridge connectée : requête bridge ;
2. bridge connectée mais requête impossible : ne pas spammer le chat automatiquement sur les chemins post-action sensibles ;
3. bridge absente : fallback legacy.

---

## Prochaine modification logique

### Migrer Stats / PVP Stats en bridge-first

C’est la prochaine étape la plus logique parce que :

- c’est un bloc read-only, donc peu risqué ;
- il génère encore du whisper automatique (`stats`, `pvp stats`) ;
- les données sont proches du modèle `DETAIL` déjà en place ;
- ça supprimera un autre gros bloc de parsing chat sans toucher aux commandes manuelles.

Plan recommandé :

1. Ajouter côté bridge :
   - `GET~STATS~<bot>` ;
   - `GET~PVP_STATS~<bot>` ;
   - éventuellement `GET~STATS_ALL` / `GET~PVP_STATS_ALL` mais avec réponses individuelles, pas gros payload unique.
2. Ajouter côté addon :
   - `Comm.RequestStats(botName)` ;
   - `Comm.RequestPvpStats(botName)` ;
   - `ApplyBridgeStatsPayload()` ;
   - `ApplyBridgePvpStatsPayload()`.
3. Brancher les boutons existants :
   - bouton stats global ;
   - bouton PVP stats Units ;
   - refresh automatique éventuel.
4. Garder `stats` et `pvp stats` en fallback si la bridge est absente.
5. Ne pas encore supprimer les parsers legacy : les neutraliser seulement quand le chemin bridge est validé ingame.

---

## Étapes suivantes après Stats / PVP Stats

1. Talents détaillés / glyphes en bridge-first.
2. Specs détaillées et liste des specs en bridge-first.
3. Outfits en bridge-first.
4. Quêtes en bridge-first, probablement en plusieurs sous-étapes.
5. Nettoyage final des parsers chat devenus inutiles.

---

## Résumé court

Ce qui est maintenant solide :

- roster / states / Units ;
- détail bot ;
- inventory snapshot ;
- inventory post-action ;
- use item avec décrément stable ;
- inspect unequip + refresh inventory ;
- trade sans dump inventory visible ;
- spellbook.

Le prochain bloc à sortir du chat est **Stats / PVP Stats**, parce que c’est le meilleur ratio gain/risque avant d’attaquer talents, glyphes, outfits et quêtes.
