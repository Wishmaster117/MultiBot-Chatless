# MultiBot / Bridge — roadmap chatless

Dernière mise à jour : 2026-04-24

## Objectif exact

Rendre **MultiBot non dépendant du retour chat pour alimenter l’UI**, tout en gardant les commandes manuelles volontaires utilisables.

À conserver comme commandes manuelles fonctionnelles :

- `who`
- `co ?`
- `nc ?`
- `ss ?`

Le but n’est pas de supprimer ces commandes. Le but est de ne plus les lancer automatiquement pour ouvrir/remplir les fenêtres d’interface.

---

## État validé après les derniers tests ingame

### Bridge C++

- [x] `HELLO` / `HELLO_ACK`
- [x] `PING` / `PONG`
- [x] `GET~ROSTER`
- [x] `GET~STATE~<bot>`
- [x] `GET~STATES`
- [x] `GET~DETAIL~<bot>`
- [x] `GET~DETAILS`
- [x] `GET~INVENTORY~<bot>~<token>`
- [x] `GET~SPELLBOOK~<bot>~<token>`

### Important : payloads volumineux

Pour éviter les paquets trop gros avec beaucoup de bots, `GET~STATES` et `GET~DETAILS` ne doivent plus dépendre d’un unique gros payload global.

État attendu :

- `GET~STATES` répond avec plusieurs paquets `STATE~<bot>~...` ;
- `GET~DETAILS` répond avec plusieurs paquets `DETAIL~<bot>~...` ;
- un paquet `STATES~` ou `DETAILS~` vide peut seulement servir de réponse vide si aucun bot n’est disponible.

---

## Blocs déjà migrés côté bridge

### 1) Socle bridge

- [x] handshake addon/bridge
- [x] détection de connexion bridge
- [x] bootstrap bridge au login / reload
- [x] logs console bridge configurables via `MultiBotBridge.EnableConsoleLogs`

### 2) Roster / Units

- [x] refresh roster bridge-first
- [x] synchronisation des bots visibles dans `Units`
- [x] hydratation des states combat / non-combat via bridge
- [x] refresh manuel `Units` via bridge quand disponible
- [x] fallback legacy conservé quand la bridge n’est pas disponible

### 3) Détail bot / Raidus

- [x] endpoint `GET~DETAIL~<bot>`
- [x] endpoint `GET~DETAILS`
- [x] réception addon `DETAIL`
- [x] réception addon `DETAILS`
- [x] stockage cache `MultiBot.bridge.details`
- [x] alimentation de `MultiBotGlobalSave`
- [x] Raidus peut récupérer classe / race / genre / niveau / talents / score sans dépendre du spam automatique `who`
- [x] demande de détail bot au bootstrap et lors du `Hello` d’un bot

### 4) Everybars / states UI

- [x] states reçus individuellement par bot
- [x] reconstruction des everybars depuis les states bridge
- [x] correction de la régression où la première everybar se collait au bouton `selfbots`
- [x] placement des everybars redonné au layout `Units`, pas au handler de réception `STATE`
- [x] relayout différé après réception des states pour éviter les coordonnées par défaut après `/reload`

### 5) Inventory snapshot

- [x] `GET~INVENTORY~<bot>~<token>`
- [x] `INV_BEGIN`
- [x] `INV_SUMMARY`
- [x] `INV_ITEM`
- [x] `INV_END`
- [x] ouverture de la fenêtre inventory depuis bridge
- [x] remplissage du contenu inventory depuis bridge
- [x] fallback whisper `items` conservé si bridge indisponible

### 6) Spellbook

- [x] `GET~SPELLBOOK~<bot>~<token>`
- [x] `SB_BEGIN`
- [x] `SB_ITEM`
- [x] `SB_END`
- [x] `Comm.RequestSpellbook(name)`
- [x] ouverture du spellbook via bridge
- [x] remplissage du spellbook via bridge
- [x] fallback whisper `spells` conservé si bridge indisponible

---

## Ce qui n’est plus à faire

### Spellbook

Le spellbook est considéré migré sur le chemin nominal.

Le whisper `spells` peut rester comme fallback, mais ne doit plus être le chemin normal quand la bridge est connectée.

### Détail bot / `who`

Le détail bot est maintenant sorti du chemin `who` pour l’UI.

Les commandes manuelles `who`, `co ?`, `nc ?`, `ss ?` doivent rester disponibles, mais l’UI ne doit plus dépendre automatiquement de leurs réponses pour Raidus / Units.

---

## Ce qui reste partiellement legacy

### A) Units pas encore 100% nettoyé

Encore présent à conserver ou à traiter plus tard selon le cas :

- fallback `.playerbot bot list` ;
- parsing `CHAT_MSG_SYSTEM` pour certains événements add/remove/offline ;
- commandes `.playerbot bot add/remove` toujours utilisées pour connecter/déconnecter les bots.

Conclusion : `Units` fonctionne maintenant en bridge-first pour roster/states/details, mais il reste des chemins legacy de compatibilité et de commande.

### B) Inventory post-action

Le snapshot inventory est bridge, mais certains refreshs après action restent encore legacy.

Exemples à nettoyer :

- refresh après equip / use / destroy / sell ;
- certains `SendChatMessage("items", "WHISPER", nil, botName)` ;
- certains refreshs déclenchés par `CHAT_MSG_LOOT` ou retours système.

Conclusion : inventory est migré pour l’ouverture et le contenu principal, mais pas encore totalement propre après action.

### C) Stats simples

Encore legacy :

- bouton stats global ;
- `SendChatMessage("stats", ...)` ;
- parsing des réponses stats.

À migrer plus tard vers endpoint bridge dédié.

### D) PVP stats

Encore legacy :

- `pvp stats` en whisper / party / raid ;
- parsing de réponse chat pour affichage.

À migrer vers endpoint bridge dédié si on veut un panneau totalement chatless.

### E) Talents / glyphes / specs détaillées

Encore legacy :

- `talents`
- `talents spec list`
- `glyphs`
- réponses chat parsées pour remplir les fenêtres.

À migrer plus tard. C’est un bloc plus gros que l’inventory post-action.

### F) Outfits

Encore legacy :

- `outfit ?`
- parsing de réponse chat.

À migrer plus tard.

### G) Quêtes

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
| Inventory post-action bridge-first | À faire |
| Spellbook bridge | Fait |
| Stats bridge | À faire |
| PVP stats bridge | À faire |
| Talents / glyphes / specs bridge | À faire |
| Outfits bridge | À faire |
| Quêtes bridge | À faire |
| Nettoyage final parsers legacy | À faire |

---

## Prochain pas logique recommandé

Le prochain pas le plus propre est : **finir inventory post-action en bridge-first**.

Pourquoi ce bloc avant stats/talents/outfits :

- le snapshot inventory est déjà bridge ;
- il reste surtout à remplacer les refreshs automatiques `items` par `Comm.RequestInventory(botName)` quand la bridge est connectée ;
- le risque est limité, car on ne change pas encore les actions elles-mêmes ;
- les commandes utilisateur comme equip/use/sell/destroy peuvent rester en whisper pour l’instant ;
- on supprime seulement le spam automatique utilisé pour reconstruire la fenêtre.

### Étape concrète suivante

Faire un patch addon qui remplace les refreshs automatiques :

```lua
SendChatMessage("items", "WHISPER", nil, botName)
```

par une fonction centralisée du style :

```lua
MultiBot.RequestInventoryRefresh(botName)
```

Cette fonction fera :

```lua
if MultiBot.bridge and MultiBot.bridge.connected and MultiBot.Comm and MultiBot.Comm.RequestInventory then
  return MultiBot.Comm.RequestInventory(botName)
end

SendChatMessage("items", "WHISPER", nil, botName)
```

Ensuite on branche cette fonction dans :

- `MultiBotInventoryFrame.lua`
- `MultiBotInventoryItem.lua`
- les vieux refreshs `items` encore présents dans `MultiBotHandler.lua`
- éventuellement `MultiBotEngine.lua` si le cas est un refresh UI et pas une commande manuelle volontaire.

---

## Règle de migration à conserver

Pour chaque fenêtre :

1. le bouton / l’action utilisateur peut encore envoyer une commande au bot si c’est une vraie action ;
2. le refresh automatique de l’UI doit passer par la bridge si elle est connectée ;
3. le fallback chat doit rester si la bridge est absente ;
4. les commandes manuelles historiques restent fonctionnelles.

---

## Résumé court

Fait et validé :

- roster bridge ;
- states bridge ;
- détails bot bridge ;
- Raidus sans `who` automatique ;
- spellbook bridge ;
- inventory snapshot bridge ;
- everybars correctement replacées après `/reload`.

Prochaine étape :

- nettoyer **inventory post-action** pour remplacer les refreshs automatiques `items` par des refreshs bridge-first.
