Où on en est

On a déjà sorti une première grosse brique du retour chat :

Déjà passé sur le bridge
handshake addon ↔ serveur : HELLO / HELLO_ACK / PING / PONG
roster temps réel des bots actifs : ROSTER
états combat / normal pour les everybars : STATE / STATES

En pratique, ça veut dire que le bridge est maintenant capable de porter l’état live des bots déjà connectés, sans parser les whispers de retour pour ça.

Ce qui reste encore dépendant du chat

Il reste un point critique, qu’on vient justement de remettre en route :

1) La reconnexion/restauration au login

Aujourd’hui, elle dépend encore de :

.playerbot bot list
la ligne système Bot roster: ...
puis les .playerbot bot add ...

Donc :

bridge = voit les bots déjà actifs
chat = permet encore de retrouver/reloguer ceux qui ne sont pas encore actifs

C’est la dépendance principale qui reste pour le bootstrap.

2) Une partie des données “riches”

Suivant les panneaux MultiBot, il reste encore du parsing chat pour récupérer par exemple :

stats détaillées,
inventaire / sacs / durabilité,
spellbook / talents / spé,
certains retours de commandes,
éventuellement d’autres vues métier du module.

Autrement dit :
l’état live minimal est en bridge,
mais beaucoup de données d’inspection restent encore en mode “commande → retour chat parsé”.

Ce qu’on a validé techniquement

On a prouvé trois choses importantes :

A. Le bridge n’était pas une fausse piste

Le transport fonctionne.

B. Le bridge seul ne suffit pas encore pour remplacer tout le bootstrap

Parce que son ROSTER actuel ne remonte que les bots déjà présents dans le PlayerbotMgr.

C. Le bon modèle n’est pas “bridge OU chat”

Le bon modèle transitoire est :

bridge prioritaire pour le live
chat en fallback uniquement là où le bridge ne sait pas encore répondre

C’est exactement ce qu’on vient de remettre proprement.

Ce qu’il manque pour rendre MultiBot réellement non dépendant du retour chat

À ce stade, le prochain vrai palier, c’est d’ajouter côté bridge des opcodes qui remplacent les flux historiques les plus structurants.

Priorité 1 : remplacer .playerbot bot list

Il faut un opcode du genre :

KNOWN_BOTS
ou
BOT_LIST

qui renvoie non seulement les bots actifs, mais aussi :

bots connus,
online/offline,
groupés / non groupés,
éventuellement owner/master,
classe / niveau si utile.

Tant qu’on n’a pas ça, la reconnexion automatique gardera une dépendance au chat.

Priorité 2 : remplacer .playerbot bot add ...

Il faut des actions bridge du genre :

CONNECT_BOT~Nom
CONNECT_BOTS~Nom1;Nom2;Nom3
voire RESTORE_GROUP

Là, on casserait la dépendance aux commandes texte pour loguer les bots.

Priorité 3 : batch de stats structuré

Pour le roster et les cadres, il faudrait une réponse structurée du type :

STATS
STATS_BATCH

avec directement :

hp / hpMax
mana / manaMax / rage / énergie / focus / runes si utile
niveau
classe
rôle / spé
map / zone si nécessaire
dead / afk / combat / distance éventuellement

À partir de là, plus besoin de déclencher des retours chat juste pour nourrir l’UI principale.

En résumé franc
Ce qui est déjà “déchatifié”
transport addon
heartbeat
roster live des bots connectés
états combat/normal
Ce qui ne l’est pas encore
découverte complète des bots au login
reconnexion automatique des bots offline
une partie des données détaillées d’UI
Le vrai état du projet

Je dirais qu’on est à peu près ici :

le noyau temps réel est engagé vers le bridge, mais le bootstrap et l’inspection détaillée dépendent encore du chat.

Donc on n’est plus au stade “tout parser dans le chat”,
mais on n’est pas encore au stade “MultiBot totalement piloté par une API serveur structurée”.

Le prochain cap logique

Le prochain chantier le plus rentable est très clair :

1. KNOWN_BOTS
2. CONNECT_BOT(S)
3. STATS_BATCH

Avec ça, on enlève l’essentiel de la dépendance au retour chat pour :

login auto,
roster,
everybars,
vue principale.

Après, le reste pourra être migré panneau par panneau.