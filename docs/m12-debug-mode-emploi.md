# MultiBot — Mode d'emploi Debug & Observabilité (M12)

Date: 2026-04-15  
Scope: Milestone 12 (M12-1 → M12-4)

Ce document explique **comment utiliser le debug MultiBot en jeu** sans casser le gameplay ni flooder le chat.

---

## 1) Principe général

- Le debug est piloté par `MultiBot.Debug` et la commande `/mbdebug`.
- Par défaut, les flags debug sont **OFF**.
- Les compteurs perf (`events.*`, `handler.*`, `scheduler.*`, `throttle.*`) ne s'incrémentent que si `perf=on`.
- Les impressions debug verbeuses utilisent un garde-fou anti-spam (`PrintRateLimited`) pour limiter les rafales.

---

## 2) Commandes disponibles

### 2.1 Inspection de l'état

```text
/mbdebug list
```

Affiche tous les sous-systèmes et leur état (`on/off`).

### 2.2 Activer / désactiver un sous-système

```text
/mbdebug on <subsystem>
/mbdebug off <subsystem>
/mbdebug toggle <subsystem>
```

Exemples:

```text
/mbdebug on core
/mbdebug off core
/mbdebug on perf
```

### 2.3 Activer / désactiver tous les flags

```text
/mbdebug all on
/mbdebug all off
```

### 2.4 Compteurs perf

```text
/mbdebug counters
/mbdebug counters reset
```

- `counters`: affiche un snapshot des compteurs.
- `counters reset`: remet à zéro tous les compteurs.

---

## 3) Sous-systèmes debug

Liste actuelle (susceptible d'évoluer):

- `core`
- `options`
- `scheduler`
- `roster`
- `quests`
- `spellbook`
- `migration`
- `perf`

> Recommandation: activer uniquement le sous-système ciblé pendant l'analyse.

---

## 4) Lecture des compteurs perf

Exemples de clés fréquemment observées:

- `events.total`
- `events.chat_msg_whisper`
- `handler.onupdate.calls`
- `handler.onupdate.elapsed`
- `scheduler.timerafter.calls`
- `scheduler.nexttick.calls`
- `throttle.enqueued`
- `throttle.sent`

Interprétation rapide:

- `*.calls` : volume d'appels.
- `*.elapsed` / `*.delay_total` : temps agrégé (pas une moyenne).
- `throttle.enqueued` >> `throttle.sent` : file qui grossit (possible surcharge côté commandes).

---

## 5) Protocole de test en jeu (baseline → debug)

## Phase A — Baseline (debug OFF)

1. `/reload`
2. `/mbdebug all off`
3. Jouer 2-5 minutes (roster, commandes whispers, actions UI habituelles).
4. Vérifier l'absence de spam chat/debug.

## Phase B — Mesure perf ciblée

1. `/mbdebug on perf`
2. `/mbdebug counters reset`
3. Rejouer les scénarios:
   - refresh roster,
   - commandes whispers fréquentes,
   - flux qui déclenchent `TimerAfter/NextTick`,
   - burst de commandes pour le throttle.
4. `/mbdebug counters`
5. Noter les compteurs clés (captures écran/chat recommandées).

## Phase C — Vérification anti-spam debug

1. `/mbdebug on core`
2. Rejouer un scénario à événements rapides.
3. Vérifier que le chat reste lisible (throttling par clé).

## Phase D — Retour à l'état nominal

```text
/mbdebug off core
/mbdebug off perf
/mbdebug counters reset
```

---

## 6) Bonnes pratiques

- Toujours partir de `all off` avant un test.
- Activer un nombre minimal de flags.
- Réinitialiser les compteurs avant chaque scénario.
- Ne pas laisser `core`/`perf` actifs en permanence en production.

---

## 7) Checklist de bug report (debug)

Pour un ticket reproductible, fournir:

1. Version addon + date du test.
2. Flags actifs (`/mbdebug list`).
3. Scénario exact (étapes joueur).
4. Snapshot compteurs (`/mbdebug counters`).
5. Résultat attendu vs observé.