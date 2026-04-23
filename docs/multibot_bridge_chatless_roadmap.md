# MultiBot / Bridge — roadmap précise pour supprimer la dépendance au retour chat

## Périmètre visé

Objectif de cette roadmap : rendre **l’addon MultiBot non dépendant des réponses textuelles chat** (`CHAT_MSG_SYSTEM`, `CHAT_MSG_WHISPER`, `CHAT_MSG_LOOT`, etc.) pour **alimenter l’UI et ses états**.

Important :
- **ce document ne vise pas encore à supprimer tous les `SendChatMessage` de commande** ;
- le but immédiat est : **les commandes peuvent encore partir en whisper/party/raid si nécessaire, mais l’addon ne doit plus dépendre des réponses texte pour se synchroniser**.

En d’autres termes :
- **écriture** : peut rester provisoirement via commandes chat ;
- **lecture / synchronisation / refresh UI** : doit passer par le bridge.

---

## Base auditée

État établi à partir des dernières versions fournies dans les ZIP :

- `mod-multibot-bridge/src/MultiBotBridge.cpp`
- `MultiBot/Core/MultiBotComm.lua`
- `MultiBot/Core/MultiBotHandler.lua`
- `MultiBot/Core/MultiBot.lua`
- `MultiBot/UI/MultiBotUnitsRootUI.lua`
- `MultiBot/Core/MultiBotEvery.lua`
- `MultiBot/UI/MultiBotInventoryFrame.lua`
- `MultiBot/UI/MultiBotSpell.lua`
- `MultiBot/UI/MultiBotSpellBookFrame.lua`
- `MultiBot/UI/MultiBotSpecUI.lua`
- `MultiBot/UI/MultiBotTalentFrame.lua`
- `MultiBot/UI/MultiBotOutfitUI.lua`
- `MultiBot/UI/MultiBotQuestsMenu.lua`

---

## 1) Ce qui est déjà effectivement décorrélé du retour chat

### 1.1 Bridge protocolaire minimal : en place

Le bridge gère déjà les messages addon suivants :

- `HELLO` / `HELLO_ACK`
- `PING` / `PONG`
- `GET~ROSTER`
- `GET~STATE~<bot>`
- `GET~STATES`

Le payload serveur expose déjà au moins :

- roster des bots groupés/raidés/online ;
- classe, niveau, HP, mana, mort ;
- stratégies `combat` / `non-combat`.

### 1.2 Bootstrap du panneau Units : majoritairement bridge-first

Validé côté addon :

- au login, le bridge est initialisé ;
- le roster bridge peut peupler `MultiBot.index.players` ;
- `GET~STATES` hydrate les everybars / états de stratégies sans attendre les retours de whisper ;
- le clic droit sur `Units` peut relancer un refresh bridge.

### 1.3 Refresh manuel du roster Units : bascule bridge en place

Le refresh manuel du bouton `Units` ne repart plus automatiquement sur les vieux mécanismes guilde/amis quand le bridge est disponible.

### 1.4 Stratégies de base au bootstrap : partiellement sorties du chat

Au moment du bootstrap global :

- l’état initial `combat` / `non-combat` peut déjà venir du bridge ;
- l’addon sait appliquer cet état dans les everybars via `ApplyBridgeBotState` / `ApplyAllBridgeStates`.

---

## 2) Ce qui reste encore dépendant du retour chat

Ici on parle bien des zones où **l’UI dépend encore d’un message texte reçu** pour être correcte.

### 2.1 Fallback login sur `.playerbot bot list` : encore présent

Même si le chemin nominal est maintenant le bridge, il reste un fallback legacy côté login :

- si le bridge n’est pas considéré prêt dans la fenêtre de bootstrap, l’addon peut encore lancer `.playerbot bot list` ;
- ensuite `CHAT_MSG_SYSTEM` sert encore à reconstruire la liste.

**Conclusion** : tant que ce fallback existe, le module n’est pas totalement indépendant du retour chat.

### 2.2 Parser `CHAT_MSG_SYSTEM` legacy : encore autoritaire à plusieurs endroits

Le handler contient toujours de la logique de synchronisation basée sur des chaînes système, notamment pour :

- reconstruction de roster legacy ;
- `add:` / `remove:` ;
- certains états du type `already logged in`, `is not online`, etc. ;
- refresh opportuniste via lignes système.

**Conclusion** : une partie de la vérité fonctionnelle est encore dans le parser système.

### 2.3 Refresh post-action des stratégies everybar : encore chat-dépendant

C’est le point le plus important après le roster.

Aujourd’hui, beaucoup d’actions d’everybar / stratégies restent conçues autour de ce modèle :

1. envoyer une commande (`co ...`, `nc ...`, `ss ...`, `who`, etc.) ;
2. attendre une réponse whisper / système ;
3. parser cette réponse ;
4. mettre à jour le bouton.

Donc :
- **l’état initial** peut venir du bridge ;
- **l’état après interaction utilisateur** repose encore largement sur le retour chat.

### 2.4 Détail bot / ignore / informations contextuelles : encore chat

Les demandes du style :

- `who`
- `co ?`
- `nc ?`
- `ss ?`

restent consommées via parser chat pour afficher ou rafraîchir l’état détaillé d’un bot.

### 2.5 Stats périodiques : encore chat

Le refresh auto de stats s’appuie encore sur :

- envoi de `stats` en whisper ;
- parsing du retour texte pour alimenter le panneau stats.

### 2.6 Inventaire / sacs / équipement / loot : encore chat

Le flux inventaire repose encore sur :

- commande `items` ;
- parsing des lignes retournées ;
- refresh additionnel via `CHAT_MSG_LOOT`.

Donc tout le panneau inventaire reste dépendant du retour chat.

### 2.7 Spellbook : encore chat

Le spellbook s’appuie encore sur :

- commande `spells` ;
- parsing séquentiel des lignes retournées pour remplir la fenêtre.

### 2.8 Talents / specs custom / glyphes : encore partiellement chat

Nuance importante :

- **l’inspect talent de base** utilise déjà en partie les mécaniques d’inspection WoW ;
- mais **les specs custom, la liste des specs, les glyphes, certains apply/switch** reposent encore sur des retours chat du bot.

Donc cette zone n’est **pas** encore chatless.

### 2.9 Outfits : encore chat

Le panneau outfit dépend encore des réponses textuelles du bot pour lister / reconstruire les outfits.

### 2.10 Quêtes : encore chat

Les vues :

- `quests all`
- `quests completed`
- `quests incompleted`

sont encore alimentées par agrégation/parsing des whispers retournés par les bots.

### 2.11 PVP stats : encore chat

Le panneau PVP stats est encore sur un modèle commande + réponse texte.

---

## 3) Diagnostic global exact

### Ce qui est vrai aujourd’hui

Le projet a **déjà franchi la première étape structurante** :

- le bridge existe ;
- le bootstrap `Units` fonctionne ;
- le roster et les états de base peuvent venir du bridge ;
- l’addon peut survivre à plusieurs scénarios où avant il dépendait directement du spam texte.

### Ce qui n’est pas encore vrai

Le projet **n’est pas encore totalement non dépendant du retour chat**, parce que :

1. le fallback login legacy existe encore ;
2. le parser `CHAT_MSG_SYSTEM` reste fonctionnel et utile ;
3. presque tous les panneaux secondaires (inventory, spellbook, quests, outfits, specs custom, stats, pvp) sont encore alimentés par texte ;
4. les interactions utilisateur sur les everybars restent encore largement synchronisées via réponses chat.

### Résumé court

- **Units bootstrap bridge-first : oui**
- **Units totalement chatless : pas encore**
- **Addon globalement chatless : non, pas encore**

---

## 4) Priorisation recommandée

Ordre recommandé pour finir proprement, sans casser ce qui marche déjà.

### Phase A — verrouiller définitivement Units / roster / everybars

C’est la priorité absolue.

À faire :

- supprimer le fallback login `.playerbot bot list` une fois le bridge considéré obligatoire ;
- retirer la reconstruction de roster par parser système dans le chemin nominal ;
- après toute action stratégie (`co/nc/ss/...`) :
  - ne plus attendre un whisper de confirmation ;
  - demander un `GET~STATE~<bot>` ou un `GET~STATES` bridge ;
  - réappliquer l’état bridge côté UI.

**Objectif de fin de phase A** :
- le panneau `Units` et ses everybars fonctionnent entièrement sans réponse texte.

### Phase B — créer un canal bridge pour les vues détaillées bot

À ajouter côté bridge :

- `GET~DETAIL~<bot>` ou équivalent ;
- payload unique regroupant les infos aujourd’hui lues via `who`, `co ?`, `nc ?`, `ss ?`, `ignore`.

**Objectif** : remplacer toute la micro-logique de détail reposant sur les whispers.

### Phase C — bridge pour stats + inventaire + équipement

À ajouter côté bridge :

- `GET~STATS~<bot>`
- `GET~INVENTORY~<bot>`
- éventuellement `GET~EQUIPMENT~<bot>` si séparation utile

Payload attendu :

- stats synthétiques ;
- sacs / slots ;
- items équipés ;
- contenu inventaire exploitable directement par l’UI.

**Objectif** : supprimer la dépendance à `stats`, `items`, `CHAT_MSG_LOOT` pour l’affichage normal.

### Phase D — bridge pour spellbook / talents / glyphes / specs

À ajouter côté bridge :

- `GET~SPELLBOOK~<bot>`
- `GET~TALENTS~<bot>`
- `GET~GLYPHS~<bot>`
- `GET~SPECS~<bot>` / `GET~CUSTOM_SPECS~<bot>` selon le modèle retenu

**Objectif** :
- ne plus parser `spells` ;
- ne plus dépendre des retours `talents spec list`, `glyphs`, etc.

### Phase E — bridge pour quêtes / outfits / pvp stats

À ajouter côté bridge :

- `GET~QUESTS~<bot>~all|completed|incompleted`
- `GET~OUTFITS~<bot>`
- `GET~PVP~<bot>`

**Objectif** : vider les derniers écrans qui dépendent de gros buffers texte.

### Phase F — nettoyage final du legacy parser

Quand toutes les vues précédentes sont migrées :

- supprimer les branches `CHAT_MSG_SYSTEM` devenues inutiles ;
- supprimer les branches `CHAT_MSG_WHISPER` devenues inutiles ;
- supprimer les `waitFor` liés uniquement aux réponses texte ;
- conserver éventuellement un mode debug / compatibilité derrière un flag temporaire.

---

## 5) Roadmap détaillée avec suivi d’avancement

## Milestone M0 — socle bridge

- [x] Handshake bridge (`HELLO`, `HELLO_ACK`)
- [x] Heartbeat (`PING`, `PONG`)
- [x] Roster bridge (`GET~ROSTER`)
- [x] State individuel (`GET~STATE~<bot>`)
- [x] States globaux (`GET~STATES`)
- [x] Application des states bridge dans l’UI Units

**Statut** : fait

## Milestone M1 — Units 100% chatless

- [x] Bootstrap nominal Units via bridge
- [x] Refresh manuel Units via bridge
- [ ] Supprimer le fallback login `.playerbot bot list`
- [ ] Supprimer la reconstruction roster legacy dans le chemin nominal
- [ ] Faire rafraîchir les everybars après action via `GET~STATE` / `GET~STATES`
- [ ] Retirer la dépendance `who/co?/nc?/ss?` pour la synchro d’état

**Statut** : en cours, proche mais non terminé

## Milestone M2 — détails bot / panneaux de contrôle

- [ ] Exposer un payload bridge de détail bot
- [ ] Remplacer les réponses `who` / `ignore` / états détaillés
- [ ] Purger les `waitFor` associés

**Statut** : à faire

## Milestone M3 — stats / inventaire / équipement

- [ ] Endpoint bridge stats
- [ ] Endpoint bridge inventory
- [ ] Endpoint bridge equipment
- [ ] Adapter `MultiBotInventoryFrame.lua`
- [ ] Sortir le panneau stats du parser whisper
- [ ] Réduire / supprimer la dépendance `CHAT_MSG_LOOT`

**Statut** : à faire

## Milestone M4 — spellbook / talents / glyphes / specs

- [ ] Endpoint bridge spellbook
- [ ] Endpoint bridge talents
- [ ] Endpoint bridge glyphes
- [ ] Endpoint bridge specs custom
- [ ] Adapter les UIs associées
- [ ] Supprimer le parser `spells`
- [ ] Supprimer la dépendance à `talents spec list` / `glyphs`

**Statut** : à faire

## Milestone M5 — outfits / quêtes / pvp stats

- [ ] Endpoint bridge outfits
- [ ] Endpoint bridge quests
- [ ] Endpoint bridge pvp stats
- [ ] Adapter les vues `quests all/completed/incompleted`
- [ ] Retirer les buffers d’agrégation chat de quêtes

**Statut** : à faire

## Milestone M6 — purge legacy finale

- [ ] Nettoyer `CHAT_MSG_SYSTEM` devenu obsolète
- [ ] Nettoyer `CHAT_MSG_WHISPER` devenu obsolète
- [ ] Nettoyer les `waitFor` legacy inutiles
- [ ] Garder éventuellement un mode compat debug temporaire

**Statut** : à faire après migration complète

---

## 6) Recommandation d’implémentation concrète

Le meilleur chemin n’est **pas** de tout migrer d’un coup.

Le plus propre est :

1. **finir Units à 100%** ;
2. **créer de nouveaux endpoints bridge par domaine fonctionnel** ;
3. **brancher chaque UI sur le bridge tout en gardant un fallback temporaire** ;
4. **supprimer les parsers legacy seulement à la fin de chaque domaine**.

C’est le chemin le moins risqué pour éviter de recasser le login, le roster, les everybars ou les frames secondaires.

---

## 7) Point de vérité actuel

Si on résume de façon stricte :

- **le chantier “sortir Units du retour chat” est bien avancé** ;
- **le chantier “sortir tout MultiBot du retour chat” est encore à mi-chemin conceptuellement, mais loin d’être terminé fonctionnellement** ;
- **la vraie prochaine marche utile est M1 : Units 100% chatless, y compris refresh post-action**.

---

## 8) Cible finale exacte

Le travail sera considéré terminé quand :

- aucun écran MultiBot critique ne dépendra d’une ligne `CHAT_MSG_*` pour afficher son état normal ;
- le roster bot sera entièrement fourni par le bridge ;
- les everybars se resynchroniseront via bridge après action ;
- les panneaux secondaires (inventory, spellbook, specs, glyphes, outfits, quests, pvp) auront chacun leur payload bridge ;
- les parsers legacy ne resteront que pour debug transitoire, puis seront supprimés.

