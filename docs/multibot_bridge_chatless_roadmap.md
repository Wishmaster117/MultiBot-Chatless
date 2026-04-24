# MultiBot / Bridge — roadmap chatless

Dernière mise à jour : 2026-04-24

## Objectif exact

Rendre **MultiBot non dépendant du retour chat pour alimenter l’UI**, tout en gardant les commandes manuelles volontaires utilisables.

Commandes manuelles à conserver fonctionnelles :

- `who`
- `co ?`
- `nc ?`
- `ss ?`

Le but n’est pas de supprimer ces commandes. Le but est de ne plus les lancer automatiquement pour ouvrir ou remplir les fenêtres d’interface.

---

## État validé / stabilisé

### Socle bridge

- [x] Handshake `HELLO` / `HELLO_ACK`
- [x] `PING` / `PONG`
- [x] Détection addon côté bridge
- [x] Bootstrap au login / `/reload`
- [x] Logs console bridge configurables via `MultiBotBridge.EnableConsoleLogs`

### Roster / Units

- [x] `GET~ROSTER`
- [x] Roster bridge-first
- [x] Synchronisation des bots visibles dans `Units`
- [x] Refresh manuel `Units` via bridge quand disponible
- [x] Fallback legacy conservé quand la bridge n’est pas disponible

### States / Everybars

- [x] `GET~STATE~<bot>`
- [x] `GET~STATES`
- [x] Réception individuelle `STATE~<bot>~...`
- [x] Les states ne dépendent plus d’un gros payload global unique
- [x] Reconstruction des everybars depuis les states bridge
- [x] Correction de la régression où la première everybar se collait au bouton `selfbots`
- [x] Placement des everybars redonné au layout `Units`
- [x] Relayout différé après réception des states pour éviter les coordonnées par défaut après `/reload`

### Détail bot / Raidus

- [x] `GET~DETAIL~<bot>`
- [x] `GET~DETAILS`
- [x] Réception individuelle `DETAIL~<bot>~...`
- [x] Les détails ne dépendent plus d’un gros payload global unique
- [x] Cache addon `MultiBot.bridge.details`
- [x] Alimentation de `MultiBotGlobalSave`
- [x] Raidus peut récupérer classe / race / genre / niveau / talents / score sans dépendre du spam automatique `who`
- [x] Demande de détail bot au bootstrap et au `Hello` d’un bot

### Inventory snapshot

- [x] `GET~INVENTORY~<bot>~<token>`
- [x] `INV_BEGIN`
- [x] `INV_SUMMARY`
- [x] `INV_ITEM`
- [x] `INV_END`
- [x] Ouverture de la fenêtre inventory depuis bridge
- [x] Remplissage du contenu inventory depuis bridge
- [x] Fallback whisper `items` conservé si bridge indisponible

### Inventory post-action

- [x] Fonction centralisée `MultiBot.RequestInventoryRefresh(botName, delay)` en bridge-first
- [x] Fonction post-action `MultiBot.RequestInventoryPostActionRefresh(botName, firstDelay, secondDelay, options)`
- [x] Refresh automatique après equip / unequip / use / destroy / loot en bridge-first
- [x] Refresh différé en deux temps après action pour éviter les snapshots trop précoces
- [x] Correction du `u [item]` : décrément visuel + pending consume local pour éviter que le snapshot bridge trop tôt remette l’ancien stack
- [x] Correction du clic droit `ue` depuis Inspect : déséquipement puis refresh inventory bridge-first
- [x] Trade : suppression du dump legacy `=== Inventory ===` dans le chat quand la bridge est connectée
- [x] Fallback `items` gardé uniquement quand la bridge n’est pas disponible

### Spellbook

- [x] `GET~SPELLBOOK~<bot>~<token>`
- [x] `SB_BEGIN`
- [x] `SB_ITEM`
- [x] `SB_END`
- [x] `Comm.RequestSpellbook(name)`
- [x] Ouverture du spellbook via bridge
- [x] Remplissage du spellbook via bridge
- [x] Fallback whisper `spells` conservé si bridge indisponible

### PVP Stats

- [x] Endpoint prévu / ajouté côté bridge : `GET~PVP_STATS~<bot>`
- [x] Endpoint prévu / ajouté côté bridge : `GET~PVP_STATS`
- [x] Réception addon `PVP_STATS~<bot>~...`
- [x] Cache addon `MultiBot.bridge.pvpStats`
- [x] Hydratation de la fenêtre PVP depuis payload bridge
- [x] Boutons PVP Stats branchés en bridge-first
- [x] Filtre addon pour masquer les lignes legacy `[PVP] ...` si elles arrivent encore pendant la transition
- [ ] Validation ingame finale à confirmer : plus aucune ligne `[PVP] ...` dans le chat quand la bridge est connectée

---

## Règle importante sur les payloads volumineux

Avec beaucoup de bots, éviter les réponses globales trop grosses.

État attendu :

- `GET~STATES` répond avec plusieurs paquets `STATE~<bot>~...` ;
- `GET~DETAILS` répond avec plusieurs paquets `DETAIL~<bot>~...` ;
- `GET~PVP_STATS` peut répondre avec plusieurs paquets `PVP_STATS~<bot>~...` ;
- un paquet global vide peut seulement servir de réponse vide si aucun bot n’est disponible.

---

## Ce qui n’est plus à faire

### Spellbook

Le spellbook est migré sur le chemin nominal. Le whisper `spells` peut rester comme fallback, mais ne doit plus être le chemin normal quand la bridge est connectée.

### Détail bot / `who`

Le détail bot est sorti du chemin `who` pour l’UI. Les commandes manuelles `who`, `co ?`, `nc ?`, `ss ?` restent disponibles, mais l’UI ne doit plus dépendre automatiquement de leurs réponses.

### Inventory post-action

Le refresh UI après action inventory est maintenant bridge-first. Les commandes d’action réelles peuvent encore passer en whisper volontaire (`u`, `e`, `ue`, `s`, `destroy`, etc.), mais le refresh automatique de la fenêtre ne doit plus spammer `items` quand la bridge est connectée.

---

## Ce qui reste partiellement legacy

### A) Units / roster legacy de compatibilité

Encore présent à conserver ou à traiter plus tard selon le cas :

- fallback `.playerbot bot list` ;
- parsing `CHAT_MSG_SYSTEM` pour certains événements add/remove/offline ;
- commandes `.playerbot bot add/remove` toujours utilisées pour connecter/déconnecter les bots.

Conclusion : `Units` fonctionne en bridge-first pour roster/states/details, mais il reste des chemins legacy de compatibilité et de commande.

### B) Stats simples

Encore legacy :

- bouton stats global ;
- `SendChatMessage("stats", ...)` ;
- parsing des réponses stats.

C’est le prochain bloc logique après PVP Stats, parce que c’est read-only et très proche du travail déjà fait pour `PVP_STATS`.

### C) PVP Stats — validation finale

La migration est en place, mais il faut encore confirmer ingame après le dernier filtre legacy :

- clic PVP Stats whisper ;
- clic PVP Stats party ;
- clic PVP Stats raid ;
- aucune ligne `[PVP] ...` visible dans le chat si la bridge est connectée ;
- fallback legacy toujours utilisable si bridge absente.

### D) Talents / glyphes / specs détaillées

Encore legacy :

- `talents`
- `talents spec list`
- `glyphs`
- réponses chat parsées pour remplir les fenêtres.

À migrer après les blocs read-only plus simples.

### E) Outfits

Encore legacy :

- `outfit ?`
- parsing de réponse chat.

À migrer plus tard.

### F) Quêtes

Encore legacy côté MultiBot :

- certains menus de quête utilisent encore des commandes chat ;
- intégration Questie séparée à garder en tête.

À traiter après les blocs plus petits, sauf priorité spécifique.

---

## Tableau d’avancement

| Bloc | État actuel |
|---|---|
| Handshake bridge | Fait |
| Roster bridge | Fait |
| States bridge | Fait |
| States en paquets individuels | Fait |
| Details bridge | Fait |
| Details en paquets individuels | Fait |
| Raidus sans `who` automatique | Fait |
| Everybars après `/reload` | Corrigé |
| Units bridge-first | Fait |
| Units 100% sans chemins legacy | À finir |
| Inventory snapshot bridge | Fait |
| Inventory post-action bridge-first | Fait |
| Inventory `u item` stack/pending consume | Fait |
| Inspect `ue` refresh inventory | Fait |
| Trade sans dump inventory legacy | Fait |
| Spellbook bridge | Fait |
| PVP Stats bridge | Implémenté, validation finale à confirmer |
| Stats simples bridge | À faire |
| Talents / glyphes / specs bridge | À faire |
| Outfits bridge | À faire |
| Quêtes bridge | À faire |
| Nettoyage final parsers legacy | À faire |

---

## Prochain pas logique recommandé

Le prochain pas logique est : **migrer les Stats simples en bridge-first**.

Pourquoi maintenant :

- c’est read-only, donc peu risqué ;
- la logique ressemble beaucoup à `PVP_STATS` ;
- ça retire encore du whisper automatique `stats` ;
- ça évite d’attaquer tout de suite des blocs plus gros comme talents/glyphes/outfits/quêtes.

### Plan du prochain patch

1. Ajouter côté bridge :

```text
GET~STATS~<bot>
GET~STATS
```

2. Répondre avec un ou plusieurs paquets individuels :

```text
STATS~<bot>~...
```

3. Ajouter côté addon :

```lua
Comm.RequestStats(botName)
Comm.ApplyStatsPayload(payload)
MultiBot.ApplyBridgeStats(stats)
```

4. Brancher les boutons existants Stats sur la bridge.

5. Garder le fallback legacy `stats` uniquement si la bridge est absente.

6. Masquer temporairement les éventuelles lignes legacy de stats si un chemin ancien les produit encore pendant la transition.

---

## Règle de migration à conserver

Pour chaque fenêtre :

1. le bouton / l’action utilisateur peut encore envoyer une commande au bot si c’est une vraie action ;
2. le refresh automatique de l’UI doit passer par la bridge si elle est connectée ;
3. le fallback chat doit rester si la bridge est absente ;
4. les commandes manuelles historiques restent fonctionnelles.
