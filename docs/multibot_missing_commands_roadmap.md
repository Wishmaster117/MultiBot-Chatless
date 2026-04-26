# MultiBot - Roadmap commandes manquantes à ajouter

## Objectif

Ce document suit les commandes `mod-playerbots` encore intéressantes à intégrer dans l'addon MultiBot, en distinguant :

- les commandes utiles dans une interface joueur ;
- les commandes à garder uniquement en usage manuel ;
- les commandes serveur/admin à ne pas intégrer dans l'addon ;
- les priorités d'intégration bridge-first/chatless.

Le principe reste le même que pour Inventory, Spellbook, Glyphs et Outfits :  
**éviter le spam chat automatique**, utiliser le bridge quand c'est possible, et conserver les commandes manuelles utiles comme `who`, `co ?`, `nc ?`, `ss ?`.

---

## Priorité 1 - RTI / Target Icons

### Pourquoi

Le système RTI est très utile pour contrôler les bots en donjon/raid :

- assigner une cible prioritaire ;
- forcer l'attaque d'une cible marquée ;
- définir une cible de contrôle de foule ;
- améliorer les pulls propres et le focus mono-cible.

### Commandes à couvrir

| Commande playerbots | Statut MultiBot | Priorité | Proposition UI |
|---|---:|---:|---|
| `rti skull` | Manquant | Haute | Bouton icône crâne |
| `rti cross` | Manquant | Haute | Bouton icône croix |
| `rti circle` | Manquant | Haute | Bouton icône cercle |
| `rti star` | Manquant | Haute | Bouton icône étoile |
| `rti square` | Manquant | Haute | Bouton icône carré |
| `rti triangle` | Manquant | Haute | Bouton icône triangle |
| `rti diamond` | Manquant | Haute | Bouton icône diamant |
| `rti moon` | Manquant | Haute | Bouton icône lune |
| `attack rti target` | Manquant | Haute | Bouton "Attack RTI" |
| `rti cc <icon>` | Manquant | Haute | Sélecteur CC target |

### Implémentation conseillée

Ajouter une petite fenêtre ou section `RTI` avec les 8 icônes de raid.

Flux conseillé :

```text
RUN~COMMAND~<scope/bot>~<token>~rti skull
RUN~COMMAND~<scope/bot>~<token>~attack rti target
RUN~COMMAND~<scope/bot>~<token>~rti cc moon
```

À faire idéalement en bridge-first, sans parsing chat.

---

## Priorité 2 - Pull Control

### Pourquoi

Les pulls propres demandent plusieurs commandes combinées. Une UI dédiée éviterait les macros manuelles.

### Commandes à couvrir

| Commande playerbots | Statut MultiBot | Priorité | Proposition UI |
|---|---:|---:|---|
| `wait for attack time <seconds>` | Manquant | Haute | Champ numérique 0-10 sec |
| `co +focus` / `co -focus` | Manquant ou non exposé clairement | Haute | Toggle Focus |
| `co -aoe` / `co +aoe` | Partiel | Haute | Toggle AoE during pull |
| `co +assist` | Partiel | Haute | Toggle Assist |
| `attack rti target` | Manquant | Haute | Bouton Attack RTI |
| `co +tank assist` | Partiel | Moyenne | Toggle Tank Assist |

### Proposition UI

Créer une section `Pull Control` :

| Option UI | Commande |
|---|---|
| Wait before attack | `wait for attack time X` |
| Single target pull | `co +focus,-aoe,+assist` |
| Enable AoE again | `co +aoe,-focus` |
| Attack RTI target | `attack rti target` |
| Tank assist | `co +tank assist` |

### Notes

Cette section peut envoyer plusieurs commandes en séquence.  
Il faudra éviter les retours chat automatiques inutiles.

---

## Priorité 3 - Stratégies combat avancées

### Pourquoi

Ces stratégies existent côté playerbots mais ne sont pas toutes exposées clairement dans MultiBot. Elles ont une vraie utilité en raid/donjon.

### Commandes à couvrir

| Stratégie | Commande | Statut MultiBot | Priorité | Intérêt |
|---|---|---:|---:|---|
| Focus | `co +focus` / `co -focus` | Manquant | Haute | Focus mono-cible |
| Avoid AoE | `co +avoid aoe` / `co -avoid aoe` | À vérifier | Haute | Évite les AoE dangereuses |
| Save Mana | `co +save mana` / `co -save mana` | Manquant | Haute | Gestion mana healers |
| Threat | `co +threat` / `co -threat` | Manquant | Haute | Réduit la prise d'aggro |
| Tank Face | `co +tank face` / `co -tank face` | Manquant | Moyenne | Gestion cleave/breath |
| Behind | `co +behind` / `co -behind` | Manquant | Moyenne | Placement melee |
| Healer DPS | `co +healer dps` / `co -healer dps` | À vérifier | Moyenne | DPS des healers hors danger |
| Boost | `co +boost` / `co -boost` | Probablement partiel | Moyenne | Burst cooldowns |
| Wait for attack | `wait for attack time X` | Manquant | Haute | Pull contrôlé |

### Proposition UI

Créer une page `Advanced Combat` ou ajouter un panneau repliable dans les stratégies.

Ne pas afficher tous les boutons dans la barre principale pour éviter de surcharger l'interface.

---

## Priorité 4 - Disperse

### Pourquoi

Très utile pour les mécaniques AoE ou les combats où les bots doivent s'espacer.

### Commandes à couvrir

| Commande playerbots | Statut MultiBot | Priorité | Proposition UI |
|---|---:|---:|---|
| `disperse set <yards>` | Manquant | Moyenne | Champ distance + bouton Apply |
| `disperse disable` | Manquant | Moyenne | Bouton Disable |

### Proposition UI

Section simple :

```text
Disperse distance: [ 8 ] yards
[Apply] [Disable]
```

---

## Priorité 5 - Loot Rules / Loot List

### Pourquoi

Le contrôle du loot est utile, mais moins prioritaire que RTI/pull.

### Commandes à couvrir

| Commande playerbots | Statut MultiBot | Priorité | Proposition UI |
|---|---:|---:|---|
| `nc +loot` | Partiel | Moyenne | Toggle Loot |
| `nc -loot` | Partiel | Moyenne | Toggle Loot |
| `ll all` | Manquant | Moyenne | Profil Loot All |
| `ll normal` | Manquant | Moyenne | Profil Normal |
| `ll gray` | Manquant | Moyenne | Profil Gray |
| `ll quest` | Manquant | Moyenne | Profil Quest |
| `ll skill` | Manquant | Moyenne | Profil Skill |
| `ll [item]` | Manquant | Basse | Ajouter item depuis inventaire |
| `ll -[item]` | Manquant | Basse | Retirer item depuis inventaire |

### Proposition UI

Créer une section `Loot Rules` avec profils prédéfinis.

Les commandes `ll [item]` et `ll -[item]` peuvent être ajoutées plus tard via clic droit sur item dans l'inventaire bridge.

---

## Priorité 6 - Trainer / Maintenance extras

### Pourquoi

Utile ponctuellement, surtout pour les altbots.

### Commandes à couvrir

| Commande playerbots | Statut MultiBot | Priorité | Proposition UI |
|---|---:|---:|---|
| `trainer` | Manquant | Moyenne/Basse | Bouton Check Trainer |
| `trainer learn` | Manquant | Moyenne/Basse | Bouton Learn |
| `maintenance` | Déjà présent ou partiel | Moyenne | À consolider |
| `autogear` | Déjà présent ou partiel | Moyenne | À consolider |
| `talents spec list` | Partiel | Moyenne | À vérifier dans UI talents |
| `talents spec <spec>` | Partiel | Moyenne | Sélecteur spec |
| `talents apply <link>` | Partiel | Basse | Champ/import lien |

### Notes

Ces actions peuvent rester en commandes bridge-first simples.  
Pas besoin de parsing automatique de réponses longues, sauf si une future UI veut afficher les résultats.

---

## Priorité 7 - Items avancés

### Pourquoi

L'inventaire bridge-first est déjà en place. Ces commandes sont des améliorations secondaires.

### Commandes à couvrir

| Commande playerbots | Statut MultiBot | Priorité | Proposition UI |
|---|---:|---:|---|
| `open items` | À vérifier | Moyenne | Bouton dans inventaire |
| `roll` | Manquant | Moyenne | Bouton Roll |
| `roll [item]` | Manquant | Moyenne | Clic droit item |
| `s vendor` | À vérifier | Moyenne | Bouton Sell Vendor |
| `s *` | À vérifier | Moyenne | Bouton Sell Gray |
| `bank [item]` | Manquant | Basse | Clic droit item |
| `bank -[item]` | Manquant | Basse | UI banque |
| `gb [item]` | Manquant | Basse | Clic droit item |
| `gb -[item]` | Manquant | Basse | UI guild bank |
| `b [item]` | Manquant | Basse | UI vendor |

---

## Commandes à garder manuelles

Ces commandes restent utiles pour s'informer ou diagnostiquer un bot, mais ne doivent pas forcément être parsées automatiquement par MultiBot.

| Commande | Décision |
|---|---|
| `who` | Garder manuel |
| `who <profession>` | Garder manuel |
| `co ?` | Garder manuel |
| `nc ?` | Garder manuel |
| `ss ?` | Garder manuel |
| `spells` | Manuel possible, UI bridge déjà présente |
| `glyphs` | Manuel possible, UI bridge déjà présente |
| `talents` | Manuel possible, UI talents présente |
| `stats` | Manuel possible, UI stats bridge présente |
| `quests` | Manuel possible, UI quêtes existante |

---

## Commandes à ne pas intégrer dans l'addon

Ces commandes sont plutôt serveur/admin/debug ou trop dangereuses pour une UI utilisateur normale.

| Commande | Raison |
|---|---|
| `playerbot pmon toggle` | Console/debug performance |
| `playerbot pmon stack` | Console/debug performance |
| `playerbot pmon tick` | Console/debug performance |
| `playerbot pmon reset` | Console/debug performance |
| `playerbot rndbot reset` | Admin serveur |
| `playerbot rndbot stats` | Admin serveur |
| `playerbot rndbot reload` | Admin serveur |
| `playerbot rndbot update` | Admin serveur |
| `playerbot rndbot init` | Dangereux / reroll rndbots |
| `playerbot rndbot clear` | Dangereux |
| `playerbot rndbot level` | Admin serveur |
| `playerbot rndbot refresh` | Admin serveur |
| `playerbot rndbot teleport` | Admin serveur |
| `playerbot rndbot revive` | Buggué selon wiki |
| `playerbot rndbot grind` | Buggué/crash selon wiki |
| `playerbot rndbot change_strategy` | Admin serveur |
| `playerbot bot initself` | Dangereux |
| `playerbot bot tweak` | Peu utile / ancien |
| `playerbot bot lookup` | Peu utile |
| `playerbot bot self` | Debug/expérimental |
| `.playerbots account setKey` | Setup compte, pas gameplay |
| `.playerbots account link` | Setup compte, pas gameplay |
| `.playerbots account linkedAccounts` | Setup compte, pas gameplay |
| `.playerbots account unlink` | Setup compte, pas gameplay |

---

## Commandes non prioritaires ou à éviter

| Commande | Décision |
|---|---|
| `runaway` | Wiki indique actuellement non fonctionnel |
| `do loot` | Wiki indique actuellement non fonctionnel |
| `do add all loot` | Wiki indique actuellement non fonctionnel |
| `rpg status` | Niche |
| `rpg do quest` | Niche |
| `spell rpg` | Niche |
| `log` | Debug |
| `debug spell` | Debug |
| `los` | Utile ponctuellement, mais manuel suffit pour le moment |
| `home` | Niche |
| `taxi` | Niche |
| `chat` | Niche |

---

## Synthèse des prochaines étapes conseillées

| Ordre | Sujet | Type | Priorité |
|---:|---|---|---:|
| 1 | RTI bridge-first | Nouvelle UI + bridge command | Haute |
| 2 | Pull Control | Nouvelle UI + séquences commandes | Haute |
| 3 | Advanced Combat Strategies | UI toggles | Haute/Moyenne |
| 4 | Disperse | Petite UI | Moyenne |
| 5 | Loot Rules | Petite UI profils | Moyenne |
| 6 | Trainer / Maintenance extras | UI maintenance | Moyenne/Basse |
| 7 | Items avancés | Extensions inventaire | Basse/Moyenne |

---

## Notes d'architecture

- Toute nouvelle commande utilisée automatiquement par l'addon devrait passer par le bridge quand possible.
- Les commandes manuelles informatives doivent rester fonctionnelles en whisper/party/raid.
- Ne pas réintroduire de parsing chat automatique pour peupler l'UI.
- Pour les commandes qui ne nécessitent aucun retour structuré, un endpoint générique de type `RUN~COMMAND` peut suffire.
- Pour les commandes qui doivent alimenter une frame, préférer un endpoint structuré dédié.
- Les commandes serveur/admin ne doivent pas être exposées dans l'addon utilisateur.
