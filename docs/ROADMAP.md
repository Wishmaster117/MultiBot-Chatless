# Multibot Chatless + Bridge — Roadmap

**Statut : active**
**Dernière synchronisation : 30/08/2026**

Cette roadmap est la **source de vérité technique** du projet.
Les README Addon/Bridge servent de vitrine fonctionnelle et restent volontairement plus courts.

`TODO.md` est un fichier local séparé et n'est pas utilisé comme source de vérité de cette roadmap.

---

## 1. Baseline actuelle

### Addon

```text
Repo:   L:\ChromieCraft_3.3.5a\Interface\AddOns\MultiBot
Branch: main
HEAD:   09e0233c1f2e17d03c191d1be67da926767c955d
Remote: origin/main = même HEAD
```

- PR #75 **Feature/alt roster bot lifecycle** mergée.
- `TODO.md` reste une modification locale séparée et hors scope des patches documentaires.

### Bridge

```text
Repo:   L:\AC_PB\azerothcore-wotlk\modules\mod-multibot-bridge
Branch: main
HEAD:   24cef0badfde0c06fc0b917b7510f8f15220a775
Remote: origin/main = même HEAD
```

- PR #34 **Feature/alt roster bot lifecycle** mergée.
- Baseline post-merge auditée et propre.

### Playerbots

```text
Repo: L:\AC_PB\azerothcore-wotlk\modules\mod-playerbots
HEAD: 2f7d9f774987d0157c6a0d0cc08c40bec3db3945
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
- plusieurs contrôles combat/non-combat.

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
- arbres `main` identiques aux feature heads validés ;
- Playerbots resté strictement inchangé.

---

## 5. Prochain chantier normal

### Audit ciblé `follow` / `attack` / `stay`

Le prochain chantier fonctionnel recommandé est :

```text
audit ciblé des ordres collectifs follow / attack / stay
```

Avant toute conception :

- vérifier les sélecteurs/actions/API Playerbots réels ;
- vérifier les scopes réellement supportés ;
- vérifier le comportement groupe/raid ;
- identifier les dépendances chat actuelles ;
- vérifier permissions et états runtime ;
- ne pas concevoir d'endpoint générique `RUN~ORDER` à l'aveugle.

Aucun nouveau code avant audit + analyse + validation utilisateur.

---

## 6. Backlog différé

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

## 7. Reliquats techniques à auditer

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

## 8. Reliquats chat / finalisation globale

Le projet ne doit pas être décrit comme **fully chatless** tant que les occurrences restantes de `SendChatMessage` n'ont pas été classées.

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
- continuer les tests de spam chat après chaque migration.

---

## 9. Contribution Jellypowered — historique conservé

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

## 10. Historique récent de clôture

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
- audit post-merge lifecycle final : propre.

Les détails de branches anciennes ne doivent plus être présentés comme état courant dans les README.

---

## 11. Références d'audit et checkpoints

Cette section conserve uniquement les preuves structurantes utiles à la reprise. Les détails exhaustifs restent dans les archives de travail.

| Référence | SHA-256 | Portée |
| --- | --- | --- |
| `audit-multibot-alt-roster-lifecycle-post-merge-v1-2026-08-30-143746.zip` | `4FCF642996BDC8B279155EF9018637AA44E4D83F1B0109CC4065A62441B91B8A` | Clôture post-merge Addon #75 / Bridge #34, `main` synchronisés et Playerbots intact. |
| `checkpoint-multibot-friends-favorites-lifecycle-v1-2026-08-29-232823.zip` | `CB90287ED1FCD7D808D83FD22607D1420061642F1478FDCA3278CF1C13271512` | Checkpoint roster Friends/Favorites avant clôture lifecycle. |
| `audit-multibot-item-move-drag-ghost-final-v1-2026-08-16-183942.zip` | `2F149A2CAE53FD839FB077C4E2E1298E389038AF4737F061EAC5E594D05D1C3A` | Validation finale UX drag/drop `ITEM_MOVE_V1`. |
| `audit-multibot-state-strategy-final-v1-2026-08-07-224000-2026-08-07-224709.zip` | `B00DBE597F554F9E20F2ABEFDC22097BC2A06DCDD3F07FD9F6522F98A7DF38DA` | Audit statique final STATE framing / strategy mutations. |
| `audit-multibot-runtime-tests-v1c-2026-08-03-203219.zip` | `44627A920618C747BD9EEB0384D118FFFA13157828677172E46A642436677CB5` | Validation runtime de consultation des formations. |

---

## 12. Maintenance documentaire

Après chaque gros merge :

1. mettre à jour les HEAD `main` ;
2. déplacer les fonctions terminées hors du backlog actif ;
3. ajouter les nouveaux différés réellement confirmés ;
4. conserver les audits/hashes utiles dans la roadmap ;
5. garder les README centrés sur les fonctionnalités et nouveautés visibles ;
6. vérifier que `TODO.md` local n'a pas été écrasé ;
7. vérifier à nouveau l'intégrité Playerbots read-only.
