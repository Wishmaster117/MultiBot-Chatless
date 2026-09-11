# Multibot Chatless + Bridge — Roadmap

**Statut : active**
**Dernière synchronisation : 11/09/2026**

Cette roadmap est la **source de vérité technique** du projet.
Les README Addon/Bridge servent de vitrine fonctionnelle et restent volontairement plus courts.

`TODO.md` est un fichier local séparé et n'est pas utilisé comme source de vérité de cette roadmap.

---

## 1. Baseline actuelle

### Addon

```text
Repo:   L:\ChromieCraft_3.3.5a\Interface\AddOns\MultiBot
Branch: feature/group-orders-chatless
Base HEAD auditée avant commit de clôture Flee:
        3d99f0c5607e0195d2c8a0fab86a42e92c7b1a61
```

État fonctionnel audité au 11/09/2026 :

- Follow / Stay / Attack livrés et runtime validés ;
- lifecycle unitaire des rosters, AutoInvite structuré et Raidus lifecycle livrés ;
- Raidus Working Layout persistant + Safe Group Remove + Empty Layout Apply livrés et runtime validés ;
- Faction Banner bulk group lifecycle livré via `BOT_GROUP_LIFECYCLE_V1` ;
- Creator `addclass` livré via `CREATOR_ADDCLASS_V1` ;
- Flee livré via `FLEE_ORDER_V1`, avec feedback chatless et noms ALL / TARGET / rôles validés ;
- `Core\MultiBotComm.lua` final Flee : `F1B19AAC980C8213CA7494CDDFF6CC6364975D11811A1EBE4A85F40E29501E9A` ;
- `MultiBotComm.lua` reste à **199 locals** au niveau chunk principal ;
- prochain chantier actif : Group Actions (`drink`, `release`, `revive`, `summon`).

### Bridge

```text
Repo:   L:\AC_PB\azerothcore-wotlk\modules\mod-multibot-bridge
Branch: feature/group-orders-chatless
Base HEAD auditée avant commit de clôture Flee:
        77b709007a13975c4898e845aaf04f0ad2fa067b
```

État fonctionnel audité au 11/09/2026 :

- endpoints Follow / Stay / Attack livrés ;
- `BOT_GROUP_REMOVE_V1` livré pour le cleanup Raidus sécurisé ;
- `BOT_GROUP_LIFECYCLE_V1` livré pour le connect/disconnect bulk borné du groupe réel ;
- `CREATOR_ADDCLASS_V1` livré comme adaptateur AddClass spécialisé, sans exécuteur Playerbots générique ;
- `FLEE_ORDER_V1` livré et runtime validé ;
- `BotMatchesAttackAudience` reste autoritaire pour les audiences de rôle ;
- `FLEE_ORDER_ITEM` retourne les résultats nominatifs bornés avant `FLEE_ORDER_ACK` ;
- `src\MultiBotBridge.cpp` final Flee : `55E29034A51BAACFBC2E97B129E245A85AE32A586D737B8576F74E6DF0A0ECF5` ;
- aucun exécuteur Playerbots générique n'a été ajouté.

### Playerbots

```text
Repo: L:\AC_PB\azerothcore-wotlk\modules\mod-playerbots
HEAD: b949b50bfcdd4fab937781bac2d7765e39330e4b
Mode: STRICT READ ONLY
```

**Règle absolue :** aucune modification de `mod-playerbots` dans ce projet.

### Architecture

Le projet est actuellement :

```text
bridge-first / mostly chatless
```

Le Bridge doit rester la couche principale d'adaptation entre l'Addon et Playerbots.

Le fallback automatique legacy reste désactivé par défaut :

```lua
MultiBot.allowLegacyChatFallback = false
```

---

## 2. Protocole de progression obligatoire

Toujours suivre :

```text
Audit
→ Analyse
→ Proposition
→ Validation utilisateur
→ Patch minimal
→ Vérifications
→ Compilation si C++
→ Tests en jeu
→ Audit final
→ Archivage
```

Règles permanentes :

- aucun patch à l'aveugle ;
- aucun changement dans `mod-playerbots` ;
- un patch = un objectif précis ;
- backup + rollback + hashes obligatoires ;
- ne jamais écraser les changements locaux ;
- ne jamais ajouter d'exécuteur Bridge générique acceptant une commande Playerbots arbitraire ;
- toute donnée reçue depuis l'Addon est non fiable et doit être revalidée côté Bridge.

---

## 3. État fonctionnel livré

Les blocs suivants ne doivent plus être présentés comme backlog actif.

### Fondation Bridge / état / stratégies

- handshake et détection Bridge ;
- `STATE_FRAMING_V1` ;
- `STRATEGY_MUTATION_V1` ;
- migration progressive des sélecteurs UI vers des réponses structurées ;
- fallback legacy automatique désactivé par défaut.

### Inventory / items

Livré et validé :

- `INVENTORY_V1` ;
- `INVENTORY_EXACT_V1` ;
- UI bag-aware Backpack / Bag 1..4 / Keyring ;
- `ITEM_MOVE_V1` pour les piles d'items ordinaires ;
- `ITEM_EQUIP_V1` ;
- `ITEM_UNEQUIP_V1` ;
- `ITEM_TRADE_V1` ;
- `ITEM_USE_V1` ;
- destruction exacte d'item ;
- `ITEM_SELL_SINGLE_V1` ;
- `VENDOR_BUYBACK_V1` ;
- `INVENTORY_BULK_SELL_V1` / Sell Vendor ;
- `INVENTORY_OPEN_V1`.

### Bank / Guild Bank

Livré :

- vues et actions Bridge existantes ;
- P3A `ITEM_DEPOSIT_EXACT_V1` pour dépôt exact BANK et GBANK ;
- validation de source physique et rejet `SOURCE_STALE`.

P3B/P3C restent différés, voir section backlog.

### Talents / glyphes

Livré et runtime validé :

- `TALENT_APPLY_V1` ;
- `TALENT_SPEC_APPLY_V1` ;
- application custom ;
- application premade ;
- dual-spec/slot 1/2 selon le chemin validé ;
- vérification autoritative avant succès.

### Professions / Enchanting

Livré :

- listing des recettes ;
- craft normal ;
- `CRAFT_RECIPE_TARGET_V1` pour les recettes nécessitant un item cible exact ;
- `ENCHANT_TRADE_V1` et workflow Enchanting Trade Service.

### Quêtes

Livré :

- listing Bridge ;
- `QUEST_ABANDON_V1` ;
- partage de quête conservé comme comportement natif client quand applicable.

### Loot

Livré :

- profils de loot Bridge ;
- décision Quest/Skill versus Disenchant clôturée en faveur du profil Playerbots vérifié `disenchant` ;
- `LOOT_RULE_ITEM_V1` pour ADD/REMOVE exact et persistant de la liste always-loot.

### SelfBot

Livré :

- `SELF_BOT_V1` ;
- `SELF_STRATEGY_V1` ;
- `SELF_ACTION_V1` pour les actions explicitement auditées.

### Group / combat tools

Livré ou déjà migré selon les familles validées :

- Formation ;
- Group Roll ;
- RTI ;
- Pull Control ;
- Disperse ;
- `FOLLOW_ORDER_V1` ;
- `STAY_ORDER_V1` ;
- `ATTACK_ORDER_V1` ;
- `FLEE_ORDER_V1`, y compris ALL / TARGET / Tank / Healer / DPS / Melee / Ranged avec feedback nominatif chatless ;
- plusieurs contrôles combat/non-combat.

### Creator — AddClass spécialisé

Livré et runtime validé le 06/09/2026 :

```text
CREATOR_ADDCLASS_V1
```

Architecture retenue :

```text
Creator UI
  -> AddClassToTarget(class, gender)
  -> RUN~CREATOR_ADDCLASS~token~class~gender
  -> validation Bridge class/gender + rate/replay
  -> adaptateur spécialisé Playerbots addclass
  -> ACK CREATOR_ADDCLASS
  -> roster refresh / auto-group existants
```

Garanties validées :

- aucune commande Playerbots arbitraire fournie par l'Addon ;
- whitelist classe + genre revalidée côté Bridge ;
- sémantique Playerbots conservée : permissions, pool AddClass, règles DK ;
- Random / Male / Female / DK runtime validés ;
- auto-group, roster et EveryBar non régressés ;
- aucun `.playerbot bot addclass ...` SAY observé avec `MultiBot.allowLegacyChatFallback == false` ;
- fallback chat historique conservé uniquement derrière `allowLegacyChatFallback` ;
- `init=auto` volontairement inchangé et hors périmètre de ce patch ;
- Playerbots resté strictement read-only.

---

## 4. Clôture Alt roster / bot lifecycle — 30/08/2026

### Capacités livrées

```text
ALT_ROSTER_V1
BOT_LIFECYCLE_V1
BOT_TARGET_RESOLVE_V1
```

### Roster coverage

Validé pour :

- My Bots / Altbots ;
- Group ;
- Guild ;
- Friends ;
- Favorites.

### Invariant UI canonique

```text
bot offline  -> EveryBar repliée
bot online   -> EveryBar dépliée
```

Les flags propres à un roster ne doivent pas faire fuiter l'état de repli vers un autre roster.

### Stabilisations Addon validées

Le chantier a couvert notamment :

- présence online/offline cohérente ;
- reconnexion/déconnexion via clic roster ;
- cache social réappliqué lors des changements de roster ;
- nettoyage lifecycle lors des transitions monde/session ;
- gestion des pending/timeout ;
- pagination Guild/Friends avec ordre canonique online-first ;
- non-régression des autres rosters.

### Hardening Bridge validé

Le Bridge lifecycle a été durci sur :

- autorisation de contrôle ;
- anti-rejeu ;
- rate limiting ;
- cible offline/online ;
- conservation des connexions asynchrones in-flight.

La simple appartenance au même groupe ne suffit pas à autoriser le contrôle lifecycle d'un personnage offline.

Les relations retenues par le chemin audité sont :

```text
sameAccount
sameGuild
addClassBot
linked/trusted account
```

### In-flight connect retention

Le timeout court sert au **reporting**, mais ne doit pas faire oublier une connexion Playerbots asynchrone encore en cours.

Le pending reste donc réservé jusqu'à :

- observation de la fin de connexion ; ou
- expiration de la fenêtre de rétention longue.

Cela évite :

- duplicate connect ;
- perte de l'état CONNECTING ;
- libération prématurée du budget `maxBots`.

### Validation finale

- compilation `worldserver` réussie ;
- serveur redémarré ;
- matrice runtime validée ;
- aucune nouvelle régression de roster/EveryBar signalée ;
- aucun nouveau spam chat signalé ;
- reviews Addon #75 et Bridge #34 fermées ;
- merges effectués ;
- audit post-merge propre ;
- Playerbots resté strictement inchangé.

### Portée exacte de cette clôture

La clôture lifecycle ci-dessus est une **clôture fonctionnelle des rosters et de `BOT_LIFECYCLE_V1`**. Elle ne signifie pas que tous les anciens transports `.playerbot bot ...` ont déjà disparu de l'Addon.

L'audit global puis l'audit lifecycle résiduel du 30/08/2026 ont identifié des appelants historiques hors des routes roster principales. Ils sont suivis comme **reliquats de transport chat** et ne remettent pas en cause la validation runtime des rosters.

Audit lifecycle résiduel du 30/08/2026 (snapshot historique) :

```text
PLAYERBOT_CHAT_OCCURRENCE_COUNT=24
STRUCTURED_FIRST_FALLBACK_COUNT=4
DIRECT_ADD_REMOVE_CHAT_REVIEW_COUNT=12
BULK_LIFECYCLE_REVIEW_COUNT=2
INIT_AUTO_REVIEW_COUNT=1
SELF_BOT_LEGACY_REVIEW_COUNT=2
BOT_LIST_REVIEW_COUNT=1
OTHER_PLAYERBOT_CHAT_REVIEW_COUNT=2
```

Ces valeurs sont des métriques de scan et de préclassification. L'analyse manuelle distingue notamment une occurrence documentaire/commentaire du code réellement exécutable.

### Conclusions architecturales lifecycle résiduelles

`BOT_LIFECYCLE_V1` et `BOT_TARGET_RESOLVE_V1` couvrent déjà la sémantique nécessaire aux connexions/déconnexions **unitaires**. Aucun nouvel exécuteur générique n'est requis pour AutoInvite, Raidus ou les add/remove unitaires.

Les relations d'autorisation Bridge restent alignées sur le modèle Playerbots audité :

```text
sameAccount
sameGuild
addClassBot
linked/trusted account
```

L'audit réactualisé du 03/09/2026 confirme que le lifecycle **unitaire** n'est plus le prochain bloc fonctionnel :

- `ReconnectExistingGroupBots()` retourne immédiatement lorsque les capacités structurées lifecycle/resolve sont disponibles et son ancien chat nécessite `MultiBot.allowLegacyChatFallback == true` ;
- les fallbacks add/remove unitaires des rosters restent derrière la politique explicite de fallback legacy ;
- AutoInvite BAR/RAIDUS est structured-first via `BOT_TARGET_RESOLVE_V1` + `BOT_LIFECYCLE_V1` ;
- Raidus utilise le lifecycle structuré par slot et `BOT_GROUP_REMOVE_V1` pour le cleanup hors layout ;
- `bot list` et `bot self` conservent seulement leurs chemins legacy bornés ;
- `addclass` et `init=auto` restent **hors lifecycle simple** et devront conserver des chantiers spécialisés.

Le reliquat bulk identifié au 03/09/2026 a depuis été migré :

```text
UI\MultiBotUnitsRootUI.lua

.playerbot bot add *
.playerbot bot remove *
```

Le Faction Banner utilise maintenant `BOT_GROUP_LIFECYCLE_V1`, avec conservation du **groupe réel du master/requester** comme scope serveur. La migration ne transforme pas `*` en « tous les bots du compte ».

### Invariant de transport conservé

```text
MultiBot.allowLegacyChatFallback == false
=> aucun fallback lifecycle unitaire automatique
   .playerbot bot add <name>
   .playerbot bot remove <name>
=> aucun transport bulk automatique
   .playerbot bot add *
   .playerbot bot remove *
```

Un audit ciblé read-only du cleanup Units / lifecycle legacy a été réalisé le 06/09/2026. Il confirme qu'un cleanup est utile, mais qu'une partie des reliquats reste constituée de fallbacks de transition, de parsers partagés ou de chemins dont la reachability doit être revalidée après les migrations restantes.

Décision de roadmap :

```text
Units / lifecycle legacy cleanup
-> différé
-> regroupé avec le cleanup final des fallbacks/parsers chat
```

Aucun cleanup lifecycle n'est donc appliqué à ce stade. Le sous-chemin Creator `addclass` a depuis été migré via `CREATOR_ADDCLASS_V1`; le prochain chantier fonctionnel actif est désormais **Creator `init=auto`**.

---

## 5. Clôture ordres collectifs Follow / Stay / Attack — 30/08/2026

### Capacités livrées

```text
FOLLOW_ORDER_V1
STAY_ORDER_V1
ATTACK_ORDER_V1
```

Les trois ordres sont désormais migrés vers des chemins Bridge spécialisés.

Architecture validée :

```text
UI Addon
  -> route spécialisée dans ActionToGroup
  -> RUN structuré
  -> endpoint Bridge borné
  -> API/action Playerbots auditée
  -> ACK structuré
```

Aucun exécuteur générique `RUN~ORDER` n'a été ajouté. Les trois routes structurées passent avant le fallback legacy PARTY/RAID, qui reste disponible uniquement pour les commandes non migrées et les usages volontairement conservés.

### Follow / Stay

Requêtes :

```text
RUN~FOLLOW_ORDER~<token>
RUN~STAY_ORDER~<token>
```

ACK :

```text
FOLLOW_ORDER_ACK~<token>~<matched>~<succeeded>~<failed>~<reason>
STAY_ORDER_ACK~<token>~<matched>~<succeeded>~<failed>~<reason>
```

Le Bridge réutilise les actions Playerbots auditées `follow chat shortcut` et `stay chat shortcut` sans passer par `HandleCommand()`. Le scope est dérivé du groupe réel du requester côté serveur, avec contrôles de sécurité, rate limit et anti-rejeu.

### Attack

Requête :

```text
RUN~ATTACK_ORDER~<token>~<audience>
```

ACK :

```text
ATTACK_ORDER_ACK~<token>~<audience>~<matched>~<succeeded>~<failed>~<reason>
```

Audiences validées :

```text
ALL
TANK
HEALER
DPS
MELEE
RANGED
```

Sémantique conservée depuis le `StrategyChatFilter` Playerbots audité :

```text
TANK   = IsTank(bot)
HEALER = IsHeal(bot)
DPS    = !IsTank(bot) && !IsHeal(bot)
RANGED = IsRanged(bot)
MELEE  = !IsRanged(bot)
ALL    = aucun filtre de rôle
```

La cible est autoritative côté serveur :

```text
requester->GetTarget()
```

Le Bridge n'utilise pas `DoSpecificAction("attack my target")`, car l'action Playerbots correspondante résout la cible via le master du bot. Un adaptateur local au Bridge expose donc `AttackAction::Attack(Unit*)` afin d'appliquer explicitement la cible du requester sans modifier Playerbots.

`WaitForAttackStrategy::ShouldWait()` peut différer l'appel physique `bot->Attack()` après acceptation de l'ordre. Le succès Bridge représente donc l'acceptation et l'application de l'état/target de combat, pas l'obligation que `GetVictim()` pointe immédiatement sur la cible.

Aucun changement CMake n'a été nécessaire : le projet généré `modules.vcxproj` expose déjà les include paths Playerbots nécessaires à `AttackAction.h`.

### Sécurité et limites communes

Les endpoints GroupOrder réutilisent les protections communes validées :

- groupe du requester dérivé côté serveur ;
- bots Bridge-visible du même groupe ;
- `PLAYERBOT_SECURITY_ALLOW_ALL` par bot ;
- session/world/runtime vérifiés ;
- limite de bots bornée ;
- rate limiting partagé ;
- token anti-rejeu ;
- ACK technique uniquement via le Bridge.

### Validation finale

- Follow/Stay runtime validés ;
- Attack compilé sans rerun CMake ;
- worldserver redémarré ;
- Attack runtime validé sur les audiences testées ;
- `ATTACK_ORDER_ACK` observé dans les logs Bridge ;
- `MultiBotComm.lua` maintenu à **199 locals main-chunk** ;
- aucun `HandleCommand()` dans les blocs Follow/Stay/Attack ;
- aucun `RUN~ORDER` générique ;
- Playerbots resté strictement inchangé.

---

## 6. Clôture Raidus Working Layout / Safe Apply — 03/09/2026

### État utilisateur livré

Raidus est désormais un planner persistant de **8 groupes × 5 slots** avec :

- pool paginé ;
- tri `Score`, `Level` et `Class` ;
- détails bot au survol ;
- drag & drop et swap des slots ;
- Auto balance score au clic gauche ;
- Auto balance Tank / Heal / DPS au clic droit ;
- Working Layout persistant après fermeture/réouverture et `/reload` ;
- Saved Layouts exposés par l'UI sur les slots 1 à 10 ;
- `Apply` structuré pour connecter les bots requis et réaligner les groupes ;
- clic droit pool via lifecycle structuré ;
- Shift + clic droit pool pour supprimer une entrée du pool après confirmation.

Le master est représenté comme une carte dédiée et n'est pas soumis au lifecycle bot.

### Safe Group Remove

Capacité livrée :

```text
BOT_GROUP_REMOVE_V1
```

Le cleanup des membres actuellement groupés mais absents du Working Layout ne passe plus par `UninviteUnit()` côté client.

Ordre serveur validé :

```text
resolve target
-> GetPlayerBot(targetGuid) prouve un Playerbot actif géré
-> même groupe normal + droits de kick AzerothCore
-> refus leader / LFG / BG / BF
-> LogoutPlayerBot(targetGuid)
-> vérification bot offline
-> relecture du groupe
-> suppression uniquement d'une appartenance résiduelle éventuelle
-> vérification finale
-> ACK structuré
```

Conséquence validée en jeu :

- Playerbot online hors layout : logout + retrait du groupe ;
- humain réel hors layout : **reste dans le groupe** ;
- aucune identité bot n'est déduite seulement du compte, de la guilde ou de l'appartenance au groupe.

### Empty Layout Apply

Un Working Layout complètement vide est désormais un cas valide :

```text
Apply
-> cleanup hors layout
-> arrêt
-> aucun AutoSort
```

Ce cas a été runtime validé en party/raid.

### Validation finale Raidus

- compilation du Bridge Safe Group Remove réussie ;
- serveur redémarré ;
- hotfix Lua Empty Layout Apply appliqué et vérifié ;
- layout vide et non vide validés ;
- protection humain validée ;
- party et raid validés ;
- Working Layout `/reload` validé ;
- Saved Layout Load/Save validé ;
- BotDetails validé ;
- BOT_CONNECT / BOT_DISCONNECT non régressés ;
- rosters / EveryBar non régressés ;
- aucun nouveau spam chat signalé ;
- Playerbots resté strictement inchangé.

### Reliquat Saved Layout non bloquant

L'UI actuelle expose les slots Saved Layout **1 à 10**, tandis que la boucle de migration des anciennes clés legacy reste bornée à 8. Les sauvegardes modernes utilisent le store actuel ; ce point concerne seulement une éventuelle migration d'anciens slots legacy 9/10 et reste un reliquat technique non prioritaire.

---

## 7. Clôture Bulk Group Lifecycle — 06/09/2026

### Capacité livrée

```text
BOT_GROUP_LIFECYCLE_V1
```

Le Faction Banner de `UI\MultiBotUnitsRootUI.lua` ne dépend plus directement du transport chat pour son chemin normal :

```text
left click  -> CONNECT
right click -> DISCONNECT
```

### Sémantique conservée

Le scope est dérivé côté serveur du `Group::MemberSlotList` courant du requester :

- requester exclu ;
- maximum 39 cibles ;
- party et raid couverts ;
- le scope reste le **groupe réel**, jamais « tous les bots du compte ».

`CONNECT` et `DISCONNECT` ne contournent pas Playerbots :

```text
CONNECT
  -> PlayerbotMgr::AddPlayerBot(...)

DISCONNECT
  -> PlayerbotMgr::GetPlayerBot(...)
  -> PlayerbotMgr::LogoutPlayerBot(...)
```

Le Bridge ne reproduit pas les internals de Playerbots :

```text
RemoveFromPlayerbotsMap()       -> NO
WorldSession::LogoutPlayer()    -> NO
direct session delete           -> NO
forced group-slot removal       -> NO
```

Un `DISCONNECT` bulk met donc le Playerbot offline tout en laissant le slot de groupe intact, conformément à la sémantique historique auditée de `.playerbot bot remove *`.

### Protections Bridge

Le chemin bulk conserve les protections lifecycle existantes :

- validation requester/session ;
- relation de contrôle autorisée pour les connexions ;
- `GetPlayerBot()` comme preuve du bot géré pour les déconnexions ;
- pending-connect accounting ;
- budget `maxAddedBots` ;
- rate limit mutation ;
- replay protection ;
- revalidation du groupe pendant le traitement ;
- résultats structurés agrégés.

Aucun exécuteur générique Playerbots n'a été ajouté.

### Validation finale

- patch appliqué et vérifié ;
- `MultiBotComm.lua` reste à **199 locals** au niveau chunk principal ;
- compilation `worldserver` : **10 succès, 0 échec** ;
- mise à jour AzerothCore/Playerbots réauditée avant runtime ;
- tests en jeu CONNECT/DISCONNECT validés ;
- reconnexion asynchrone Playerbots observée ;
- slots de groupe conservés au disconnect ;
- aucun crash observé ;
- aucun `.playerbot bot add *` / `.playerbot bot remove *` observé dans le transport runtime validé ;
- Addon et Bridge commités, poussés et synchronisés ;
- Playerbots resté strictement read-only.

Baseline validée :

```text
Addon      af66f27a5e4c40d9115b48271bbd0e6216e6f256
Bridge     6f10549f02ac6469697197c41d47cf5974a71590
AzerothCore 413bea61a85e20d9caef7d66fc601a661fdddd9d
Playerbots b949b50bfcdd4fab937781bac2d7765e39330e4b
```

### Prochain ordre fonctionnel

Le bulk lifecycle et Flee sont retirés de la file active.

L'audit `Units / lifecycle legacy cleanup` du 06/09/2026 a confirmé qu'un nettoyage est possible, mais il reste volontairement reporté afin de ne pas retirer trop tôt des fallbacks/parsers encore utiles pendant la migration chatless.

Après clôture Flee du 11/09/2026, l'ordre recommandé devient :

1. Group Actions (`drink`, `release`, `revive`, `summon`) ;
2. RTSC ;
3. Quest interactions (`accept *`, `talk`, `los`, gameobject use, reward choice) ;
4. actions bots ordinaires restantes (maintenance, autogear, Hunter pet controls, spell cast) ;
5. nettoyage final global des fallbacks/parsers chat devenus morts, **incluant le cleanup Units / lifecycle legacy déjà audité**.

Ne pas déclarer le projet fully chatless tant que les occurrences restantes de `SendChatMessage` n'ont pas été classées et validées.

---

## 7bis. Clôture Flee Chatless — 11/09/2026

### Capacité livrée

```text
FLEE_ORDER_V1
```

Le chemin normal Flee est désormais structuré pour :

```text
ALL
TARGET
TANK
HEALER
DPS
MELEE
RANGED
```

### Sémantique et autorité

Le Bridge n'a pas réimplémenté la logique native Flee. Il invoque l'action Playerbots auditée :

```text
flee chat shortcut
```

La sélection des audiences de rôle reste autoritaire côté Bridge via `BotMatchesAttackAudience`. Le scope groupe est borné, la sécurité Playerbots est revalidée par bot, et les protections de rate/replay restent appliquées.

Pour les rôles, le Bridge renvoie un résultat borné par bot avant l'ACK final :

```text
FLEE_ORDER_ITEM~token~audience~encodedBotName~OK|ERR
FLEE_ORDER_ACK~token~audience~matched~succeeded~failed~reason
```

Le nombre maximum de bots correspondants reste 40. Si l'Addon ne reçoit pas une liste nominative complète et cohérente, il retombe sur le compteur au lieu d'afficher une liste partielle.

### Feedback chatless

Le feedback utilisateur a été validé ainsi :

- `ALL` affiche les noms des bots contrôlés du groupe/raid ;
- `TARGET` affiche le nom du bot uniquement sur succès exact ;
- une cible non-bot / non contrôlée ne génère pas de fausse confirmation nominative ;
- `TANK`, `HEALER`, `DPS`, `MELEE`, `RANGED` affichent les noms autoritaires renvoyés par le Bridge ;
- les whispers Playerbots normaux de succès Flee sont filtrés uniquement pendant une requête Flee correspondante ;
- les erreurs Playerbots et les whispers humains sans rapport restent visibles.

### Validation finale

Validation runtime utilisateur du 11/09/2026 :

- ALL : OK ;
- TARGET bot contrôlé : OK ;
- TARGET mob/non contrôlé : aucune fausse confirmation ;
- Tank / Healer / DPS / Melee / Ranged : exécution et noms OK ;
- `FLEE_ORDER_ITEM` observé avant `FLEE_ORDER_ACK` pour les audiences de rôle ;
- suppression du spam whisper Flee : OK ;
- Follow / Stay / Attack après Flee : non-régression validée ;
- aucune erreur Lua ni crash signalé ;
- build `worldserver` post-patch : validé ;
- Playerbots resté strictement read-only.

Hashes finaux Flee avant commit documentaire :

```text
Addon Core\MultiBotComm.lua
F1B19AAC980C8213CA7494CDDFF6CC6364975D11811A1EBE4A85F40E29501E9A

Bridge src\MultiBotBridge.cpp
55E29034A51BAACFBC2E97B129E245A85AE32A586D737B8576F74E6DF0A0ECF5
```

Audit final de clôture/documentation :

```text
audit-multibot-flee-closeout-docs-current-state-v1-2026-09-11-175432.zip
SHA-256 030F44635E435E41B5A056A77F5975B8F67A7785EF9BFB21536DD7423E32D16D
FINAL_STATUS=OK
```

Le prochain chantier actif est **Group Actions** : `drink`, `release`, `revive`, `summon`.

---

## 8. Backlog différé

Ces éléments ne doivent pas interrompre le prochain chantier normal sauf demande explicite.

### P3B — exact BANK withdrawal

Le snapshot actuel ne fournit pas encore un modèle physique de source exploitable de bout en bout pour un retrait exact.

### P3C — exact GBANK withdrawal

Même problème : la sélection physique exacte de la source doit être conçue de bout en bout.

### `SOURCE_STALE` UI

Ajouter un libellé localisé dédié.
Le texte générique actuel est fonctionnel et non bloquant.

### `BAG_MOVE`

Important :

`ITEM_MOVE_V1` couvre déjà le déplacement des **items ordinaires** entre Backpack / Bag 1..4 / Keyring.

Le backlog `BAG_MOVE` signifie uniquement :

```text
déplacer / rééquiper les objets sacs eux-mêmes
dans les slots de sacs équipés
```

### `SELL_GREY`

Audit/implémentation bridge-first dédié à reprendre plus tard.

### Firestone / Spellstone

Faire la revalidation réelle finale du comportement :

```text
TEMP_ENCHANTMENT_SLOT
```

Le diagnostic et le code de support existants ne suffisent pas à déclarer ce point définitivement fermé.

### LuaLint Warlock

Quatre warnings historiques restent à nettoyer après les chantiers fonctionnels prioritaires.

---

## 9. Reliquats techniques à auditer

Ces points sont enregistrés mais ne sont pas le prochain chantier fonctionnel.

### Lifecycle Trainer

`trainerCommands` doit être audité pour :

- timeout borné ;
- résultat `DISCONNECTED` déterministe ;
- aucun pending UI bloqué après perte de connexion.

### Lifecycle Outfit

Le verrou UI / pending doit être audité afin qu'une déconnexion ne laisse pas `commandBusy` bloqué.

### Lifecycle Formation

Les callbacks/pending doivent être drainés de façon déterministe lors des transitions/disconnects.

### Craft normal — idempotence / anti-rejeu

Le chemin `PROFESSION_RECIPE_CRAFT` doit être comparé aux protections de `CRAFT_RECIPE_TARGET_V1` :

- rate limit ;
- replay token ;
- retry ambigu ;
- résultat perdu ;
- risque de double craft.

---

## 10. Reliquats chat / finalisation globale

Le projet ne doit pas être décrit comme **fully chatless** tant que les occurrences restantes de `SendChatMessage` n'ont pas été classées.

### Snapshot global historique du 03/09/2026

Le scan first-party avait relevé avant migration du bulk :

```text
SENDCHATMESSAGE_FIRST_PARTY_COUNT=143
PLAYERBOT_BOT_ADD_REMOVE_MATCH_COUNT=17
BULK_GROUP_LIFECYCLE_DIRECT_COUNT=2
```

Ces valeurs restent un **snapshot historique**, pas un comptage post-bulk. Aucun nouveau scan global n'a été relancé uniquement pour mettre à jour cette documentation.

`PLAYERBOT_BOT_ADD_REMOVE_MATCH_COUNT=17` incluait un commentaire, `addclass`, des fallbacks unitaires déjà gated/structured-first et les deux producteurs bulk désormais migrés. Cette métrique ne représente donc pas 17 migrations actives.

Raidus conserve encore des `SendChatMessage` d'information utilisateur, mais **aucun `.playerbot bot add/remove`** dans son lifecycle actuel.

Follow / Stay / Attack, le lifecycle unitaire des rosters, AutoInvite, Raidus et le Faction Banner bulk ne représentent plus le prochain problème de transport lifecycle.

### Décision 06/09/2026 — cleanup lifecycle différé

L'audit ciblé `Units / lifecycle legacy cleanup` a été exécuté après la clôture Bulk Group Lifecycle.

Résultat structurel :

- les chemins structurés `BOT_LIFECYCLE_V1`, `BOT_GROUP_LIFECYCLE_V1` et `BOT_GROUP_REMOVE_V1` restent actifs et protégés ;
- plusieurs anciens `bot add/remove` sont désormais des fallbacks post-migration ;
- `allowLegacyChatFallback` reste partagé par d'autres familles encore non migrées et ne doit pas être retiré maintenant ;
- les parsers généraux chat restent partagés ;
- certains blocs `MultiBotHandler.lua` nécessitent encore une revalidation de reachability avant suppression ;
- aucun patch cleanup n'est appliqué à ce stade.

Décision :

```text
cleanup Units / lifecycle legacy
-> REPORTÉ
-> repris dans le cleanup final global
```

Cette décision évite de casser prématurément les rosters, EveryBar, AutoInvite, Raidus ou des chemins de compatibilité pendant que les dernières familles chatless sont encore en migration.

### Familles actives à reprendre

Ordre courant après clôture Flee du 11/09/2026 :

```text
1. Group Actions: drink / release / revive / summon
2. RTSC
3. Quest interactions
4. remaining ordinary-bot actions
5. final legacy parser/fallback cleanup
   including Units / lifecycle legacy cleanup
```

Les listes de quêtes `INCOMPLETED`, `COMPLETED` et `ALL` sont déjà Bridge-first ; ne pas les remigrer. Le reliquat Quest concerne surtout les interactions/commandes encore chat.

### Classification finale attendue

Chaque occurrence doit finir dans une catégorie claire :

```text
manual command volontaire
diagnostic
compatibility fallback
information message
UI mechanism à migrer
dead code
```

Après preuve de non-régression :

- supprimer les parsers legacy devenus morts ;
- conserver les commandes manuelles utiles ;
- conserver un fallback seulement lorsqu'il est explicitement justifié ;
- continuer les tests de spam chat après chaque migration ;
- retirer le throttle/infrastructure `SendChatMessage` uniquement en toute fin, lorsqu'aucun producteur nécessaire ne l'utilise encore.

---

## 11. Contribution Jellypowered — historique conservé

Les contributions Jellypowered ont servi de référence pendant la migration chatless.

### Contribution initiale

Auteur :

```text
Jellypowered <Jellypowered@gmail.com>
```

Commits historiques étudiés :

```text
13059a9f334d1e5aaa8560ab29a1814e48b07054
7ff1347535be6d5a3256d933731c11c4b3f3b38e
04061f084bd189487f1ac0e99892316146f1bea0
```

### Fork Extended étudié

Référence historique :

```text
Jellypowered/mod-multibot-bridge
branch: Extended
```

Commits notamment étudiés :

```text
89da6a9dd15be77c3cbfe9be88a9885b632d606a
40bc0e378b1723d746d3425d4ee0818fd01531c6
7f9027faf6126bd2854d9f5e84f9a7fa82549077
```

Politique conservée :

- ne jamais merger aveuglément le fork ;
- auditer fonction par fonction ;
- reprendre / adapter / rejeter selon l'état réel ;
- conserver les crédits uniquement pour les parties réellement reprises.

Lorsque la reprise substantielle le justifie :

```text
Co-authored-by: Jellypowered <Jellypowered@gmail.com>
```

Pour une simple inspiration de design :

```text
Design inspired by the Jellypowered bridge contribution.
```

Les anciennes branches Jellypowered sont désormais des références historiques, pas les branches de développement actives.

---

## 12. Historique récent de clôture

Repères principaux conservés :

- PR Jellypowered Addon #67 mergée dans `main` ;
- PR Jellypowered Bridge #28 mergée dans `main` ;
- PR SelfBot Addon #72 mergée ;
- PR SelfBot Bridge #30 mergée ;
- stabilisation Addon PR #73 ;
- P3A `ITEM_DEPOSIT_EXACT_V1` clôturé ;
- `LOOT_RULE_ITEM_V1` clôturé ;
- décision Disenchant clôturée ;
- Alt roster / lifecycle Addon PR #75 mergée ;
- Alt roster / lifecycle Bridge PR #34 mergée ;
- audit post-merge lifecycle final : propre ;
- Follow / Stay / Attack structurés, compilés/testés puis commités et poussés sur `feature/group-orders-chatless` ;
- Raidus lifecycle par slot migré vers `BOT_LIFECYCLE_V1` / `BOT_TARGET_RESOLVE_V1` ;
- Raidus Safe Group Remove livré via `BOT_GROUP_REMOVE_V1` ;
- Raidus Working Layout persistant et Empty Layout Apply runtime validés ;
- audit lifecycle/documentation du 03/09/2026 : les chemins unitaires sont structurés ou legacy-gated et le bulk `add * / remove *` est identifié comme producteur direct suivant ;
- bulk group lifecycle du Faction Banner migré via `BOT_GROUP_LIFECYCLE_V1` ;
- build `worldserver` post-migration : 10 succès, 0 échec ;
- compatibilité réauditée après mise à jour AzerothCore / Playerbots ;
- runtime CONNECT/DISCONNECT bulk validé sans transport chat bulk observé ;
- audit ciblé Units / lifecycle legacy cleanup exécuté le 06/09/2026 : cleanup utile mais différé jusqu'à la phase finale afin de préserver les fallbacks/parsers encore partagés ;
- Creator `addclass` migré via `CREATOR_ADDCLASS_V1`, build `worldserver` validé (3 succès, 0 échec) et runtime Random/Male/Female/DK + auto-group validé sans spam `.playerbot bot addclass` en SAY ;
- audit final Creator AddClass v1b : `CREATOR_ADDCLASS_V1=VALIDATED`, `WARNING_COUNT=0`, `FATAL_COUNT=0`, Playerbots clean/read-only ;
- Flee migré via `FLEE_ORDER_V1`, puis feedback normal Playerbots rendu chatless sans modifier Playerbots ;
- ALL et TARGET nominatif validés ; une cible non-bot ne produit plus de fausse confirmation ;
- audiences Tank / Healer / DPS / Melee / Ranged enrichies par `FLEE_ORDER_ITEM` autoritaire côté Bridge avant `FLEE_ORDER_ACK` ;
- build `worldserver`, runtime Flee et non-régressions Follow / Stay / Attack validés le 11/09/2026 ;
- prochaine migration active fixée à Group Actions (`drink`, `release`, `revive`, `summon`) ;
- base HEAD Addon auditée avant commit de clôture Flee : `3d99f0c5607e0195d2c8a0fab86a42e92c7b1a61` ;
- base HEAD Bridge auditée avant commit de clôture Flee : `77b709007a13975c4898e845aaf04f0ad2fa067b` ;
- Playerbots `b949b50bfcdd4fab937781bac2d7765e39330e4b` resté strictement read-only.

Les détails de branches anciennes ne doivent plus être présentés comme état courant dans les README.

---

## 13. Références d'audit et checkpoints

Cette section conserve uniquement les preuves structurantes utiles à la reprise. Les détails exhaustifs restent dans les archives de travail.

| Référence | SHA-256 | Portée |
| --- | --- | --- |
| `audit-multibot-flee-closeout-docs-current-state-v1-2026-09-11-175432.zip` | `030F44635E435E41B5A056A77F5975B8F67A7785EF9BFB21536DD7423E32D16D` | Audit final Flee + documentation : hashes finaux Addon/Bridge, 199 locals Comm, Flee ALL/TARGET/rôles nominatif validé, Playerbots clean/read-only, état README/ROADMAP inventorié. |
| `audit-multibot-creator-addclass-final-v1b-2026-09-06-040620.zip` | `601049B069D378410EDE6D8E13BCD5B1DA45786BA8E689B3C0FF1F3D4034D8C6` | Audit final Creator AddClass : hashes post-patch vérifiés, build/runtime Random/Male/Female/DK + auto-group validés, zéro fallback AddClass SAY observé, `init=auto` inchangé, Playerbots clean/read-only. |
| `audit-multibot-units-lifecycle-legacy-cleanup-current-state-v1-2026-09-06-021846.zip` | `5C7829243DFD362901821D2708E39D76137EF512487E33957E59D742E249D689` | Audit ciblé read-only du cleanup Units/lifecycle : baselines intactes, Playerbots sans écriture, fallbacks lifecycle identifiés, parsers partagés conservés ; décision de reporter le cleanup à la phase finale. |
| `audit-multibot-bulk-group-lifecycle-post-push-v1-2026-09-06-013903.zip` | `060586545D36CB4F608E1440593EB98E8F2A547006A9018BB0B853281B7AD2C5` | Clôture post-push : HEAD Addon/Bridge synchronisés, fichiers commités identiques aux hashes runtime validés, Playerbots propre. |
| `audit-multibot-bulk-group-lifecycle-final-v1-2026-09-06-013117.zip` | `4B3D390A119B4B839C65C9EB4E5A66051F1A23D737D1C329535CF05063D73AB7` | Audit final Bulk Group Lifecycle : build 10/0, runtime CONNECT/DISCONNECT validé, aucun bypass Playerbots, 199 locals Comm. |
| `audit-multibot-bulk-lifecycle-post-azerothcore-playerbots-update-v1b-2026-09-06-012035.zip` | `52D40CAD2D39A113B48F62D0581ED8D47815EB1CC312611E23D07213D3A6A8AC` | Audit de compatibilité post-update AzerothCore/Playerbots avant runtime : contrats lifecycle critiques inchangés. |
| `audit-multibot-bulk-lifecycle-playerbots-cleanup-v1-2026-09-05-234855.zip` | `74F9E0624528EC110B87A498638C9522A6419185935DAD11057347D6216DE46C` | Audit ciblé Playerbots read-only : `LogoutPlayerBot()` et cleanup groupe, confirmation que `remove *` n'impose pas le retrait du slot de groupe. |
| `audit-multibot-bulk-lifecycle-add-remove-current-state-v1-2026-09-03-181704.zip` | `21E4AA5657777113401C6600D91FD919CBD31D810B5B9B31A64BACCFF3E3BAFB` | Audit initial Bulk Group Lifecycle : producteur Faction Banner, sémantique `*` réelle du groupe et APIs Playerbots nécessaires. |
| `audit-multibot-docs-post-bulk-roadmap-prior-audit-v1c-2026-09-06-015224.zip` | `1F43023051764733C5B692A793F0BCBBD8D00A8E41325EB5947558FCCD20C1B4` | Audit documentaire read-only post-bulk : snapshots README/ROADMAP actuels et réutilisation de l'historique sans relancer un audit global des commandes. |
| `audit-multibot-lifecycle-docs-raidus-current-state-v1c-2026-09-03-164749.zip` | `CD60E456B2B2F4C4DA716238B52976B9BAE06F5C74F3C85C895A67806643C07A` | Audit read-only post-push : documentation, lifecycle résiduel, snapshots README/ROADMAP/Raidus/Comm/Bridge, 143 `SendChatMessage`, prochain bulk `add * / remove *`. |
| `audit-multibot-raidus-safe-group-remove-final-v1-2026-09-03-163047.zip` | `1E796B59DC113E10216BD948EA2F2CE17BDD32BACA24BC62616EAE991CEFE499` | Clôture finale Raidus Safe Group Remove + Empty Layout Apply, runtime sécurité humain/party/raid et non-régressions validés. |
| `audit-multibot-lifecycle-remaining-playerbot-chat-paths-v1-2026-08-30-212756.zip` | `BEF78AEDA9F4F6486C66F359030E0AF42F2F96D96D5C063B9020D9DDC44861F9` | Audit read-only des 24 occurrences `.playerbot` résiduelles, classification lifecycle, stabilité Git et Playerbots inchangé. |
| `audit-multibot-group-orders-post-push-manual-closure-v1-2026-08-30-210500.txt` | `DE6B8B7926F278ECEC80B084B5966CE5473D6865E388D1E61295EB5141504865` | Clôture post-push Follow/Stay/Attack après confirmation sync/clean et correction des faux négatifs des scripts post-push. |
| `audit-multibot-follow-stay-final-pre-branch-v1c-2026-08-30-181420.zip` | `D0351714C289392B635CB68992AA31D043C17043C0111839884E6126333F11ED` | Clôture Follow/Stay structurés, runtime validé, 199 locals main-chunk et Playerbots intact. |
| `audit-multibot-attack-selectors-bridge-migration-v1-2026-08-30-182703.zip` | `B69122E485CF725B1852A6AB3D7752A923E4A0366E0201617A99839DF9BD0202` | Sémantique exacte des audiences Attack et dépendance `AttackMyTargetAction` au master. |
| `audit-multibot-attack-wait-build-access-v2b-2026-08-30-184309.zip` | `702758ABD0AED5A485391EB23CF9D1FCE9C38977017BEA49B2A865828D797BDF` | `WaitForAttackStrategy`, faisabilité `AttackAction::Attack(Unit*)` et include paths build confirmés. |
| `audit-multibot-group-orders-attack-final-pre-commit-v1-2026-08-30-195459.zip` | `BA45BC56CDD6B8392A6DB236340BEDA8D78AD4B2DBB6484C74CB064462F07F9F` | Audit final Follow/Stay/Attack, build/runtime Attack validés, aucun parser générique. |
| `audit-multibot-alt-roster-lifecycle-post-merge-v1-2026-08-30-143746.zip` | `4FCF642996BDC8B279155EF9018637AA44E4D83F1B0109CC4065A62441B91B8A` | Clôture post-merge Addon #75 / Bridge #34, `main` synchronisés et Playerbots intact. |
| `checkpoint-multibot-friends-favorites-lifecycle-v1-2026-08-29-232823.zip` | `CB90287ED1FCD7D808D83FD22607D1420061642F1478FDCA3278CF1C13271512` | Checkpoint roster Friends/Favorites avant clôture lifecycle. |
| `audit-multibot-item-move-drag-ghost-final-v1-2026-08-16-183942.zip` | `2F149A2CAE53FD839FB077C4E2E1298E389038AF4737F061EAC5E594D05D1C3A` | Validation finale UX drag/drop `ITEM_MOVE_V1`. |
| `audit-multibot-state-strategy-final-v1-2026-08-07-224000-2026-08-07-224709.zip` | `B00DBE597F554F9E20F2ABEFDC22097BC2A06DCDD3F07FD9F6522F98A7DF38DA` | Audit statique final STATE framing / strategy mutations. |
| `audit-multibot-runtime-tests-v1c-2026-08-03-203219.zip` | `44627A920618C747BD9EEB0384D118FFFA13157828677172E46A642436677CB5` | Validation runtime de consultation des formations. |

---

## 14. Maintenance documentaire

Après chaque gros merge :

1. mettre à jour les HEAD des branches actives et leur état de synchronisation ;
2. déplacer les fonctions terminées hors du backlog actif ;
3. ajouter les nouveaux différés réellement confirmés ;
4. conserver les audits/hashes utiles dans la roadmap ;
5. garder les README centrés sur les fonctionnalités et nouveautés visibles ;
6. synchroniser `docs/RAIDUS_GUIDE.md` lorsqu'un comportement utilisateur Raidus change ;
7. vérifier que `TODO.md` local n'a pas été écrasé ;
8. vérifier à nouveau l'intégrité Playerbots read-only.
