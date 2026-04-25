# MultiBot / Bridge — roadmap chatless

Dernière mise à jour : 2026-04-25

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

- [x] Endpoint côté bridge : `GET~PVP_STATS~<bot>`
- [x] Endpoint côté bridge : `GET~PVP_STATS`
- [x] Réception addon `PVP_STATS~<bot>~...`
- [x] Cache addon `MultiBot.bridge.pvpStats`
- [x] Hydratation de la fenêtre PVP depuis payload bridge
- [x] Boutons PVP Stats branchés en bridge-first
- [x] Filtre addon pour masquer les lignes legacy `[PVP] ...` si elles arrivent encore pendant la transition
- [x] Validation ingame : PVP Stats exploitable via bridge, fallback legacy conservé

### Stats simples

- [x] Endpoint côté bridge : `GET~STATS~<bot>`
- [x] Endpoint côté bridge : `GET~STATS`
- [x] Réception addon `STATS~<bot>~...`
- [x] Cache addon `MultiBot.bridge.stats`
- [x] Hydratation de la fenêtre Stats depuis payload bridge
- [x] Bouton Auto-Stats branché en bridge-first
- [x] Correction compilation C++ : déclaration anticipée de `GetPct`
- [x] Fallback legacy `stats` conservé si bridge absente

### Quêtes

- [x] Endpoint côté bridge : `GET~QUESTS~INCOMPLETED~<bot>~<token>`
- [x] Endpoint côté bridge : `GET~QUESTS~COMPLETED~<bot>~<token>`
- [x] Endpoint côté bridge : `GET~QUESTS~ALL~<bot>~<token>`
- [x] Variantes groupe/raid avec `<bot>` vide
- [x] Réponses en paquets courts : `QUESTS_BEGIN`, `QUESTS_ITEM`, `QUESTS_END`, `QUESTS_DONE`
- [x] Branchement des fenêtres `QuestIncomplete`, `QuestCompleted` et `QuestAll` en bridge-first
- [x] Correction C++ : lecture du quest log runtime via `GetQuestSlotQuestId()` / `GetQuestStatus()` avant fallback DB
- [x] Correction addon : rebuild de la vue `QuestAll` d’un bot ciblé sans forcer l’agrégat groupe
- [x] Validation ingame : les frames affichent les quêtes via bridge et ne dépendent plus du spam chat des listes de quêtes
- [x] Fallback legacy conservé si la bridge est absente

### Talents / sélection de specs

- [x] Endpoint côté bridge : `GET~TALENT_SPEC_LIST~<bot>~<token>`
- [x] Réponses en paquets courts : `TALENT_SPEC_BEGIN`, `TALENT_SPEC_ITEM`, `TALENT_SPEC_END`
- [x] Lecture côté bridge des specs disponibles depuis `AiPlayerbot.PremadeSpecName.*` / `AiPlayerbot.PremadeSpecLink.*`
- [x] Reconstruction de la frame de choix des specs depuis la bridge
- [x] Suppression du spam automatique `talents spec list` dans le chat quand la bridge est connectée
- [x] Conservation volontaire du whisper utile `My current talent spec is: ...`
- [x] Filtrage des lignes d’aide legacy inutiles renvoyées par `talents` (`warlock`, `Talents usage`, etc.)
- [x] Correction affichage : la partie `(0/56/15)` de la spé courante est ré-affichée en blanc
- [x] Fallback legacy `talents spec list` conservé si la bridge est absente

### Glyphes / Custom Glyphs

- [x] Endpoint côté bridge : `GET~GLYPHS~<bot>~<token>`
- [x] Réponses en paquets courts : `GLYPHS_BEGIN`, `GLYPHS_ITEM`, `GLYPHS_END`
- [x] Envoi par item de `slot`, `itemId`, `glyphId`, `spellId`, avec fallback serveur pour retrouver l’`itemId` quand il n’est pas directement disponible
- [x] Correction serveur : résolution des items de glyphes via `item_template` et les effets de spell liés au `glyphId` / `spellId`
- [x] Réception addon `Comm.RequestGlyphs(botName)`
- [x] Hydratation de la frame `Glyphs` depuis la bridge
- [x] Affichage des icônes réelles des glyphes dans les sockets
- [x] Tooltips fonctionnels via lien item, avec fallback spell si nécessaire
- [x] Couleur / glow des sockets adaptée à la classe du bot
- [x] Nettoyage de `MultiBot.awaitGlyphs` quand la bridge répond pour éviter le message `[ERROR] Message nonglyphe ignoré`
- [x] Fallback whisper `glyphs` conservé seulement si la bridge est absente ou ne répond pas
- [x] Correction navigation : le bouton `Custom Talents` reconstruit les arbres vides sans dépendre obligatoirement de l’API d’inspection
- [x] Correction `Custom Glyphs` : séparation entre `socketType` et `glyphType` pour ne plus écraser le type attendu du socket
- [x] Correction `Custom Glyphs` : mapping ordre bridge/playerbots vers ordre visuel des sockets
- [x] Correction `Custom Glyphs` : `glyph equip` renvoie les IDs dans l’ordre attendu par playerbots, pas dans l’ordre visuel
- [x] Nettoyage : suppression du message debug local `[DBG] glyph equip ...` après validation

---

## Règle importante sur les payloads volumineux

Avec beaucoup de bots, éviter les réponses globales trop grosses.

État attendu :

- `GET~STATES` répond avec plusieurs paquets `STATE~<bot>~...` ;
- `GET~DETAILS` répond avec plusieurs paquets `DETAIL~<bot>~...` ;
- `GET~PVP_STATS` peut répondre avec plusieurs paquets `PVP_STATS~<bot>~...` ;
- `GET~STATS` peut répondre avec plusieurs paquets `STATS~<bot>~...` ;
- `GET~QUESTS` répond en paquets `QUESTS_BEGIN` / `QUESTS_ITEM` / `QUESTS_END` / `QUESTS_DONE` pour éviter le spam chat et les payloads trop longs ;
- `GET~TALENT_SPEC_LIST` répond en paquets `TALENT_SPEC_BEGIN` / `TALENT_SPEC_ITEM` / `TALENT_SPEC_END` ;
- `GET~GLYPHS` répond en paquets `GLYPHS_BEGIN` / `GLYPHS_ITEM` / `GLYPHS_END` ;
- un paquet global vide peut seulement servir de réponse vide si aucun bot n’est disponible.

---

## Ce qui n’est plus à faire

### Spellbook

Le spellbook est migré sur le chemin nominal. Le whisper `spells` peut rester comme fallback, mais ne doit plus être le chemin normal quand la bridge est connectée.

### Détail bot / `who`

Le détail bot est sorti du chemin `who` pour l’UI. Les commandes manuelles `who`, `co ?`, `nc ?`, `ss ?` restent disponibles, mais l’UI ne doit plus dépendre automatiquement de leurs réponses.

### Inventory post-action

Le refresh UI après action inventory est maintenant bridge-first. Les commandes d’action réelles peuvent encore passer en whisper volontaire (`u`, `e`, `ue`, `s`, `destroy`, etc.), mais le refresh automatique de la fenêtre ne doit plus spammer `items` quand la bridge est connectée.

### Quêtes

Les fenêtres de quêtes (`incompleted`, `completed`, `all`) sont migrées sur la bridge. Les commandes legacy de quêtes peuvent rester comme fallback, mais le chemin normal n’a plus besoin de parser les listes envoyées en chat.

### Sélection de specs

La liste de choix des specs ne dépend plus de `talents spec list` en chat. Le whisper `talents` reste volontairement utilisé pour conserver la ligne utile `My current talent spec is: ...`, mais les lignes d’aide legacy sont filtrées côté addon.

### Glyphes

La lecture des glyphes n’est plus dépendante du whisper `glyphs` quand la bridge est connectée. Les icônes, tooltips, sockets et couleurs de classe sont alimentés par `GET~GLYPHS`. Les actions réelles de modification restent autorisées en commande volontaire, notamment `glyph equip ...`, conformément à la règle de migration.

---

## Ce qui reste partiellement legacy

### A) Units / roster legacy de compatibilité

Encore présent à conserver ou à traiter plus tard selon le cas :

- fallback `.playerbot bot list` ;
- parsing `CHAT_MSG_SYSTEM` pour certains événements add/remove/offline ;
- commandes `.playerbot bot add/remove` toujours utilisées pour connecter/déconnecter les bots.

Conclusion : `Units` fonctionne en bridge-first pour roster/states/details, mais il reste des chemins legacy de compatibilité et de commande.

### B) Talents actifs détaillés

Encore à évaluer :

- `talents` reste volontairement utilisé pour afficher la spé courante ;
- la sélection des specs est déjà migrée ;
- les arbres `Custom Talents` peuvent s’afficher sans dépendre obligatoirement de l’inspection ;
- il faut encore décider si l’UI a besoin d’un endpoint bridge pour les talents actifs détaillés, ou si l’état actuel suffit.

Conclusion : ne pas migrer par réflexe. À traiter seulement si une fenêtre UI dépend encore réellement d’un parsing chat ou d’un inspect instable.

### C) Outfits

Encore legacy :

- `outfit ?`
- parsing de réponse chat.

À migrer maintenant en priorité logique.

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
| PVP Stats bridge | Fait |
| Stats simples bridge | Fait |
| Quêtes bridge | Fait |
| Sélection specs bridge | Fait |
| Glyphes bridge | Fait |
| Glyphes icônes / tooltips | Fait |
| Custom Talents navigation | Corrigé |
| Custom Glyphs mapping sockets | Corrigé |
| Talents actifs détaillés bridge | À évaluer / à faire si UI nécessaire |
| Outfits bridge | À faire |
| Nettoyage final parsers legacy | À faire |

---

## Prochain pas logique recommandé

Le prochain pas logique est maintenant : **migrer les Outfits en bridge-first**.

Pourquoi ce bloc en premier :

1. c’est le dernier gros flux UI encore listé comme clairement legacy ;
2. il est normalement read-only pour l’affichage (`outfit ?`), donc moins risqué que les vraies actions d’équipement ;
3. il suit le même modèle déjà validé pour inventory, spellbook, quests, specs et glyphes ;
4. il permettra de réduire encore le parsing automatique du chat sans toucher aux commandes manuelles utiles.

Plan recommandé :

1. inventorier précisément où l’addon lance actuellement `outfit ?` et où il parse la réponse ;
2. ajouter côté bridge `GET~OUTFITS~<bot>~<token>` ;
3. envoyer des paquets courts `OUTFITS_BEGIN`, `OUTFITS_ITEM`, `OUTFITS_END` ;
4. ajouter côté addon `Comm.RequestOutfits(botName)` ;
5. hydrater la fenêtre existante depuis un cache `MultiBot.bridge.outfits[botName]` ;
6. conserver `outfit ?` comme fallback uniquement si la bridge est absente ;
7. laisser les vraies actions utilisateur d’outfit en whisper volontaire tant qu’elles ne servent pas à remplir automatiquement l’UI.

Après Outfits, il faudra faire un audit final des parsers `CHAT_MSG_WHISPER` / `CHAT_MSG_SYSTEM` pour séparer clairement :

- les fallbacks legacy à conserver ;
- les commandes manuelles volontaires à conserver ;
- les anciens parsers automatiques devenus inutiles à supprimer ou neutraliser.

---

## Règle de migration à conserver

Pour chaque fenêtre :

1. le bouton / l’action utilisateur peut encore envoyer une commande au bot si c’est une vraie action ;
2. le refresh automatique de l’UI doit passer par la bridge si elle est connectée ;
3. le fallback chat doit rester si la bridge est absente ;
4. les commandes manuelles historiques restent fonctionnelles.
