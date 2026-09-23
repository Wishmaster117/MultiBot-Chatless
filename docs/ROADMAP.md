# Multibot Chatless + Bridge — Roadmap

**Statut : active**
**Dernière synchronisation : 23/09/2026**

Cette roadmap est la **source de vérité technique** du projet.
Les README Addon/Bridge servent de vitrine fonctionnelle et restent volontairement plus courts.

---

## 1. Baseline actuelle

### Addon

```text
Repo:   L:\ChromieCraft_3.3.5a\Interface\AddOns\MultiBot
Branch: feature/group-orders-chatless
HEAD:   36144e183686fa939f58f170a44bcfd21c198fac
```

État fonctionnel audité au 23/09/2026 :

- Follow / Stay / Attack, Flee, Group Actions et RTSC livrés et runtime validés ;
- lifecycle rosters, Raidus Safe Apply et bulk group lifecycle livrés ;
- Creator `addclass` et `init=auto` livrés via leurs endpoints spécialisés ;
- Quest interactions structurées, Autogear, Maintenance M1/M2, Hunter Pet H1/H2/H3 et Spellbook Cast / Ignore clôturés ;
- Trainer T1/T2 clôturé : timeout 8 s, corrélation stricte des tokens, drainage `DISCONNECTED` et `Tout apprendre` transitif borné ;
- Outfit L1/E1/E2 clôturé : lifecycle déterministe, résultat equip/replace, framing borné et libellé delete i18n validés ;
- compatibilité Rogue Strategy Rename clôturée sans fusionner les contrôles Dps Assist / Aoe / Tank Assist ;
- Formation F1–F6 clôturée via `FORMATION_V1`, y compris UI autoritaire, protections rate-limit/replay et exposition `far` ;
- Craft normal C1 clôturé avec idempotence/anti-rejeu Bridge et tests normal/répété/target/rapid-click ;
- Warlock Firestone/Spellstone clôturé via `WARLOCK_STONE_STATE_V1` : état physique autoritaire, icônes authentiques, OFF physique, application silencieuse et message système ;
- `Core\MultiBotComm.lua` working tree final : `8fda18a57270188676993850d0052d565b211144754fe994caf0d6e304603252` ;
- `Strategies\MultiBotWarlock.lua` working tree final : `e1cdf413e01ba49824bf277f76d4b254669f18b7a0cfcf072df4abdf7199cc1f` ;
- ordre restant : reliquats techniques explicitement différés, puis audit global des chemins chat et cleanup legacy final.

### Bridge

```text
Repo:   L:\AC_PB\azerothcore-wotlk\modules\mod-multibot-bridge
Branch: feature/group-orders-chatless
HEAD:   49f8d9f7af64f33af43f8d0cab73515515e0cca9
```

État fonctionnel audité au 23/09/2026 :

- endpoints group/lifecycle et ordres collectifs précédemment validés conservés ;
- `CREATOR_ADDCLASS_V1`, `CREATOR_INIT_AUTO_V1`, les cinq capacités Quest, `AUTOGEAR_OPTIONS_V1`, `BOT_MAINTENANCE_V1`, Hunter Pet H1/H2/H3 et Spellbook Cast / Ignore restent validés ;
- Trainer T2 conserve son `Tout apprendre` transitif borné ; son hardening rate-limit/anti-rejeu spécifique reste différé ;
- Outfit L1/E1/E2 est clôturé ; ses hardenings secondaires restent explicitement différés ;
- `FORMATION_V1` couvre le lifecycle Formation F1–F6 validé ;
- Craft normal C1 applique un rate-limit indépendant de 4 requêtes / 2 s et une protection replay TTL 10 s, 32 tokens, 512 requesters ;
- `WARLOCK_STONE_STATE_V1` fournit l'état physique autoritaire Firestone/Spellstone et le chemin spécialisé d'application silencieuse, sans modifier Playerbots ;
- aucun exécuteur Playerbots générique n'a été ajouté ;
- `src\MultiBotBridge.cpp` working tree final : `930e3509cf4426e5113d45f6c5e40b1cc85fcd820ab0bd3b6fa6f8a8bf0cd670`.

### Playerbots

```text
Repo:   L:\AC_PB\azerothcore-wotlk\modules\mod-playerbots
Remote: https://github.com/mod-playerbots/mod-playerbots
Branch: master
HEAD:   7bae1b5c58c76a0aa20381155edc08096d1485b2
Mode:   STRICT READ ONLY
```

**Règle absolue :** aucune modification de `mod-playerbots` dans ce projet. Pour compiler le Bridge, utiliser la révision courante de `master` du dépôt officiel `mod-playerbots/mod-playerbots`; le SHA ci-dessus est la révision validée le 23/09/2026.

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
- `GROUP_ACTION_V1` pour `drink`, `release`, `revive` et `summon`, runtime validé sans fallback chat automatique ;
- `RTSC_ORDER_V1` pour ENABLE / RESET / SELECT / CANCEL / SAVE / UNSAVE / GO, audiences rôles et groupes, avec AEDM natif conservé ;
- `QUEST_ACCEPT_ALL_V1`, `QUEST_TALK_V1`, `QUEST_GAMEOBJECT_USE_V1`, `QUEST_REWARD_V1`, `QUEST_REWARD_POLICY_V1` ;
- `AUTOGEAR_OPTIONS_V1` pour le workflow Autogear options/confirmation/apply ;
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
- `init=auto` a ensuite été migré séparément via `CREATOR_INIT_AUTO_V1` ;
- Playerbots resté strictement read-only.

### Creator — Init Auto spécialisé

Livré après AddClass via :

```text
CREATOR_INIT_AUTO_V1
```

Le protocole expose uniquement `TARGET` ou `GROUP`. Le Bridge applique validation, rate-limit et anti-rejeu, puis délègue à `PlayerbotMgr::ProcessBotCommand("init=auto", ...)` pour conserver les règles Playerbots. Le mode groupe retourne les compteurs initialized/skipped/failed. Aucun exécuteur Playerbots générique n'est exposé.

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

Aucun cleanup lifecycle n'est donc appliqué à ce stade. À la date de cet audit, le sous-chemin Creator `addclass` venait d'être migré via `CREATOR_ADDCLASS_V1` et Creator `init=auto` était le chantier suivant. Creator `init=auto` a depuis été clôturé via `CREATOR_INIT_AUTO_V1`; le cleanup lifecycle reste différé jusqu'au cleanup final.

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

Après clôture Maintenance + Hunter Pet H1/H2/H3 puis Spellbook Cast / Ignore au 19/09/2026, l'ordre recommandé devient :

1. reliquats techniques explicitement différés selon priorité ;
2. nettoyage final global des fallbacks/parsers chat devenus morts, **incluant le cleanup Units / lifecycle legacy déjà audité**.

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

À la clôture **Group Actions** du 11/09/2026, le chantier suivant était **RTSC**. RTSC a depuis été clôturé via `RTSC_ORDER_V1`.

---

## 7ter. Clôture Group Actions Chatless — 11/09/2026

### Capacité livrée

```text
GROUP_ACTION_V1
```

Périmètre volontairement fermé :

```text
DRINK   -> Playerbots "drink"
RELEASE -> Playerbots "release"
REVIVE  -> Playerbots "spirit healer"
SUMMON  -> Playerbots "summon"
```

Architecture validée :

```text
Group Actions UI
  -> MultiBot.ActionToGroup(exact action)
  -> RUN~GROUP_ACTION~token~ACTION
  -> validation Bridge + scope groupe/raid + security + rate/replay
  -> PlayerbotAI::DoSpecificAction(native action)
  -> GROUP_ACTION_ACK
```

Garanties de clôture :

- aucune commande Playerbots arbitraire acceptée par cet endpoint ;
- allowlist serveur fermée aux quatre actions auditées ;
- scope borné à 40 bots et protections group-order existantes réutilisées ;
- contrôle `PLAYERBOT_SECURITY_ALLOW_ALL` conservé côté Bridge ;
- `revive` utilise l'action native `spirit healer` au lieu de réimplémenter le lifecycle de résurrection ;
- fallback PARTY/RAID conservé uniquement si `MultiBot.allowLegacyChatFallback == true` ;
- tentative structurée non rétrogradée silencieusement vers le chat ;
- `Core\MultiBotComm.lua` reste à **199 locals** au niveau chunk principal ;
- Playerbots resté strictement read-only.

Validation runtime :

```text
worldserver build = OK
server start      = OK
DRINK             = VALIDATED
RELEASE           = VALIDATED
REVIVE            = VALIDATED
SUMMON            = VALIDATED
GROUP_ACTION_ACK  = OBSERVED
legacy chat spam  = NOT OBSERVED
```

Audit final :

```text
audit-multibot-group-action-v1-final-v1c-2026-09-11-201814.zip
SHA-256 52B58083BF66E29B774ADECB17122EB9C54E56C19918B81F17DFAE12C487E0FF
FATAL_COUNT=0
WARNING_COUNT=1
FINAL_STATUS=OK_WITH_WARNINGS
```


Hashes code de clôture :

```text
MultiBotComm.lua   FEEC5C0811B4B9BA2EEC49ECEAB1A23B1C6653BA4A2225D37FC561926BBED4F8
MultiBotEngine.lua BE19850C472CF85FB69AE3292D8F15DB71EBBB6471E5F93DE4A2A2670FB33DE6
MultiBotBridge.cpp E43FCB40DF864AFAE8A12D6CC3EC0FBFA82E6B5C58EAAB49E1F3B3C2204596B0
```

À la clôture **RTSC** du 12/09/2026, le chantier suivant était **Quest interactions**. Les interactions Quest structurées ont depuis été clôturées via les cinq capacités `QUEST_*` listées ci-dessous.

---

## 7quater. Clôture RTSC Chatless — 12/09/2026

### Capacité livrée

```text
RTSC_ORDER_V1
```

Requête structurée :

```text
RTSC_ORDER~token~OP~AUDIENCE~GROUP_MASK~SLOT
```

ACK :

```text
RTSC_ORDER_ACK~token~OP~AUDIENCE~GROUP_MASK~SLOT~matched~succeeded~failed~reason
```

Opérations autorisées :

```text
ENABLE
RESET
SELECT
CANCEL
SAVE
UNSAVE
GO
```

Audiences autorisées :

```text
ALL
TANK
HEALER
DPS
MELEE
RANGED
MELEE_DPS
RANGED_DPS
GROUPS
```

`GROUP_MASK` vaut `0` hors `GROUPS`. Pour `GROUPS`, le protocole valide un masque borné ; l'UI actuelle expose les groupes 1..5. `SLOT` vaut `1..9` pour SAVE / UNSAVE / GO et `0` pour les autres opérations.

### Architecture Playerbots conservée

Le Bridge ne réimplémente pas RTSC. Il adapte la requête structurée vers l'action native auditée :

```cpp
botAI->DoSpecificAction("rtsc", Event("rtsc", nativeParam, requester), true);
```

`ENABLE` conserve la sémantique native du sort `RTSC_MOVE_SPELL 30758` avec postcondition vérifiée. `SELECT` tient compte de la postcondition native `RTSC selected`.

Règle AEDM canonique :

```text
/cast aedm
-> cast WoW natif
-> Playerbots SeeSpellAction
-> MoveToSpell
```

Le Bridge :

```text
raw coordinates      -> NO
SpellCastTargets RTSC-> NO
MoveToSpell clone    -> NO
AEDM reimplementation-> NO
```

Le comportement runtime observé reste natif : un bot en Follow peut revenir vers le master après le déplacement ; un bot en Stay conserve la destination RTSC.

Les mutations `co/nc +rtsc,+guard,?` restent volontairement sur `STRATEGY_MUTATION_V1` et ne sont pas remigrées.

### Validation runtime

Validé en jeu :

- ENABLE / RESET ;
- SELECT ALL ;
- TANK / HEALER / DPS ;
- MELEE / RANGED ;
- MELEE_DPS / RANGED_DPS ;
- GROUPS 1..5 ;
- sélections multi-groupes ;
- SAVE / GO / UNSAVE ;
- CANCEL ;
- AEDM natif ;
- comportement Follow / Stay ;
- absence de transport legacy visible `rtsc ...` en PARTY/RAID sur le chemin structuré ;
- hotfix du pattern Lua `@group` validé sans récurrence de l'erreur `malformed pattern`.

`MultiBotComm.lua` reste à **199 locals** au niveau chunk principal. Playerbots est resté strictement read-only.

### Hashes code de clôture RTSC

```text
MultiBotComm.lua
312741C60FDFFB49ACEF351C9B99204B510DD58510C8E23D3C8C21BEA4F1981F

MultiBotEngine.lua
1449F78EAA4BB2F6C7AC547F6D534B912834937482AED71CB692BEC5C68ECE59

MultiBotBridge.cpp — RTSC final avant cleanup warnings
3F6EE3470DB5B535AB187185C8D7A3EA18D69F6DA14C5ADAEA8D75528A7DA354

MultiBotBridge.cpp — courant après cleanup warnings
668A46994456CBD71B56C319CE0D16D6E21F092BD02237311B7C0ADCFDD10C23
```

### Audit final RTSC

```text
audit-multibot-rtsc-order-v1-final-v1c-2026-09-12-122116.zip
SHA-256 FDE1388AD4F297A1552CD64F2805DB20CFC97F6A6CBA0050F71B484DD40FD297
FATAL_COUNT=0
WARNING_COUNT=0
FINAL_STATUS=OK
```

Les deux `FATAL` du premier script d'audit final étaient des faux positifs de l'audit lui-même : deux références `RunRtscOrderCommand` correspondaient à une garde + un appel réel, et les quatre `SpellCastTargets` du Bridge étaient tous hors du bloc RTSC.

### Cleanup warnings Bridge post-RTSC

Deux warnings GCC observés sur Linux dans `MultiBotBridge.cpp` ont été audités puis corrigés **sur l'arbre Windows** :

- `PlayerScript::OnPlayerCanUseChat(...4 args...)` masqué par les overloads Bridge : correction par `using PlayerScript::OnPlayerCanUseChat;` ;
- `GetGuildBankWithdrawRemaining(...)` définition-only : helper mort supprimé.

Validation Windows :

```text
Build worldserver: 3 succeeded, 0 failed
Bridge runtime: OK
RTSC smoke test: OK
Guild Bank smoke test: OK
normal chat smoke test: OK
crash regression: none observed
```

Audit final du hotfix :

```text
audit-multibot-bridge-compile-warnings-final-v1-2026-09-12-134628.zip
SHA-256 07BF5E6107A6C6198737FF5029FF65D9B183B019D327D8B699DA097DAAF60D35
LIVE_EQUALS_EXACT_TWO_CHANGE_TRANSFORMATION=YES
FATAL_COUNT=0
WARNING_COUNT=0
FINAL_STATUS=OK
```

La disparition effective des deux warnings GCC reste à confirmer au prochain build Linux de cette branche. Le warning `mod-lfr` sur son paramètre `reload` est hors périmètre MultiBot.

---

## 7quinquies. Clôture Quest interactions structurées — 14/09/2026

Capacités livrées :

```text
QUEST_ACCEPT_ALL_V1
QUEST_TALK_V1
QUEST_GAMEOBJECT_USE_V1
QUEST_REWARD_V1
QUEST_REWARD_POLICY_V1
```

Le Bridge conserve l'autorité sur le requester, le contrôle bot, les limites et les résultats. L'Addon utilise des requêtes structurées pour accept-all, talk, GameObject use et reward, et reçoit la politique de reward serveur. Le correctif Addon du 14/09 rend également la recherche GameObject structured-only avec loading gate.

Playerbots reste strictement read-only.

---

## 7sexies. Clôture Autogear options / i18n / AceGUI / deferred-open — 17/09/2026

Capacité livrée :

```text
AUTOGEAR_OPTIONS_V1
```

État final validé :

- limites qualité/iLvl autoritaires côté Bridge ;
- modes valeurs serveur / qualité / match iLvl joueur / iLvl personnalisé ;
- reset explicite de l'équipement porté ;
- workflow `AUTOGEAR_INFO → AUTOGEAR_PLAN → confirmation → AUTOGEAR_APPLY` ;
- lifecycle silent-reset sans faux warning de login/reload ;
- i18n officielle `MultiBot.L` avec **49 clés × 8 locales** ;
- fenêtre AceGUI cohérente avec les fenêtres modernes MultiBot ;
- deferred-open : refus initial (ex. bot < niveau 5) affiché en alerte sans ouvrir de fenêtre vide ;
- runtime final : bot valide `Viz` OK, bot bas niveau `Heal` refusé proprement ;
- Playerbots inchangé/read-only.

Hashes finaux :

```text
Features\MultiBotAutogear.lua  1843AF73ADFBD2C527E8CE50BA7C127541090E9A56ACB36473404DB3EB74BEAB
src\MultiBotBridge.cpp          A4B5B6FA845C7F732C82C569852C4D9D43BD53A9105BB8750911FF02C0BFF7EE
```

Audits finaux :

```text
audit-multibot-autogear-i18n-final-v1c-2026-09-15-161909.zip
SHA-256 996FE5B1C27EDA7AE91A0CA89B1FE188D6A76C75081118E3D1A89559E6E3EC4C

audit-multibot-autogear-ui-deferred-open-final-v1-2026-09-17-190701.zip
SHA-256 EA5F49B9ABFE74501D825704B16510F9B24AB6D879F043A1F44D43D24C00D0B9
```

---

## 7septies. Clôture Hunter Pet H1/H2/H3 — 18/09/2026

Capacités livrées :

```text
HUNTER_PET_CONTROL_V1
HUNTER_PET_MANAGE_V1
HUNTER_PET_LIFECYCLE_V1
```

État final validé :

- H1 control : `AGGRESSIVE`, `DEFENSIVE`, `PASSIVE`, `ATTACK`, `FOLLOW`, `STAY` ;
- H2 manage : `TAME_ID`, `TAME_FAMILY`, `RENAME`, `ABANDON` ;
- H3 lifecycle : `DISMISS`, `CALL` ;
- `ABANDON` reste destructif via `PET_SAVE_AS_DELETED` ;
- `DISMISS` conserve le pet courant via `PET_SAVE_AS_CURRENT` et désactive temporairement la stratégie Playerbots `pet` en `BOT_STATE_NON_COMBAT` uniquement si elle était active ;
- `CALL` utilise le sort Hunter `883` et restaure `+pet` uniquement si le Bridge avait retiré la stratégie ;
- UI Hunter Quick : Call / Dismiss / Abandon distincts, tooltips dans 8 locales ;
- `MultiBotComm.lua` final à **199 locals** ;
- Hunter Quick final à **0 `SendChatMessage`** ;
- H3a compilé, worldserver redémarré et runtime validé ;
- H3b runtime validé ;
- `mod-playerbots` strictement read-only.

Hashes finaux pré-commit documentation :

```text
Core\MultiBotComm.lua           0EE6916C4E8C0299D594ADE3570C9FC86155A4F326FC9DD165156D7E43483DEC
UI\MultiBotHunterQuickFrame.lua 6614C804A4238B6882233E3A212C6CF0BEC19777DB1FC6260375583AC88EF9D9
src\MultiBotBridge.cpp          5ADAEA8198105EEF24D5EADFAC8A7CC7190DA93F2678BD84F439B799E18F2906
```

Audit final :

```text
audit-multibot-hunter-pet-h1-h2-h3-final-v1-2026-09-18-192853.zip
SHA-256 E4CFFD5763DA3C821830F188C9154E92B952C1AA96FCFC9CD99769300426EE26
FINAL_STATUS=OK
```

Checkpoint final :

```text
checkpoint-multibot-hunter-pet-h1-h2-h3-v1-2026-09-18-193155.zip
SHA-256 1DFB038072ED1DC75C97334EF666162C14B526185DC52CADCFD49D7D1664D4FD
manifest 146/146 verified
8 successful packages
6 apply reports copied
FINAL_STATUS=OK_WITH_WARNINGS
```

Les deux warnings du checkpoint sont documentaires : deux anciens rapports `apply` ne sont plus présents. Ils ne remettent pas en cause le manifest 146/146, les hashes finaux ni la validation runtime.

---

## 7octies. Clôture Spellbook Cast / Ignore Chatless — 19/09/2026

Capacités livrées :

```text
SPELLBOOK_CAST_V1
SPELLBOOK_IGNORE_V1
```

### Cast

Le Spellbook envoie désormais le `spellId` sélectionné via un endpoint Bridge dédié. Le résultat revient par ACK structuré et le feedback d'échec utilisateur est localisé. Le chemin normal ne dépend plus d'un whisper `cast` et aucun exécuteur générique `RUN~CAST_SPELL` n'a été introduit.

### Ignore / Allow

La case d'ignorance utilise désormais les opérations structurées `IGNORE` / `ALLOW`. Le Bridge revalide requester, bot contrôlé, état session/world, `spellId` et appartenance au Spellbook avant mutation de l'état Playerbots existant.

Le chemin Spellbook ne contient plus :

```text
ss +<spellId>
ss -<spellId>
Ignored spell list
```

L'état `ignored` du snapshot serveur reste autoritaire et le feedback succès n'est affiché qu'après ACK.

### UI et i18n

- feedback succès ajout/retrait dans les 8 locales chargées ;
- bouton footer `Ignorés (N)` / `Tous les sorts` ;
- bouton visible mais désactivé lorsque `N=0` en vue normale ;
- grille 3×6 inchangée ;
- pagination recalculée sur la vue filtrée ;
- checkbox toujours actionnable en vue filtrée ;
- retrait du dernier sort ignoré : vue filtrée vide conservée jusqu'au clic `Tous les sorts` ;
- géométrie finale validée : `125×18`, ancre `TOPRIGHT`, `Y=-270`, `X=12`.

### État final validé

```text
Core\MultiBotComm.lua
B5DA10182B40CC9100499C7EB8BE7136D8A08788D8E92C601DC42DB89C3A502D

UI\MultiBotSpell.lua
F69C69FE0F2F6B0D2CFBEB404B54548AFAC2697FFCA3A21BE33A38C826F9B60E

UI\MultiBotSpellBookFrame.lua
F86CD2B3ECECBAC0A48BDF98CDAFD9A3FE5096BED554BAD06E337FB4E53CFBA1

Bridge src\MultiBotBridge.cpp
64627A37BF000704078966728487A0C1BDBA69A1427231B9C99B34C079ED2F0D
```

Validation :

- `MultiBotComm.lua` reste à **199 locals** au niveau chunk principal ;
- zéro `ss +` / `ss -` sur le chemin Spellbook ;
- zéro texte `Ignored spell list` dans le chemin Addon audité ;
- zéro exécuteur générique `RUN~CAST_SPELL` ;
- runtime cast / ignore / allow / filtre validé en jeu ;
- `mod-playerbots` strictement read-only.

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

---

## 9. Clôtures techniques récentes et hardening différé

Les chantiers lifecycle/idempotence qui étaient encore ouverts au 19/09 sont désormais clôturés. Les éléments listés comme différés ci-dessous restent volontairement hors du prochain lot fonctionnel.

### Lifecycle Trainer — terminé (20/09/2026)

Le lifecycle Trainer est borné et déterministe :

- timeout de 8 s pour la liste et l'apprentissage ;
- résultat `DISCONNECTED` déterministe et drainage des transactions en cours ;
- corrélation stricte `requestToken` / `pendingToken` côté UI ;
- aucun pending UI bloqué après perte de connexion ;
- `Tout apprendre` traite transitivement les rangs nouvellement débloqués avec une boucle bornée côté Bridge ;
- communication structurée Addon/Bridge, sans fallback chat sur le chemin Trainer ;
- Playerbots reste strictement read-only.

Hardening Trainer volontairement différé :

- rate-limit / protection anti-rejeu spécifique aux endpoints Trainer ;
- revue de parité avec `PlayerbotFactory::IsTrainerSpellAllowedForBot()`.

### Lifecycle Outfit — terminé et archivé (20/09/2026)

La clôture Outfit couvre :

- L1 lifecycle déterministe avec tokens/timeouts, corrélation stricte et drainage sur disconnect ;
- E1 traitement du résultat equip/replace ;
- E2 transport framed borné à 255 octets ;
- libellé delete i18n validé ;
- tests runtime passés et checkpoint final archivé ;
- Playerbots inchangé/read-only.

Hardening Outfit volontairement différé :

- gestion renforcée des doublons ring/trinket ;
- rate-limit / anti-rejeu dédié ;
- contrôle d'autorisation plus strict ;
- noms contenant des séparateurs ;
- cleanup global du fallback chat legacy ;
- diagnostic du malformed packet WorldSocket hors de ce chantier.

### Rogue Strategy Rename Compatibility — terminé (20/09/2026)

La divergence entre les noms de stratégie Rogue a été corrigée : l'Addon conserve son alias/UI sans confondre les contrôles Dps Assist / Aoe / Tank Assist, tandis que le Bridge adapte les spécialisations Rogue vers les stratégies Playerbots attendues (`combat` / `assassin`). Les commits Addon/Bridge ont été poussés et synchronisés.

### Lifecycle Formation F1–F6 — terminé et archivé (21/09/2026)

La clôture Formation comprend :

- F1 idempotence ;
- F2 capability `FORMATION_V1` ;
- F3 UI autoritaire ;
- F4 rate-limit / replay ;
- F5 héritage de l'état désiré et stabilité de l'icône ;
- F6 exposition de `far`, avec l'icône `Spell_Nature_FarSight` et `AiPlayerbot.FarDistance=20.0` ;
- compilation/runtime validés ;
- Playerbots inchangé/read-only.

### Craft normal C1 — terminé et archivé (22/09/2026)

Le chemin `PROFESSION_RECIPE_CRAFT` possède désormais son propre hardening Bridge :

- rate-limit indépendant : 4 requêtes / 2 s ;
- replay TTL : 10 s ;
- 32 tokens conservés ;
- 512 requesters maximum ;
- état indépendant de `CRAFT_RECIPE_TARGET_V1` ;
- tests runtime normal, répété, target et rapid-click validés ;
- Playerbots inchangé/read-only.

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

Ordre courant après les clôtures Trainer, Outfit, Rogue compatibility, Formation F1–F6, Craft C1 et Warlock du 20–23/09/2026 :

```text
1. reliquats techniques explicitement différés selon priorité
2. audit global actualisé des chemins chat encore actifs
3. final legacy parser/fallback cleanup
   including Units / lifecycle legacy cleanup
```

Maintenance, interactions Quest, Autogear, Hunter Pet H1/H2/H3, Spellbook Cast / Ignore, Trainer, Outfit, Rogue compatibility, Formation F1–F6, Craft C1 et Warlock Firestone/Spellstone sont clôturés dans la baseline courante ; ne pas les remettre dans la file active sans nouvel audit ciblé.

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
- audit final Creator AddClass v1c : `CREATOR_ADDCLASS_V1=VALIDATED`, `WARNING_COUNT=0`, `FATAL_COUNT=0`, Playerbots clean/read-only ;
- Flee migré via `FLEE_ORDER_V1`, puis feedback normal Playerbots rendu chatless sans modifier Playerbots ;
- ALL et TARGET nominatif validés ; une cible non-bot ne produit plus de fausse confirmation ;
- audiences Tank / Healer / DPS / Melee / Ranged enrichies par `FLEE_ORDER_ITEM` autoritaire côté Bridge avant `FLEE_ORDER_ACK` ;
- build `worldserver`, runtime Flee et non-régressions Follow / Stay / Attack validés le 11/09/2026 ;
- Group Actions (`drink`, `release`, `revive`, `summon`) migrées via `GROUP_ACTION_V1`, build/runtime validés le 11/09/2026, audit final fatal-free et Playerbots resté read-only ;
- RTSC migré via `RTSC_ORDER_V1` le 12/09/2026, audiences/groupes/SAVE/GO/UNSAVE/CANCEL et AEDM natif validés ;
- hotfix Lua du sélecteur `@group` validé ;
- audit final RTSC v1c : fatal-free, 199 locals Comm, Playerbots clean/read-only ;
- cleanup warnings Bridge post-RTSC appliqué sur Windows : `OnPlayerCanUseChat` base overload réexposé et helper guild-bank mort supprimé ;
- build Windows du hotfix : 3 succès, 0 échec ; runtime Bridge/RTSC/Guild Bank/chat normal validé ;
- confirmation GCC/Linux des deux warnings Bridge encore à effectuer au prochain build Linux ;
- Quest interactions structurées livrées côté Addon/Bridge ;
- Autogear options/i18n/AceGUI/deferred-open clôturé et runtime validé ;
- Hunter Pet H1/H2/H3 livré via trois capacités dédiées ; `DISMISS`/`CALL` séparés de l'abandon destructif, UI 8 locales, 199 locals Comm et zéro chat Hunter Quick validés ;
- audit final Hunter Pet `E4CFFD...EE26` OK et checkpoint `1DFB0380...D4FD` vérifié 146/146 ;
- Maintenance clôturée ; Hunter Pet H1/H2/H3 clôturé, compilé lorsque requis et runtime validé le 18/09/2026 ;
- Spellbook Cast / Ignore clôturé et runtime validé le 19/09/2026 via `SPELLBOOK_CAST_V1` et `SPELLBOOK_IGNORE_V1`, avec feedback 8 locales, filtre ignorés et zéro fallback `ss +/-` ;
- Trainer T1/T2 clôturé le 20/09/2026 : lifecycle 8 s, drainage `DISCONNECTED`, corrélation stricte des tokens et `Tout apprendre` transitif borné ; hardening rate-limit/anti-rejeu et parité trainer-policy différés ;
- Outfit L1/E1/E2 clôturé et archivé le 20/09/2026 ; lifecycle, equip/replace, framing <=255 octets et i18n delete validés ;
- Rogue Strategy Rename Compatibility clôturée le 20/09/2026, avec adaptation `combat` / `assassin` et contrôles Dps Assist / Aoe / Tank Assist préservés ;
- Formation F1–F6 clôturée et archivée le 21/09/2026 via `FORMATION_V1`, avec idempotence, UI autoritaire, rate-limit/replay, stabilité d'état/icône et `far` validés ;
- Craft normal C1 clôturé et archivé le 22/09/2026 : 4 requêtes / 2 s, replay TTL 10 s, 32 tokens, 512 requesters ; tests normal/répété/target/rapid-click validés ;
- Warlock Firestone/Spellstone clôturé et archivé le 23/09/2026 via `WARLOCK_STONE_STATE_V1` : H1/H1b/H1c/H2/W3 validés, icônes authentiques, OFF physique, application silencieuse et message système ; Playerbots inchangé ;
- ordre restant : reliquats techniques différés, audit global actualisé des chemins chat, puis cleanup legacy final ;
- HEAD Addon courant au 23/09/2026 : `36144e183686fa939f58f170a44bcfd21c198fac` ;
- HEAD Bridge courant au 23/09/2026 : `49f8d9f7af64f33af43f8d0cab73515515e0cca9` ;
- Playerbots officiel `master` `7bae1b5c58c76a0aa20381155edc08096d1485b2` resté strictement read-only.

Les détails de branches anciennes ne doivent plus être présentés comme état courant dans les README.

---

## 13. Références d'audit et checkpoints

Cette section conserve uniquement les preuves structurantes utiles à la reprise. Les détails exhaustifs restent dans les archives de travail.

| Référence | SHA-256 | Portée |
| --- | --- | --- |
| `audit-multibot-warlock-final-global-v1-2026-09-23-191459.zip` | `4B1D1E59982469F3D444FC1D93F0018AC82B81AFBA07494E27BF57AC138427B1` | Audit global final Warlock : hashes finaux exacts, W3/silent-use/system-ACK/H2/H1-H1c conservés, build/runtime worldserver identiques, Playerbots clean/read-only, zéro warning. |
| `checkpoint-multibot-warlock-final-v1-2026-09-23-191826.zip` | `78994886DBDB07A22E67AF3F8099B6A94FF034D9F20F4DA7D8226A5DAFF28CBD` | Checkpoint définitif Warlock : manifest 50 entrées vérifié, audits/packages/snapshots archivés, `WARLOCK_CHANTIER_STATUS=CLOSED`, aucun write Playerbots. |
| `audit-multibot-hunter-pet-h1-h2-h3-final-v1-2026-09-18-192853.zip` | `E4CFFD5763DA3C821830F188C9154E92B952C1AA96FCFC9CD99769300426EE26` | Audit final Hunter Pet H1/H2/H3 : trois capabilities validées, 199 locals Comm, zéro `SendChatMessage` Hunter Quick, 8 locales, H3 compile/runtime validé, 57 hashes Playerbots clean/read-only. |
| `checkpoint-multibot-hunter-pet-h1-h2-h3-v1-2026-09-18-193155.zip` | `1DFB038072ED1DC75C97334EF666162C14B526185DC52CADCFD49D7D1664D4FD` | Checkpoint final Hunter Pet : manifest 146/146 vérifié, 8 packages réussis, 6 rapports apply copiés ; `OK_WITH_WARNINGS` uniquement pour 2 rapports historiques absents. |
| `audit-multibot-autogear-ui-deferred-open-final-v1-2026-09-17-190701.zip` | `EA5F49B9ABFE74501D825704B16510F9B24AB6D879F043A1F44D43D24C00D0B9` | Audit final UI Autogear + deferred-open : chaîne UI/hotfix cohérente, guards i18n/wire/PLAN-APPLY/AceGUI conservés, runtime `Viz`/`Heal` validé, 112 hashes protégés, Playerbots clean/read-only. |
| `audit-multibot-autogear-i18n-final-v1c-2026-09-15-161909.zip` | `996FE5B1C27EDA7AE91A0CA89B1FE188D6A76C75081118E3D1A89559E6E3EC4C` | Audit final i18n Autogear : 49 clés exactes × 8 locales, `MultiBot.L`, lifecycle hotfix conservé, runtime FR validé, Playerbots clean/read-only. |
| `audit-multibot-rtsc-order-v1-final-v1c-2026-09-12-122116.zip` | `FDE1388AD4F297A1552CD64F2805DB20CFC97F6A6CBA0050F71B484DD40FD297` | Audit final RTSC : `RTSC_ORDER_V1`, hotfix group pattern présent, 199 locals Comm, audiences/groupes/SAVE/GO/UNSAVE/CANCEL/AEDM validés, Playerbots clean/read-only, zéro fatal/warning. |
| `audit-multibot-bridge-compile-warnings-final-v1-2026-09-12-134628.zip` | `07BF5E6107A6C6198737FF5029FF65D9B183B019D327D8B699DA097DAAF60D35` | Audit final du cleanup warnings Bridge post-RTSC : transformation byte-exact limitée au `using PlayerScript::OnPlayerCanUseChat;` et à la suppression du helper mort, build/runtime Windows validés ; revalidation GCC/Linux encore attendue. |
| `audit-multibot-group-action-v1-final-v1c-2026-09-11-201814.zip` | `52B58083BF66E29B774ADECB17122EB9C54E56C19918B81F17DFAE12C487E0FF` | Audit final Group Actions : `GROUP_ACTION_V1`, hashes code validés, 199 locals Comm, build/server/runtime DRINK/RELEASE/REVIVE/SUMMON validés, Playerbots clean/read-only. |
| `audit-multibot-flee-closeout-docs-current-state-v1-2026-09-11-175432.zip` | `030F44635E435E41B5A056A77F5975B8F67A7785EF9BFB21536DD7423E32D16D` | Audit final Flee + documentation : hashes finaux Addon/Bridge, 199 locals Comm, Flee ALL/TARGET/rôles nominatif validé, Playerbots clean/read-only, état README/ROADMAP inventorié. |
| `audit-multibot-creator-addclass-final-v1c-2026-09-06-040620.zip` | `601049B069D378410EDE6D8E13BCD5B1DA45786BA8E689B3C0FF1F3D4034D8C6` | Audit final Creator AddClass : hashes post-patch vérifiés, build/runtime Random/Male/Female/DK + auto-group validés, zéro fallback AddClass SAY observé, `init=auto` inchangé, Playerbots clean/read-only. |
| `audit-multibot-units-lifecycle-legacy-cleanup-current-state-v1-2026-09-06-021846.zip` | `5C7829243DFD362901821D2708E39D76137EF512487E33957E59D742E249D689` | Audit ciblé read-only du cleanup Units/lifecycle : baselines intactes, Playerbots sans écriture, fallbacks lifecycle identifiés, parsers partagés conservés ; décision de reporter le cleanup à la phase finale. |
| `audit-multibot-bulk-group-lifecycle-post-push-v1-2026-09-06-013903.zip` | `060586545D36CB4F608E1440593EB98E8F2A547006A9018BB0B853281B7AD2C5` | Clôture post-push : HEAD Addon/Bridge synchronisés, fichiers commités identiques aux hashes runtime validés, Playerbots propre. |
| `audit-multibot-bulk-group-lifecycle-final-v1-2026-09-06-013117.zip` | `4B3D390A119B4B839C65C9EB4E5A66051F1A23D737D1C329535CF05063D73AB7` | Audit final Bulk Group Lifecycle : build 10/0, runtime CONNECT/DISCONNECT validé, aucun bypass Playerbots, 199 locals Comm. |
| `audit-multibot-bulk-lifecycle-post-azerothcore-playerbots-update-v1c-2026-09-06-012035.zip` | `52D40CAD2D39A113B48F62D0581ED8D47815EB1CC312611E23D07213D3A6A8AC` | Audit de compatibilité post-update AzerothCore/Playerbots avant runtime : contrats lifecycle critiques inchangés. |
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
7. vérifier à nouveau l'intégrité Playerbots read-only.
