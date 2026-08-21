# Multibot Chatless + Bridge — Roadmap de reprise

Statut : roadmap active issue de l'audit initial v1c du 1er août 2026, resynchronisée le 21 août 2026 après validation des migrations talents sur les branches `jellypowered-chatless-integration-v2`.
Dernière mise à jour : 21/08/2026 — `TALENT_APPLY_V1` et `TALENT_SPEC_APPLY_V1` sont maintenant implémentés, compilés et validés en jeu avec résultats structurés autoritatifs, messages localisés et sans spam chat sur les chemins Bridge normaux. `TALENT_SPEC_APPLY_V1` couvre aussi le slot 2/dual spec et conserve le fallback historique uniquement sous `MultiBot.allowLegacyChatFallback == true`. `TODO.md` reste séparé et inchangé. Le prochain sous-chantier Jellypowered actif devient `CRAFT_RECIPE_TARGET`.
Cette roadmap est la source de vérité active du projet. `TODO.md` reste un fichier de notes local séparé et est volontairement exclu de cette synchronisation documentaire.

## Baseline auditée

Synchronisation documentaire fondée sur :

- `audit-multibot-jellypowered-docs-baseline-v2-2026-08-20-172627.zip` ;
- `audit-multibot-jellypowered-git-state-supplement-v1-2026-08-20-173756.zip` ;
- `audit-multibot-jellypowered-bag-move-item-trade-v1-2026-08-20-174218.zip`.

- Addon : `L:\ChromieCraft_3.3.5a\Interface\AddOns\MultiBot`
  - branche `jellypowered-chatless-integration-v2`, créée depuis `main` le 20/08/2026 ;
  - HEAD = `main` = `origin/main` = `origin/jellypowered-chatless-integration-v2` au baseline audité : `833d541063f207354c4131cf6a614c7df176348d` ;
  - ahead/behind versus `main` : `0/0` avant cette synchronisation documentaire ;
  - PR Jellypowered #67 déjà mergée, merge commit `70e72ba6cb9a7170497b201e0dbe469bb29e6be9` ;
  - PR SelfBot #72 **Complete SelfBot chatless integration** déjà mergée ; le chantier SelfBot reste séparé du développement Jellypowered ;
  - seul `TODO.md` est modifié localement et non stagé ; il est explicitement hors scope de cette synchronisation.
- Bridge : `L:\AC_PB\azerothcore-wotlk\modules\mod-multibot-bridge`
  - branche `jellypowered-chatless-integration-v2`, créée depuis `main` le 20/08/2026 ;
  - HEAD = `main` = `origin/main` = `origin/jellypowered-chatless-integration-v2` au baseline audité : `d42b23dd288b6ff0871c57bedd98856b705594da` ;
  - ahead/behind versus `main` : `0/0` avant cette synchronisation documentaire ;
  - PR Jellypowered #28 déjà mergée, merge commit `5e5ff7594ec8afedf40926605a60848dbc14991e` ;
  - PR SelfBot #30 **Complete SelfBot chatless bridge support** déjà mergée ; le worktree Bridge est propre au baseline audité.
- Playerbots : `L:\AC_PB\azerothcore-wotlk\modules\mod-playerbots`
  - **lecture seule stricte** ; fingerprints source identiques avant/après les audits ciblés du 20/08/2026.
- Communication actuelle : bridge-first pour les principaux rafraîchissements UI et pour plusieurs actions d'écriture explicitement bornées ; des occurrences `SendChatMessage` subsistent et doivent être classées/migrées famille par famille.
- Fallback automatique legacy désactivé par défaut : `MultiBot.allowLegacyChatFallback = false`. Certains chemins de compatibilité historiques restent toutefois explicitement documentés jusqu'à leur migration ou leur suppression validée.

## Règles de progression

Audit → Analyse → Proposition → Validation utilisateur → Patch minimal → Vérifications → Compilation → Tests en jeu → Audit final → Archivage

- Aucun patch à l'aveugle.
- Aucun changement dans `mod-playerbots`.
- Un patch = un objectif.
- Rollback et hashes obligatoires.
- Ne jamais ajouter d'exécuteur bridge générique acceptant une commande Playerbots arbitraire.

## Contribution externe Jellypowered — RÉFÉRENCE CONSERVÉE, ATTRIBUTION OBLIGATOIRE

Deux sources Jellypowered sont conservées comme références de recherche. **Aucune ne doit être fusionnée directement dans `main`.**

### Contribution initiale reçue le 04/08/2026

- auteur : Jellypowered `<Jellypowered@gmail.com>` ;
- commits : `13059a9f334d1e5aaa8560ab29a1814e48b07054`, `7ff1347535be6d5a3256d933731c11c4b3f3b38e`, `04061f084bd189487f1ac0e99892316146f1bea0` ;
- cette contribution reste une source historique à comparer avec l'état actuel.

### Fork `Extended` audité le 15/08/2026 — REPRISE SÉLECTIVE PRIORITAIRE

- fork : `Jellypowered/mod-multibot-bridge`, branche `Extended` ;
- commit `89da6a9dd15be77c3cbfe9be88a9885b632d606a` — extension générale du bridge ;
- commit `40bc0e378b1723d746d3425d4ee0818fd01531c6` — utilisation native d'item ;
- commit `7f9027faf6126bd2854d9f5e84f9a7fa82549077` — resynchronisation partielle avec les fonctions upstream ;
- audit : `audit-multibot-jellypowered-extended-v1-2026-08-15-025145.zip` ;
- SHA-256 réel : `88a64500cb339fe8842d1f3b5a0553145d12f5eff34bbe9e30bd0fed04ed2d7b` ;
- `mod-playerbots` est resté strictement en lecture seule.

La branche `Extended` est divergente et ne doit pas être mergée en bloc. Chaque fonction suit obligatoirement cette matrice :

`Fonction Jellypowered`
→ `Déjà présente chez nous ?`
→ `Absente / partielle / différente ?`
→ `Compatible avec notre sécurité ?`
→ `Utile à la roadmap ?`
→ `REPRENDRE / ADAPTER / REJETER`

### Fonctions à ajouter ou adapter après audit sémantique ciblé

1. **Support multi-préfixes addon configurables — TERMINÉ / VALIDÉ**
   - audit ciblé initial : `audit-multibot-multiprefix-v1c-2026-08-15-133152.zip` ;
   - `MBOT` reste le préfixe MultiBot par défaut ; l'Addon peut utiliser les préfixes configurés et le Bridge applique une whitelist stricte et bornée ;
   - le Bridge répond sur le même préfixe que la requête reçue et n'accepte aucun préfixe arbitraire ;
   - le budget des messages addon reste borné à 255 octets et a été revalidé pendant la stabilisation CAPS.

2. **Inventaire à emplacements exacts, UI bag-aware et déplacement natif — TERMINÉ / VALIDÉ EN JEU**
   - audits ciblés de conception terminés :
     - `audit-multibot-inventory-exact-locations-v1-2026-08-15-135528.zip` ;
     - `audit-multibot-inventory-bag-ui-v1-2026-08-15-142637.zip` ;
   - `INVENTORY_EXACT_V1` est implémenté comme fondation complémentaire à l'`INVENTORY_V1` historique : le chemin legacy `INV_BEGIN` / `INV_ITEM` reste conservé pour les fonctions déjà validées ;
   - le Bridge expose la topologie réelle des conteneurs avec `INV_BAG` et les piles physiques avec `INV_ITEM_LOC`, en utilisant les coordonnées AzerothCore réelles comme référence canonique ;
   - les coordonnées et métadonnées permettent de distinguer sans ambiguïté Backpack, sacs équipés, Keyring et piles identiques situées dans des emplacements physiques différents ;
   - `INV_EQUIP_LOC` n'a pas été nécessaire pour la V1 `ITEM_EQUIP_V1` validée et reste différé jusqu'à l'apparition d'un consommateur réel ;
   - `INVENTORY_BULK_SELL_V1` et `INVENTORY_OPEN_V1` restent préservés ;
   - les données exactes ne sont jamais une autorisation : joueur, contrôle du bot, session/map, coordonnées, item, quantité et état runtime restent revalidés côté Bridge.

   **UI bag-aware réalisée et validée :**
   - taille générale de la fenêtre conservée ; zone grille/scroll réduite pour réserver la barre basse ;
   - barre basse : **Backpack + Sac 1 + Sac 2 + Sac 3 + Sac 4 + Keyring** ;
   - aucune sélection = vue globale ; clic sur un conteneur = filtre local ; second clic sur le même conteneur = retour à la vue globale ;
   - changement de bot = retour à la vue globale ; rafraîchissement du même bot = filtre conservable ;
   - les emplacements vides sont dessinés et les items sont placés dans leurs coordonnées physiques réelles ;
   - les quatre sacs équipés utilisent leurs vraies icônes ; un emplacement de sac absent reste visible mais désactivé ;
   - Backpack utilise la texture client 3.3.5a validée ; Keyring utilise une icône verticale étroite `13x28` sans cadre carré, avec une zone cliquable `32x32` ;
   - les tooltips Backpack / Sac 1..4 / Keyring sont couverts dans les 8 locales Addon auditées ;
   - tests en jeu validés : `/reload`, rendu initial, slots vides, vue globale, filtres Backpack/Sac 1/Sac 2/Sac 3/Sac 4/Keyring, retour à Tous, traductions FR et rendu final Keyring ;
   - le trafic exact reste lié au consommateur UI : l'Addon conserve le chemin legacy puis demande le snapshot exact pour la fenêtre d'inventaire ; aucun polling global n'est introduit.

   **`ITEM_MOVE_V1` réalisé et validé :**
   - endpoint spécialisé `RUN~ITEM_MOVE` pour déplacer une pile entière entre slots physiques autorisés ; le split-stack reste explicitement hors scope ;
   - drag/drop synthétique côté Addon avec `RegisterForDrag("LeftButton")`, résolution de la destination via `GetMouseFocus()` / `__mbExactSlot`, sans `PickupContainerItem`, `PickupInventoryItem`, `GetCursorInfo` ni `ClearCursor` ;
   - aucune mutation optimiste de l'UI : le résultat structuré `INVENTORY_ITEM_MOVE` déclenche un nouveau snapshot exact ;
   - le Bridge revalide bot contrôlable, sessions/monde, source/destination, `itemId`, quantité et positions autorisées Backpack / sacs équipés / Keyring ;
   - protection serveur : **8 requêtes / 2 s / requester**, TTL anti-rejeu **10 s**, **32** tokens récents maximum par requester, état requester borné à **512**, quantité bornée à **1000** ;
   - exécution native par **un seul `Player::SwapItem`**, puis relecture autoritative de la source et de la destination ; succès uniquement si l'état réel a changé ;
   - aucun `SplitItem`, `HandleCommand`, `DoSpecificAction`, exécuteur Playerbots générique ni dépendance chat/whisper sur le chemin `ITEM_MOVE_V1` ;
   - tests en jeu validés : drag/drop même conteneur et inter-conteneurs, rafraîchissement exact après résultat, absence de spam chat et absence de régression constatée ;
   - UI finale validée : groupes visuels par conteneur en vue globale, titres repositionnés, nom jaune redondant supprimé, panneau actions gauche **120 px**, espacement des actions **36/38**, grille inventaire conservée à **8 colonnes** ;
   - audit final : `audit-multibot-item-move-final-v1b-2026-08-15-195912.zip` — `FINAL_STATUS=OK`, `FAILURE_COUNT=0`, `WARNING_COUNT=0` ;
   - attribution Jellypowered à conserver pour les parties réellement reprises ou substantiellement adaptées depuis `Extended`.

3. **Lectures bulk — AUDITÉ / NON INTÉGRÉ**
   - audit ciblé : `audit-multibot-jellypowered-bulk-reads-v1-2026-08-15-205840.zip` — `FINAL_STATUS=OK`, `FAILURE_COUNT=0`, `WARNING_COUNT=0` ;
   - `GET~INVENTORY_BULK` : **rejeter/différer dans sa forme Extended** ;
     - il recouvre partiellement les données déjà fournies par `INVENTORY_EXACT_V1`, qui reste la source autoritative pour la topologie physique Backpack / sacs / Keyring et pour `ITEM_MOVE_V1` ;
     - Extended réutilise `INV_BAG` et `INV_ITEM_LOC` avec des schémas incompatibles avec ceux déjà validés dans notre protocole exact ;
     - aucun consommateur Addon actuel ne nécessite une snapshot d'inventaire multi-bot ;
     - la boucle sur tous les bots visibles n'est pas explicitement bornée et peut amplifier fortement le trafic addon et les logs ;
     - aucun framing générique, comptage de complétude, pagination, ACK ou rate-limit dédié n'est fourni par Extended pour cette famille ;
   - `GET~BOT_SKILLS_BULK` : **différer jusqu'à l'apparition d'un consommateur multi-bot réel** ;
     - `GET~BOT_SKILLS` unitaire et `BuildBotSkillEntries` couvrent déjà le besoin actuel de Character Info ;
     - le format Extended inverse `skillId` et `category` par rapport au schéma `BOT_SKILLS_ITEM` déjà utilisé ;
     - toute reprise future devra conserver le schéma unitaire existant et ajouter des limites explicites de bots/entrées/octets, rate-limit, token/timeout et contrôle de complétude ;
   - aucun besoin de modifier `mod-playerbots` et aucun exécuteur générique/chat Playerbots n'est requis pour ces lectures ;
   - décision : **aucun patch C++/Lua pour ce point** ; le chantier est clos par documentation uniquement.

4. **Équipement et déséquipement natifs d'un item précis — TERMINÉ / VALIDÉ EN JEU**
   - `ITEM_EQUIP_V1` utilise l'endpoint spécialisé `RUN~ITEM_EQUIP~bot~token~srcBag~srcSlot~srcItemId~srcCount` et le résultat structuré `INVENTORY_ITEM_EQUIP` ;
   - la source est limitée au Backpack et aux sacs équipés, avec identité exacte `bag/slot/itemId/count`, revalidation serveur du bot, des droits, sessions, état runtime et source avant exécution ;
   - l'exécution passe par l'auto-équipement natif AzerothCore ; aucun `HandleCommand`, `DoSpecificAction`, exécuteur Playerbots générique ni mutation optimiste Addon n'est utilisé ;
   - le résultat autoritatif déclenche le rafraîchissement de l'inventaire et les tests en jeu ont validé Backpack, sacs 1..4, remplacement d'un slot occupé, interactions 2H/offhand, double-clic rapide, refus d'un objet non équipable et absence de whisper/chat parasite ;
   - `ITEM_UNEQUIP_V1` utilise l'endpoint spécialisé `RUN~ITEM_UNEQUIP~bot~token~srcSlot~srcItemId` et le résultat structuré `INVENTORY_ITEM_UNEQUIP` ;
   - le clic droit Inspect convertit le slot client `1..19` en slot Core `0..18`, puis le Bridge revalide le slot équipé et l'`itemId`, capture le GUID et utilise la voie native `CMSG_AUTOSTORE_BAG_ITEM` vers l'inventaire ;
   - le succès n'est annoncé que si le même GUID est retrouvé hors équipement dans un emplacement physique autorisé Backpack/Sac 1..4 ; aucun appel à `UnequipAction` Playerbots n'est utilisé ;
   - protections `ITEM_UNEQUIP_V1` : **8 requêtes / 2 s / requester**, TTL anti-rejeu **10 s**, **32** tokens récents maximum par requester et état requester borné à **512** ;
   - le fallback legacy `ue` n'est possible que lorsque `MultiBot.allowLegacyChatFallback == true`; avec la configuration bridge-first normale (`false`), aucun whisper automatique n'est émis ;
   - tests en jeu validés : slot simple, main hand, 2H/offhand, inventaire plein, double clic rapide, aucune perte/duplication, rafraîchissement cohérent et zéro chat parasite.

5. **Utilisation native d'un item précis — TERMINÉ / VALIDÉ EN JEU**
   - `ITEM_USE_V1` utilise une source physique exacte et un résultat structuré `INVENTORY_ITEM_USE` ;
   - le Bridge revalide le bot, l'identité de la source et l'état runtime avant d'emprunter le chemin natif `HandleUseItemOpcode` ;
   - aucune mutation optimiste Addon ; le snapshot est rafraîchi après le résultat autoritatif ;
   - la postcondition des objets démarrant une quête a été corrigée ; le cas négatif « quête déjà acceptée » reste un test runtime différé, pas un chantier `ITEM_USE_V1` à réimplémenter.

6. **Déplacement/rééquipement des sacs équipés eux-mêmes — À ADAPTER, priorité faible**
   - `ITEM_MOVE_V1` couvre déjà les piles d'items dans Backpack / sacs 1..4 / Keyring, y compris les déplacements inter-conteneurs ;
   - le résiduel `BAG_MOVE` concerne uniquement l'objet sac placé dans un emplacement de sac équipé ;
   - les emplacements d'équipement des sacs ne font pas partie de la whitelist actuelle `ITEM_MOVE_V1` et ne doivent pas être ajoutés sans audit dédié ;
   - ne jamais présenter ce point comme un déplacement générique des objets d'inventaire.

7. **Échange générique d'un item précis — TERMINÉ / VALIDÉ EN JEU — `ITEM_TRADE_V1`**
   - l'UI Inventory -> Trade utilise désormais un endpoint structuré bridge-first avec identité de source exacte et résultat `INVENTORY_ITEM_TRADE` ;
   - le workflow natif WoW Trade est préservé et le Bridge emprunte le handler AzerothCore natif pour placer l'item exact dans le Trade ;
   - le fallback historique de don/échange reste derrière `MultiBot.allowLegacyChatFallback == true` et n'est pas utilisé en configuration bridge-first normale ;
   - `ENCHANT_TRADE_V1` reste un service spécialisé distinct et n'a pas été généralisé ;
   - validation runtime du 20/08/2026 : Trade natif validé dans les deux sens, aucune régression de l'UI Trade et aucun exécuteur générique de commande Playerbots.

8. **Abandon et partage de quête — TERMINÉ POUR LE BESOIN ACTUEL**
   - `QUEST_ABANDON_V1` utilise `RUN~QUEST_ABANDON~token~questId` et un résultat structuré `QUEST_ABANDON_RESULT` ;
   - le Bridge limite l'exécution aux bots visibles du requester appartenant au même groupe, revalide la sécurité Playerbots, la session/l'état monde et recherche la quête dans les slots bornés `0..MAX_QUEST_LOG_SIZE-1` ;
   - l'abandon bot passe par `WorldPackets::Quest::QuestLogRemoveQuest`, `Read()` puis `WorldSession::HandleQuestLogRemoveQuest`, avec vérification de postcondition ;
   - protections : **4 requêtes / 2 s / requester**, TTL anti-rejeu **10 s**, **32** tokens récents maximum et **512** états requester maximum ;
   - côté Addon, le joueur conserve l'abandon WoW natif `SetAbandonQuest()` / `AbandonQuest()` ; le fallback historique `drop <quest>` n'est disponible que si `MultiBot.allowLegacyChatFallback == true` ;
   - test runtime 1 bot du 20/08/2026 : joueur et bot abandonnent correctement, zéro chat/whisper parasite, zéro erreur Lua ;
   - **test différé roadmap** — `DEFERRED_RUNTIME_TEST_NO_BOTS_AVAILABLE` : scénario avec plusieurs bots dont au moins un sans la quête, faute de bots disponibles au moment de la validation ;
   - `QUEST_SHARE` est déjà natif/chatless via `QuestLogPushQuest()` : aucun endpoint `QUEST_SHARE_V1` n'est créé ni nécessaire pour le comportement actuel.

9. **Application/reset de talents — À ADAPTER AVEC PRUDENCE**
   - endpoint `TALENT_APPLY` ;
   - valider build, niveau, points, coûts/reset, combat, double spécialisation et effets runtime ;
   - vérifier les API Playerbots/AzerothCore dans le dépôt local avant toute reprise.

10. **Artisanat ciblé — À ADAPTER**
    - étudier `CRAFT_RECIPE_TARGET` ;
    - revalider profession, recette, matériaux, outils, cible exacte, compatibilité et état Trade.

11. **Banque / banque de guilde / vendeur — COMPARER PUIS ADAPTER**
    - ces familles existent déjà dans notre Bridge ;
    - ne reprendre que les améliorations démontrables : emplacement exact, quantités, droits, proximité, validation ;
    - ne considérer aucun endpoint vendeur supplémentaire comme acquis sans preuve dans le code.

12. **Comptage d'inventaire / restauration de sélection — COMPARER PUIS ADAPTER**
    - ne reprendre que les corrections démontrées par audit comparatif.

### Fonctions et modèles explicitement rejetés

- **`RUN~CAST_SPELL` générique : REJETER.**
  - un `spellId` arbitraire avec cible élargit trop la surface d'action ;
  - préférer des endpoints spécialisés et bornés comme `ENCHANT_TRADE_V1`.

- **Tout exécuteur Bridge générique de commande Playerbots ou de texte libre : REJETER.**
  - aucun nouvel endpoint ne doit transmettre une commande Playerbots arbitraire ;
  - les helpers de type `HandleCommand()` ne sont pas un modèle pour les nouvelles fonctions.

- **Toute logique contournant les validations serveur : REJETER.**
  - permissions, contrôle du bot, session/map/Trade, longueurs, nombres, emplacements, quantités, rate limiting, erreurs structurées et timeouts restent obligatoires.

- **Toute modification de `mod-playerbots` : INTERDITE.**

### Règle d'intégration Extended

Audit ciblé → Analyse comparative → classification `REPRENDRE` ou `ADAPTER` → validation utilisateur → patch minimal → vérifications → compilation si C++ → tests en jeu → audit final → archivage.

Aucune fonction Extended ne doit être marquée comme intégrée avant validation runtime.

### Attribution obligatoire

- conserver le nom de Jellypowered et les hashes des commits réellement étudiés ;
- chaque PR précise ce qui est repris, adapté, réécrit ou rejeté ;
- reprise substantielle, lorsque pertinent :
  `Co-authored-by: Jellypowered <Jellypowered@gmail.com>` ;
- réécriture seulement inspirée :
  `Design inspired by the Jellypowered bridge contribution.` ;
- les crédits sont ajoutés uniquement pour les parties réellement intégrées et validées.

Statut : **audit Extended validé ; reprise sélective prioritaire avant la roadmap normale ; merge direct du fork interdit.** Le travail Jellypowered courant est isolé sur `feature/jellypowered-chatless-integration` dans l'Addon et le Bridge ; les commits validés y sont accumulés et aucune PR/merge vers `main` ne doit être lancée avant demande explicite de l'utilisateur.


## Phase 0 — Assainissement documentaire — TERMINÉE

Objectif : repartir avec une documentation courte, actuelle et non contradictoire.

Réalisé par `patch-multibot-docs-cleanup-roadmap-v1-2026-08-01-162227` :

- les 18 anciens trackers ont été sauvegardés puis retirés du dossier actif ;
- `TODO.md` a été consolidé dans cette roadmap puis retiré ;
- `docs/ROADMAP.md` est la source de vérité active ;
- `docs/DEBUG_RUNBOOK.md` consolide le guide de debug et d'observabilité ;
- le README référence les deux documents actifs ;
- le package contient un rollback intégral et vérifiable.

Critère de sortie : phase validée par `verify.ps1`, avec hashes post-patch conformes et aucun ancien document actif.

## Validation livrée — Formations chatless — APPLICATION ET CONSULTATION VALIDÉES LE 03/08/2026

Patches fonctionnels validés :

- application : `patch-multibot-formation-chatless-v1c-2026-08-01-181300` ;
- consultation : `patch-multibot-formation-query-chatless-v1-2026-08-03-195340` ;
- localisation : `patch-multibot-formation-query-i18n-v1b-2026-08-03-210300`.

Périmètre validé :

- les clics gauche `arrow`, `queue`, `near`, `melee`, `line`, `circle`, `chaos` et `shield` utilisent désormais `RUN~FORMATION~GROUP` ;
- le bridge applique directement `FormationValue::Load()` sans passer par `HandleCommand()` ni par l'action Playerbots `set formation` ;
- le fonctionnement est validé avec la stratégie `passive`, en groupe et pour l'ensemble des bots contrôlables d'un raid ;
- aucun fichier de `mod-playerbots` n'a été modifié ;
- l'icône de l'addon n'est mise à jour qu'après un `FORMATION_ACK` complet ;
- aucun message `formation ...` n'est envoyé dans PARTY ou RAID pour ces clics ;
- le clic droit utilise `MultiBot.Comm.RequestFormations()` puis `GET~FORMATIONS~GROUP` ;
- le bridge lit la valeur effective de chaque bot avec `FormationValue::Save()` et renvoie `FORMATIONS_BEGIN/ITEM/END` ;
- le résultat est affiché localement, une ligne par bot, dans un tooltip traduit pour les huit locales supportées ;
- aucun message PARTY, RAID, WHISPER ou `TellMaster` n'est produit par la consultation.

Preuves de validation :

- compilation `worldserver` validée par l'utilisateur ;
- audit runtime : `audit-multibot-runtime-tests-v1c-2026-08-03-184046.zip` ;
- SHA-256 de l'audit : `7E3FBD948C51FAE34351B97B416BDFA663061F4577932F6AC251C79ECE933F25` ;
- 11 requêtes `RUN~FORMATION`, 11 réponses `FORMATION_ACK`, 55 applications réussies et 0 échec ;
- les huit formations ont provoqué visuellement le déplacement attendu des bots ;
- l'icône a été mise à jour visuellement sans message chat visible ;
- aucune erreur Lua MultiBot ni ancien blocage `PassiveMultiplier` observé ;
- audit de consultation : `audit-multibot-runtime-tests-v1c-2026-08-03-203219.zip` ;
- SHA-256 de cet audit : `44627A920618C747BD9EEB0384D118FFFA13157828677172E46A642436677CB5` ;
- 9 requêtes `GET~FORMATIONS`, 9 séquences `FORMATIONS_BEGIN/END` et 23 réponses individuelles `FORMATIONS_ITEM` ;
- tooltip local et traductions validés visuellement par l'utilisateur, sans sortie chat.

Reste explicitement hors périmètre :

- la formation Playerbots `far` existe dans le module de référence mais n'est pas exposée par l'interface actuelle.

## Validation intermédiaire — STATE framing + Strategy Mutation — STATIQUE VALIDÉE LE 07/08/2026, RUNTIME FINAL À TERMINER

Baseline intégrée :

- PR #49 : synchronisation bridge, contrôles stratégies, favoris persistants et stabilisation STATE ;
- PR #50 : diagnostics explicites des rejets `RunStrategyCommand` ;
- PR #51 : déduplication mécanique des helpers partagés de workflow roster ;
- addon `main` : `270911305acf3e806d389712a34a9433131db981`.

État STATE validé statiquement :

- capacité `STATE_FRAMING_V1` présente côté addon et bridge ;
- requêtes unitaires `GET~STATE` et globales `GET~STATES` gérées par transactions tokenisées ;
- framing `STATE_BEGIN/STATE_ITEM/STATE_END` et framing global `STATES_BEGIN/.../STATES_END` ;
- `STATE_ABORT` pris en compte comme échec de la requête concernée ;
- timeout par bot à 5 s et timeout global à 15 s ;
- limite de 32 requêtes STATE actives, 128 bots, 256 stratégies par scope, 192 caractères par stratégie et 32768 octets cumulés ;
- nettoyage des transactions sur timeout/erreur/déconnexion ;
- garde d'ordre par bot pour empêcher une réponse ancienne de remplacer un état plus récent.

État mutations stratégies validé statiquement :

- capacité `STRATEGY_MUTATION_V1` présente côté addon et bridge ;
- mutations `co/nc` structurées via `RUN~STRATEGY` pour les chemins utilisant `MultiBot.Comm.RunStrategyCommand()` ;
- résultat serveur via `STRATEGY_ACK` avec compteurs `matched/succeeded/failed` ;
- limites de taille, nombre d'opérations et requêtes actives ;
- timeout à 5 s ;
- neuf diagnostics de rejet explicites ajoutés par F07 ;
- `RunStrategyCommand()` ne contient aucun `SendChatMessage`.

Preuve d'audit final statique :

- archive : `audit-multibot-state-strategy-final-v1-2026-08-07-224000-2026-08-07-224709.zip` ;
- SHA-256 : `B00DBE597F554F9E20F2ABEFDC22097BC2A06DCDD3F07FD9F6522F98A7DF38DA` ;
- 57 contrôles, 0 échec ;
- addon, bridge et `mod-playerbots` ont des empreintes avant/après identiques pendant l'audit ;
- `mod-playerbots` reste strictement en lecture seule.

Reste à terminer avant de fermer définitivement ce bloc :

- le lot Warlock Stones/Soulstones/Pets/Curses est validé pour sa migration chatless et ne fait plus partie des reliquats `co/nc` prioritaires ;
- le comportement sans fallback silencieux des mutations stratégies a été durci et mergé après cette baseline intermédiaire ;
- exécuter/consolider la matrice runtime finale : zéro/un/plusieurs bots, listes longues, fragment manquant/dupliqué/désordonné, réponse tardive, timeouts, déconnexion en cours de transaction, mutations valides/invalides, bot absent, plusieurs bots, smoke test toutes classes, zéro erreur Lua, contrôle chat et logs ;
- classifier puis migrer les autres familles legacy réellement automatiques avant de déclarer le projet entièrement chatless.

## Validation livrée — Sélecteurs Warlock chatless + Stones — MIGRATION CHATLESS VALIDÉE, RELIQUATS SUSPENDUS

Périmètre validé et mergé :

- les sélecteurs Warlock Stones, Soulstones, Pets et Curses utilisent le transport structuré `STRATEGY_MUTATION_V1` / `RUN~STRATEGY` lorsque le bridge est disponible ;
- le chemin bridge attend l'état serveur autoritatif au lieu de valider localement une mutation avant l'ACK ;
- les contrôles Warlock invalides `dps` et `dps debuff` ainsi que le placeholder Buff désactivé ont été retirés et le layout a été compacté ;
- le bridge contient le mécanisme de bascule Firestone/Spellstone et l'endpoint diagnostique à la demande `GET~WEAPON_ENCHANT` / `WEAPON_ENCHANT` ;
- aucun fichier de `mod-playerbots` n'est modifié.

Décision de roadmap au 14/08/2026 :

- la **vérification réelle finale du `TEMP_ENCHANTMENT_SLOT` Firestone/Spellstone** reste un chantier suspendu à reprendre seulement à la fin de la roadmap normale ;
- les **quatre warnings LuaLint restants dans `Strategies/MultiBotWarlock.lua`** restent également suspendus ;
- ces reliquats ne doivent pas interrompre le chantier suivant de la Phase 5.

## Synchronisation post-merge — État livré au 14/08/2026

Les jalons suivants, postérieurs à la mise à jour du 08/08, sont présents dans les branches `main` auditées :

- mutations stratégies : suppression du fallback chat silencieux lorsque le chemin structuré est requis ;
- Outfits : transport bridge-first et négociation `OUTFIT_V1` ;
- inventaire : lecture/rafraîchissement natifs via `INVENTORY_V1` ;
- banque, banque de guilde et achat vendeur : durcissements serveur des actions `ITEM_ACTION` ;
- vente inventaire `SELL_VENDOR` : bridge-first lorsque `INVENTORY_BULK_SELL_V1` est négocié ; le fallback legacy de compatibilité demeure hors chemin normal ;
- `OPEN_ITEMS` : bridge-first via `INVENTORY_OPEN_V1`, avec traitement résiduel borné côté serveur ;
- `GROUP ROLL` : bridge-first via `GROUP_ROLL_V1`, avec mode normal et mode item, filtrage aux bots visibles/contrôlables du groupe, rate-limit serveur et ACK structuré.

Jalons de merge principaux :

- Addon PR #58 — **Migrate inventory Sell Vendor to the bridge** ;
- Bridge PR #24 — **Add safe bridge-first SELL_VENDOR inventory action** ;
- Addon PR #60 — **Add bridge-first OPEN_ITEMS inventory action** ;
- Bridge PR #25 — **Add residual auto-safe OPEN_ITEMS handling** ;
- Addon PR #61 — **Add chatless group Roll UI** — merge `106074c3c93f80812f73af27e746860c7c8a4dcf` ;
- Bridge PR #26 — **Add chatless group Roll support** — merge `210bd1f4f6597fe4f0691ec729ec4904ebe2d463`.

Validation `GROUP ROLL` :

- roll normal 0–100 : OK ;
- roll avec objet par Shift+clic : OK ;
- seuls les bots éligibles au contexte Playerbots invoqué participent au roll item ;
- aucun whisper/chat parasite sur le workflow ;
- protection contre double envoi et refus d'un item vide/invalide ;
- pending nettoyé sur déconnexion/changement de monde ;
- UI finale validée : `240x245`, fond opaque style inventaire, padding horizontal `10 px`, padding vertical haut `10 px` ;
- compilation Bridge déjà validée sans erreur.

## Phase 1 — Baseline de compilation et tests de non-régression

Objectif : prouver le fonctionnement de l'état actuel avant toute correction source.

### Serveur / bridge

- Compiler l'état Git audité sans modification.
- Vérifier le chargement de `mod-multibot-bridge` et de sa configuration.
- Vérifier `HELLO/HELLO_ACK`, `PING/PONG`, erreurs et logs.

### Addon / jeu

Tester avec zéro, un et plusieurs bots :

- chargement initial, `/reload`, déconnexion/reconnexion ;
- bots personnels, AddClass bots et randombots groupés ;
- roster, states, details, stats et PVP stats ;
- inventaire, banque bot, banque de guilde, vendeur ;
- spellbook, talents, glyphes et outfits ;
- quêtes, objets de jeu, character info, réputations, monnaies ;
- recettes, craft et trainer ;
- RTI, Pull Control, Combat Strategies, Disperse et Loot Rules.

Mesurer le chat visible avec `MultiBot.allowLegacyChatFallback = false`.

Critère de sortie : matrice de tests remplie, baseline compilée, bugs reproductibles séparés des impressions anciennes.

## Phase 2 — Durcissement du bridge

Objectif : traiter les risques de sécurité et de blocage avant de développer de nouvelles fonctions.

- Ajouter des parseurs numériques stricts : chaîne entière valide, absence de signe négatif, contrôle d'overflow et bornes métier.
- Borner la taille totale des messages et la longueur de chaque champ.
- Borner les quantités d'actions item, notamment l'achat vendeur.
- Ajouter un rate limiting par joueur et par famille de requêtes `HELLO`, `PING`, `GET` et `RUN`.
- Revalider joueur, session, carte, propriété du bot, proximité PNJ et état du bot au moment de l'exécution.
- Borner les logs et désactiver les logs console par défaut même si la configuration est absente.
- Retourner des erreurs structurées et distinctes pour message malformé, limite dépassée, permission refusée et état incompatible.

Critère de sortie : patch compilé, tests de messages malformés/volumineux, aucune boucle longue pilotable par le client.

## Phase 3 — Stabilisation du protocole addon/bridge

Objectif : fiabiliser les transactions et supprimer les ambiguïtés d'ACK.

- Documenter chaque commande `GET` et `RUN`, ses champs, bornes, réponses et erreurs.
- Identifier les payloads non bornés ; fragmenter notamment le roster si les limites client l'exigent.
- Uniformiser les séquences `BEGIN/ITEM/END` et les tokens de transaction.
- Ajouter timeout, annulation, déduplication et gestion des réponses hors ordre côté addon.
- Distinguer : requête reçue, commande transmise à Playerbots et résultat effectivement vérifié.
- Vérifier perte, duplication, réponses tardives, changement de carte et déconnexion du bot.

Critère de sortie : protocole documenté, transactions déterministes, aucune frame bloquée sur une requête perdue.

## Phase 4 — Corrections runtime prioritaires

Traiter un problème par patch, dans cet ordre :

1. Reconnexion : bots inconnus dans l'UI de groupe Blizzard jusqu'à `/reload`.
2. AddClass bots créés ou sélectionnés au niveau 1 pour un joueur niveau 80.
3. Vérification fonctionnelle de Disperse.
4. Lenteur de l'affichage des glyphes et recentrage des icônes.
5. ID de quête affiché temporairement à la place du titre ; étudier l'avancement de quête par bot.
6. Inventaire au-delà de 16 emplacements.
7. Outfit avec deux armes à deux mains.
8. Compatibilité de l'UI talents/glyphes avec la configuration actuelle.
9. Quick Hunter/Shaman : croix stable et absence de quick bars pour un joueur humain.
10. Raidus : rafraîchissement ouverture/fermeture et purge des bots inconnus/SavedVariables.
11. Respect global du frame strata configuré.
12. Harmonisation de la frame PVP Stats.

Critère de sortie : chaque correction possède reproduction avant, test après et non-régression ciblée.

## Phase 5 — Migration des commandes chat restantes

Objectif : réduire le chat par familles fonctionnelles, sans toucher à Playerbots.

Avant chaque migration, classer l'occurrence `SendChatMessage` comme :

- commande manuelle volontaire ;
- fallback diagnostic ;
- message d'information ;
- mécanisme UI à migrer ;
- code mort à supprimer.

Ordre recommandé et état réel :

1. **Formations — application par clic gauche : TERMINÉ / VALIDÉ** via `RUN~FORMATION~GROUP`.
2. **Consultation de la formation actuelle par clic droit : TERMINÉ / VALIDÉ** via `GET~FORMATIONS~GROUP`, `FORMATIONS_BEGIN/ITEM/END` et tooltip local traduit.
3. **Infrastructure mutations stratégies `co/nc` : TERMINÉE pour les chemins migrés** via `STRATEGY_MUTATION_V1`, `RUN~STRATEGY`, `STRATEGY_ACK`, timeouts, limites et diagnostics explicites.
4. **Sélecteurs Warlock Stones/Soulstones/Pets/Curses : TERMINÉS pour la migration chatless validée**. Les reliquats TEMP_ENCHANT réel et LuaLint sont suspendus et ne bloquent pas la roadmap normale.
5. **`s *` / `SELL_GREY` : SUSPENDU** — le chemin actuel existe, mais le chantier `SELL_GREY / sell-grey core API / bridge-first` est explicitement reporté à la fin de la roadmap.
6. **`s vendor` / `SELL_VENDOR` : TERMINÉ pour le chemin bridge-first inventaire** — `INVENTORY_BULK_SELL_V1`, validation serveur et résultat structuré ; fallback legacy de compatibilité conservé si la capacité n'est pas disponible.
7. **`open items` / `OPEN_ITEMS` : TERMINÉ / VALIDÉ / MERGÉ** — `INVENTORY_OPEN_V1`, Addon PR #60, Bridge PR #25.
8. **`roll` et `roll [item]` : TERMINÉ / VALIDÉ / MERGÉ** — `GROUP_ROLL_V1`, Addon PR #61, Bridge PR #26.
9. **Enchantement d'objet : TERMINÉ / VALIDÉ EN JEU / MERGÉ — Addon #63 / Bridge #27** — `ENCHANT_TRADE_V1`, UI dédiée aux enchanteurs, liste des enchantements réellement connus, composants/outils, Trade WoW natif via le slot « ne sera pas échangé », exécution par ID de sort numérique validé côté bridge, sans exécuteur générique de cast/chat ; layout 440 px et i18n des 8 locales validés.
10. **Spam inventaire automatique à l'ouverture Trade : TERMINÉ / VALIDÉ EN JEU — PR ADDON #64 EN COURS** — réutilisation puis généralisation du filtre addon existant : détection du header exact `=== Inventory ===` pour un bot connu, suppression du dump lors des chemins Inventory → Trade, Enchanting → Trade et du menu natif WoW « Échanger », sans modification de Playerbots ni du Bridge.
11. **PROCHAIN CHANTIER NORMAL — Ajout/retrait d'items précis dans les règles de loot.**
12. **À FAIRE — Décision sur `Quest`/`Skill` versus `Disenchant`**, sans inventer de stratégie absente de Playerbots.
13. **À FAIRE — Ordres collectifs `follow`, `attack`, `stay`**, seulement après validation manuelle exacte des sélecteurs Playerbots ; ne pas réintroduire `RUN~ORDER` générique.

Les commandes informatives `who`, `co ?`, `nc ?` et `ss ?` restent manuelles tant qu'aucune UI structurée ne les remplace. Les mutations UI automatiques `co/nc`, en revanche, doivent passer par le bridge dès qu'un contrat structuré validé existe.

### Validation Enchanting Trade Service — 14/08/2026

- audit Trade/Cast et interfaces Playerbots réalisé en lecture seule ;
- capacité négociée `ENCHANT_TRADE_V1` ;
- `GET~ENCHANT_TRADE` liste uniquement les sorts d'Enchanting connus et valides du bot avec disponibilité des composants/outils ;
- `RUN~ENCHANT_TRADE` accepte uniquement un bot contrôlable, un token et un ID de sort numérique ; aucun GUID d'objet arbitraire, texte de commande ou exécuteur Playerbots générique n'est exposé ;
- cible réelle via le Trade WoW natif et `TRADE_SLOT_NONTRADED`, avec revalidation Core au cast puis à l'acceptation finale du Trade ;
- rate-limit bridge : 4 requêtes par fenêtre de 2 secondes ;
- UI dédiée visible uniquement pour les bots enchanteurs, accessible depuis l'EveryBar et Character Info ;
- fenêtre réduite à 440 px, champ de recherche corrigé et textes Enchant Trade localisés dans les 8 locales runtime ;
- test en jeu : ouverture, liste, recherche, tooltips, Trade et enchantement réel **OK** ;
- spam chat automatique lié au service Enchanting : **aucun après correctif Trade validé le 15/08/2026** ;
- l'ouverture du Trade par l'UI Enchanting réutilise le filtre de dump inventaire déjà employé par Inventory → Trade.

### Validation suppression du dump Inventory à l'ouverture Trade — 15/08/2026

- cause auditée dans Playerbots en lecture seule : `TradeStatusAction::BeginTrade()` envoie automatiquement `=== Inventory ===` puis le contenu de l'inventaire au maître lors du démarrage d'un échange ;
- `mod-playerbots` reste strictement inchangé ;
- le filtre addon existant du bouton Inventory → Trade a d'abord été exporté puis réutilisé par les deux appels `InitiateTrade()` de l'UI Enchanting ;
- le filtre a ensuite été généralisé côté addon pour reconnaître automatiquement le header exact `=== Inventory ===` provenant d'un bot connu uniquement lorsqu'une fenêtre Trade est ouverte, ce qui couvre aussi le menu contextuel natif WoW « Échanger » sans masquer la sortie manuelle `item count` hors Trade ;
- le matching large sur le simple mot `Inventory` a été retiré afin d'éviter de masquer un whisper normal ;
- tests en jeu : Inventory → Trade silencieux, Enchanting → Trade silencieux, menu natif WoW « Échanger » silencieux ;
- enchantement réel et workflow Trade conservés ;
- aucune régression observée par l'utilisateur ;
- Bridge inchangé, Playerbots inchangé, aucun rebuild worldserver requis.

### Chantiers suspendus — à reprendre seulement après la roadmap normale

- `SELL_GREY` / sell-grey core API / bridge-first ;
- vérification réelle finale Firestone/Spellstone `TEMP_ENCHANTMENT_SLOT` ;
- quatre warnings LuaLint restants dans `Strategies/MultiBotWarlock.lua` ;
- autres petits reliquats explicitement reportés lors des étapes précédentes.

Ces sujets restent enregistrés mais **ne doivent pas modifier l'ordre du prochain chantier**.

Critère de sortie : chaque famille migrée fonctionne bridge-first et ne génère plus de réponse chat automatique.

## Phase 6 — Backlog UI et fonctions secondaires

À traiter après sécurité, protocole et bugs prioritaires :

- argent de guilde dans la frame banque de guilde ;
- options de taille des icônes MainBar et Quick Bars ;
- options de déplacement restantes ;
- traductions AceLocale des tooltips Quick Hunter/Shaman ;
- chargement des skins de familiers chasseur ;
- harmonisation de la frame Reward ;
- amélioration Loot Master : tri d'éligibilité, filtres de rôle/classe, recommandation, avertissements, mode compact, historique et debug discret.

Ces fonctions doivent rester séparées des patches de correction et de sécurité.

## Phase 7 — Finalisation

- Compilation complète sans erreur ni nouvel avertissement lié au bridge.
- Tests en jeu complets avec zéro/un/plusieurs bots et groupes importants.
- Audit final des dépendances chat, de la sécurité, des performances et des logs.
- Nettoyage des fallbacks legacy devenus inutiles seulement après preuve de non-régression.
- Mise à jour du README et de la roadmap.
- Création d'un checkpoint et d'une archive ZIP avec manifeste SHA-256 et rollback vérifié.

Critère de sortie : version stabilisée, documentée et reproductible du projet Multibot Chatless + Bridge.

<!-- MULTIBOT_JELLYPOWERED_PROGRESS_SYNC_2026-08-17 -->
<!-- NORMAL_ROADMAP_NEXT=LOOT_RULE_EXACT_ITEM_ADD_REMOVE -->

## État consolidé Jellypowered / inventaire — 20/08/2026

> **Référence de progression actuelle.** Ce bloc supplante les anciens libellés « prochain chantier Jellypowered » conservés plus haut à titre historique. Il ne modifie pas l'ordre de la roadmap normale après clôture du lot Jellypowered.

### Intégré, vérifié et validé

- **Support multi-préfixes addon configurable** : `MBOT` reste le préfixe MultiBot par défaut ; le Bridge utilise une whitelist configurée et répond sur le même préfixe que la requête reçue ; aucun préfixe arbitraire n'est accepté.
- **Inventaire exact / bag-aware** : `INVENTORY_EXACT_V1`, identité exacte `itemId + bag + slot`, vue globale sans sac sélectionné, Backpack + 4 sacs équipés + Keyring ; l'icône Keyring reste étroite et sans cadre carré spécifique.
- **Déplacement exact d'item** : `ITEM_MOVE_V1`, source/destination revalidées côté serveur, pas de mutation optimiste côté Addon, rafraîchissement autoritatif après résultat Bridge.
- **UX drag & drop de `ITEM_MOVE_V1`** : source atténuée pendant le drag, fantôme 32x32 suivant le curseur, `EnableMouse(false)`, détection `GetMouseFocus()` préservée, aucune API native de curseur détournée. Test en jeu validé le 16/08/2026 ; audit final `audit-multibot-item-move-drag-ghost-final-v1-2026-08-16-183942.zip`, SHA-256 `2f149a2cae53fd839fb077c4e2e1298e389038af4737f061eac5e594d05d1c3a`.
- **Équipement exact** : `ITEM_EQUIP_V1` validé.
- **Déséquipement exact** : `ITEM_UNEQUIP_V1` validé.
- **Utilisation native d'un item exact** : `ITEM_USE_V1` validé via endpoint spécialisé et chemin natif `HandleUseItemOpcode`, avec revalidation de la source et résultat serveur autoritatif.
- **Destruction d'un item exact** : `ITEM_DESTROY` validé via endpoint spécialisé.
- **Vente unitaire exacte** : `ITEM_SELL_SINGLE_V1` validé avec source exacte, vendeur proche revalidé, protections des objets non vendables/protégés, rate limit/replay et absence de mutation optimiste.
- **Rachat vendeur** : `VENDOR_BUYBACK_V1` validé avec liste structurée, vendeur proche revalidé, exécution via le handler natif de Buyback et rafraîchissements autoritatifs de l'inventaire et de la liste de rachat.
- **Échange générique exact** : `ITEM_TRADE_V1` validé en jeu dans les deux sens, avec source exacte, Trade WoW natif préservé, résultat structuré et fallback historique explicitement conditionné.
- **Abandon de quête** : `QUEST_ABANDON_V1` compilé et validé avec un bot, via le paquet Quest AzerothCore typé et le handler natif ; zéro spam chat et zéro erreur Lua. Le test multi-bots mixte reste différé faute de bots disponibles.
- **Partage de quête** : déjà natif/chatless via `QuestLogPushQuest()` ; aucun endpoint Bridge additionnel n'est nécessaire.
- **Application de talents personnalisés** : `TALENT_APPLY_V1` compilé et validé en jeu ; validation classe/DBC/points côté Bridge, réutilisation du chemin Playerbots audité, vérification serveur des trois arbres via `BuildTalentTabPoints`, reset des stratégies uniquement après succès et confirmation visuelle localisée côté Addon après `OK`.
- **Sélecteur de spécialisations prémontées** : `TALENT_SPEC_APPLY_V1` compilé et validé en jeu en clic gauche/slot 1 et clic droit/slot 2. `TALENT_SPEC_CURRENT` fournit l'état courant sans whisper normal ; le Bridge revalide l'index du modèle, gère le dual spec, interrompt le cast, applique talents + glyphes, vérifie les totaux finaux et renvoie un résultat structuré. Les anciens `talents`, `talents spec list`, `stopcasting`, `talents switch` et `talents spec` ne restent que dans le fallback explicitement activé.

Toutes ces intégrations conservent `mod-playerbots` en **lecture seule stricte** et n'introduisent aucun exécuteur générique de commande Playerbots.

### Merges validés et nouvelle baseline v2 — 20/08/2026

- Addon : le lot Jellypowered est déjà intégré à `main` via la PR #67, merge commit `70e72ba6cb9a7170497b201e0dbe469bb29e6be9`.
- Bridge : le lot Jellypowered est déjà intégré à `main` via la PR #28, merge commit `5e5ff7594ec8afedf40926605a60848dbc14991e`.
- Le chantier SelfBot, traité séparément, est lui aussi déjà intégré à `main` via Addon PR #72 et Bridge PR #30 ; les capacités héritées sont `SELF_BOT_V1`, `SELF_STRATEGY_V1` et `SELF_ACTION_V1`.
- Les nouvelles branches `jellypowered-chatless-integration-v2` ont été créées directement depuis ces `main` le 20/08/2026 et étaient à `0/0` ahead/behind au baseline audité.
- Les résiduels SelfBot Bridge déjà identifiés (`dps aoe` -> stratégie native `aoe`, robustesse du rollback différé Warlock) restent un chantier séparé et ne doivent pas être corrigés pendant Jellypowered.

### Stabilisation validée avant merge — historique du 17/08/2026

- CAPS : fragmentation/budget wire bornés et corrigés.
- `ITEM_MOVE_V1` : postcondition de déplacement de pile entière corrigée.
- `ITEM_USE_V1` : postcondition des objets démarrant une quête corrigée ; le cas négatif « quête déjà acceptée » reste différé faute de cas runtime dédié.
- `INVENTORY_EXACT_V1` : autorisation explicite côté Bridge corrigée.
- `ITEM_EQUIP_V1` : fallback chat legacy remis sous le flag explicite de compatibilité.
- Inventaire : recyclage de la frame et sécurité item/link en cold-cache corrigés ; les cas runtime cold-cache réel et Unequip exact sans cas reproductible restent différés.
- `ITEM_USE_V1` : namespace locale et raisons d'échec localisées ; tooltip Inspect localisé dans les 8 locales auditées.
- `VENDOR_BUYBACK_V1` : garde nil de création de frame ajoutée sans changement de protocole.
- LuaLint : variable inutilisée `BUYBACK_ROWS` supprimée.
- Ces contrôles constituaient la porte de sortie du lot avant son merge ; les futurs patches Jellypowered v2 devront à nouveau passer les contrôles applicables avant tout nouveau merge.

### Audité et différé / non intégré

- `GET~INVENTORY_BULK` : audité ; la forme Extended reste rejetée/différée tant qu'elle duplique sans bénéfice démontré `INVENTORY_EXACT_V1`.
- `GET~BOT_SKILLS_BULK` : audité ; différé jusqu'à l'apparition d'un consommateur multi-bot réel.

### Jellypowered restant à étudier

Ordre recommandé après cette synchronisation documentaire :

1. `CRAFT_RECIPE_TARGET` — **prochain sous-chantier actif** ; profession/recette/matériaux/outils/cible/Trade à revalider contre le code local avant toute proposition.
2. Banque / banque de guilde / vendeur — comparer avec l'existant et ne reprendre que des améliorations démontrables.
3. Comptage d'inventaire / restauration de sélection — comparer puis adapter uniquement si un défaut actuel est démontré.

`TALENT_APPLY_V1` et `TALENT_SPEC_APPLY_V1` ont quitté cette liste : les deux sont implémentés, compilés et validés en jeu sur la branche v2.

**Résiduel basse priorité, non bloquant :** `BAG_MOVE` concerne uniquement le déplacement/rééquipement des **sacs équipés eux-mêmes**. Les déplacements d'items entre Backpack / sacs 1..4 / Keyring sont déjà terminés via `ITEM_MOVE_V1`.

### Chantiers suspendus — inchangés

À ne pas reprendre pendant la roadmap normale sauf demande explicite :

- `SELL_GREY` / sell-grey core API / bridge-first ;
- diagnostic réel final Firestone / Spellstone `TEMP_ENCHANTMENT_SLOT` ;
- quatre warnings LuaLint restants dans `Strategies/MultiBotWarlock.lua` ;
- autres petits reliquats déjà explicitement reportés.

### Après le lot Jellypowered

Le **prochain chantier normal** reste : **ajout/retrait d'items précis dans les règles de loot**.

La branche `jellypowered-chatless-integration-v2` reste la ligne de travail dédiée. Cette synchronisation documentaire rattrape `TALENT_APPLY_V1` déjà commité/poussé et accompagne `TALENT_SPEC_APPLY_V1` maintenant compilé et validé en jeu. Le prochain sous-chantier Jellypowered actif est `CRAFT_RECIPE_TARGET`. Aucune PR vers `main` n'est prévue à ce stade : les branches v2 doivent encore recevoir les prochains sous-chantiers Jellypowered.
