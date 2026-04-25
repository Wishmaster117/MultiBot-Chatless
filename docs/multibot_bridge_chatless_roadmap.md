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

### Audit chatless final / nettoyage legacy

- [x] Ajout du switch global `MultiBot.allowLegacyChatFallback = false` dans la configuration addon
- [x] Centralisation côté handler avec `LegacyChatFallbackEnabled()`
- [x] Désactivation par défaut des fallbacks automatiques legacy pour les refresh UI ciblés
- [x] `stats` automatique neutralisé si la bridge ne répond pas
- [x] `items` / inventory automatique neutralisé si la bridge ne répond pas
- [x] `spells` / spellbook automatique neutralisé si la bridge ne répond pas
- [x] `glyphs` automatique neutralisé si la bridge ne répond pas
- [x] `talents spec list` automatique neutralisé si la bridge ne répond pas
- [x] Conservation des vraies commandes d’action volontaire : `glyph equip ...`, actions inventory, sélection de spec, add/remove/connect bots
- [x] Conservation volontaire des commandes manuelles de diagnostic : `who`, `co ?`, `nc ?`, `ss ?`


### Roster / Units

- [x] `GET~ROSTER`
- [x] Roster bridge-first
- [x] Synchronisation des bots visibles dans `Units`
- [x] Refresh manuel `Units` via bridge quand disponible
- [x] Fallback `.playerbot bot list` neutralisé par défaut via `MultiBot.allowLegacyChatFallback = false`
- [x] Reconnexion au login / `/reload` des bots déjà présents dans le groupe ou raid via `.playerbot bot add <bot>`
- [x] Reconnexion volontairement indépendante du switch legacy, car elle sert à connecter les bots et pas à remplir l’UI
- [x] Refresh bridge différé après reconnexion : `GET~ROSTER`, `GET~STATES`, `GET~DETAILS`
- [x] Refresh `Units` automatique après `AddClass` / `.playerbot bot addclass ...` via snapshot bridge immédiat puis différé

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
- [x] Fallback whisper `items` réactivable uniquement via `MultiBot.allowLegacyChatFallback = true`

### Inventory post-action

- [x] Fonction centralisée `MultiBot.RequestInventoryRefresh(botName, delay)` en bridge-first
- [x] Fonction post-action `MultiBot.RequestInventoryPostActionRefresh(botName, firstDelay, secondDelay, options)`
- [x] Refresh automatique après equip / unequip / use / destroy / loot en bridge-first
- [x] Refresh différé en deux temps après action pour éviter les snapshots trop précoces
- [x] Correction du `u [item]` : décrément visuel + pending consume local pour éviter que le snapshot bridge trop tôt remette l’ancien stack
- [x] Correction du clic droit `ue` depuis Inspect : déséquipement puis refresh inventory bridge-first
- [x] Trade : suppression du dump legacy `=== Inventory ===` dans le chat quand la bridge est connectée
- [x] Fallback `items` gardé uniquement en mode diagnostic `MultiBot.allowLegacyChatFallback = true`

### Spellbook

- [x] `GET~SPELLBOOK~<bot>~<token>`
- [x] `SB_BEGIN`
- [x] `SB_ITEM`
- [x] `SB_END`
- [x] `Comm.RequestSpellbook(name)`
- [x] Ouverture du spellbook via bridge
- [x] Remplissage du spellbook via bridge
- [x] Fallback whisper `spells` réactivable uniquement via `MultiBot.allowLegacyChatFallback = true`

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
- [x] Fallback legacy `stats` réactivable uniquement via `MultiBot.allowLegacyChatFallback = true`

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
- [x] Suppression du spam automatique `talents spec list` dans le chat en chemin normal
- [x] Conservation volontaire du whisper utile `My current talent spec is: ...`
- [x] Filtrage des lignes d’aide legacy inutiles renvoyées par `talents` (`warlock`, `Talents usage`, etc.)
- [x] Correction affichage : la partie `(0/56/15)` de la spé courante est ré-affichée en blanc
- [x] Fallback legacy `talents spec list` réactivable uniquement via `MultiBot.allowLegacyChatFallback = true`

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
- [x] Fallback whisper `glyphs` réactivable uniquement via `MultiBot.allowLegacyChatFallback = true`
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

### Audit chatless final

Les refresh automatiques UI les plus sensibles ne retombent plus en chat legacy par défaut. Le switch `MultiBot.allowLegacyChatFallback` permet de réactiver temporairement les anciens fallbacks pour diagnostic, mais la configuration propre reste `false`.

La reconnexion des bots déjà membres du groupe/raid reste autorisée via `.playerbot bot add <bot>`, car ce n’est pas un parser UI legacy : c’est l’action nécessaire pour reconnecter les bots au login ou après `/reload`.

Le bouton `AddClass` déclenche maintenant un refresh bridge automatique du roster/states/details après l’ajout, ce qui évite d’avoir à clic droit sur `Units` pour voir apparaître le nouveau bot.

---

## Ce qui reste partiellement legacy

### A) Units / roster legacy de compatibilité

État actuel après nettoyage :

- le fallback `.playerbot bot list` est désactivé par défaut via `MultiBot.allowLegacyChatFallback = false` ;
- les commandes `.playerbot bot add/remove` restent utilisées pour connecter/déconnecter réellement les bots ;
- la reconnexion automatique au login utilise `.playerbot bot add <bot>` pour les bots déjà présents dans le groupe/raid ;
- certains parsers `CHAT_MSG_SYSTEM` historiques peuvent encore exister pour des événements add/remove/offline ou compatibilité.

Conclusion : `Units` fonctionne en bridge-first pour roster/states/details. Les chemins legacy restants sont surtout des commandes de contrôle ou de compatibilité, pas le chemin nominal pour remplir l’UI.

### B) Talents actifs détaillés

Encore à évaluer :

- `talents` reste volontairement utilisé pour afficher la spé courante ;
- la sélection des specs est déjà migrée ;
- les arbres `Custom Talents` peuvent s’afficher sans dépendre obligatoirement de l’inspection ;
- il faut encore décider si l’UI a besoin d’un endpoint bridge pour les talents actifs détaillés, ou si l’état actuel suffit.

Conclusion : ne pas migrer par réflexe. À traiter seulement si une fenêtre UI dépend encore réellement d’un parsing chat ou d’un inspect instable.

### C) Outfits

Encore legacy, volontairement laissé comme ça pour l’instant :

- `outfit ?`
- parsing de réponse chat.

Conclusion : pas prioritaire immédiatement, car le flux ne spamme pas trop dans l’usage actuel. À migrer plus tard si l’objectif devient le zéro parsing chat sur toutes les fenêtres.

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
| Units sans fallback UI legacy automatique | Fait |
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
| Switch `MultiBot.allowLegacyChatFallback` | Fait |
| Nettoyage fallbacks automatiques stats/items/spells/glyphs/spec list | Fait |
| Reconnexion bots au login / `/reload` | Fait |
| Refresh Units après AddClass | Fait |
| Talents actifs détaillés bridge | À évaluer / à faire si UI nécessaire |
| Outfits bridge | Reporté volontairement |
| Nettoyage final parsers legacy | Fait pour les refresh UI ciblés ; audit résiduel à faire |

---

## Prochain pas logique recommandé

Le prochain pas logique est maintenant : **migrer les Outfits en bridge-first**.

À valider avant de lancer cette migration plus tard :

1. le chemin principal `Units` / `Roster` / `States` / `Details` / `Stats` / `Inventory` / `Spellbook` / `Quests` / `Specs` / `Glyphs` est maintenant bridge-first ;
2. les fallbacks automatiques chat les plus gênants sont neutralisés par défaut ;
3. la reconnexion des bots au login et le refresh après `AddClass` viennent juste d’être corrigés, donc il faut les valider en conditions réelles ;
4. `Outfits` est volontairement laissé legacy pour l’instant, car il ne génère pas assez de spam pour justifier une migration immédiate.

Plan recommandé :

1. tester plusieurs cycles complets : login, `/reload`, groupe, raid, ajout via `AddClass`, ouverture de chaque frame ;
2. vérifier en console qu’il n’y a plus de refresh automatique legacy `stats`, `items`, `spells`, `glyphs`, `talents spec list` avec `MultiBot.allowLegacyChatFallback = false` ;
3. vérifier que les commandes de contrôle nécessaires restent fonctionnelles : `.playerbot bot add`, `.playerbot bot remove`, actions inventory, `glyph equip`, sélection de spec ;
4. garder `Outfits` tel quel pendant cette phase ;
5. ensuite seulement, décider entre deux suites possibles : migrer `Outfits` en bridge-first, ou auditer les derniers parsers `CHAT_MSG_WHISPER` / `CHAT_MSG_SYSTEM` restants pour supprimer ce qui est devenu inutile.

Après cette stabilisation, on pourra reprendre directement la migration fonctionnelle **Outfits bridge-first**.

## Règle de migration à conserver

Pour chaque fenêtre :

1. le bouton / l’action utilisateur peut encore envoyer une commande au bot si c’est une vraie action ;
2. le refresh automatique de l’UI doit passer par la bridge si elle est connectée ;
3. le fallback chat doit rester si la bridge est absente ;
4. les commandes manuelles historiques restent fonctionnelles.
