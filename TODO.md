TODO
* faire en sorte que la croix de fermeture de quickshamant et quickhunter reste à la même place quand on clique dessus pour les fermer
* Uniformiser le template des frame quetes comme celle de Itemus
* Uniformiser le template de la frame reward comme celle de itemus
* Raidus doit se rafraichir à l'ouverture et fermeture
* dans la liste des quêtes des fois c'est l'ID de la queête qui apparait et pas le tritre
* Mettre une option pour choisir la tailles des icones de la main barre et des quickhunter/shaman
* Voir si il y'a pas d'autres option que l'on peut ajouter à la frame options de multibot
* creer le multilangue pour le tooltip: setTooltip(self, "Show / Hide / Move Quick Shaman") des fichiers quickshaman et quickhunter
* Finir les options de déplacement des boutons
* faire en sorte que les menus déroulants de la main barre se ferment quand on on ouvre un autre
* revoir le fichiers UI/MultiBotTalent, la partie des glyphes et des talents car il y'a eu des modifications dans le fichiers .conf de multibot
* pourquoi les glyphes sont longues a afficher?
* implémenter RTI
* trouver un moyen de charger tous les skins des pets hunter
* tester nouvelle commande /mbdebug : "[MB] Usage: /mbdebug list | /mbdebug on <subsystem> | /mbdebug off <subsystem> | /mbdebug toggle <subsystem> | /mbdebug all on|off | /mbdebug counters [reset]"

Comment tester en jeu (plan concret)
1) Préparer une baseline (debug OFF)
Recharge l’UI (/reload).

Vérifie que tout est OFF:

/mbdebug list → perf=off attendu.

Joue 2-3 minutes normalement (ouvrir/fermer UI, inviter bots, quelques whispers bots).

2) Activer la collecte perf
Active seulement la perf:

/mbdebug on perf

Remets les compteurs à zéro:

/mbdebug counters reset

3) Exécuter les scénarios ciblés M12-2
Cycle événementiel/roster

Ouvre MultiBot, fais un refresh de roster, invite/retire 2-3 bots.

Whisper flow

Déclenche des commandes whisper classiques (stats, co ?, etc.) via flux normal addon.

Scheduler

Ouvre/ferme des écrans qui déclenchent des TimerAfter/NextTick (inventory/reward/spellbook selon ton flow habituel).

Throttle

Lance plusieurs commandes successives pour remplir la queue (ex: actions groupées sur bots).

4) Lire les compteurs
/mbdebug counters

Tu dois voir évoluer des clés de ce type:

events.total, events.chat_msg_whisper

handler.onupdate.calls, handler.onupdate.elapsed

scheduler.timerafter.calls, scheduler.nexttick.calls

throttle.enqueued, throttle.sent, throttle.onupdate.calls

5) Vérifs de non-régression
Désactive perf:

/mbdebug off perf

Rejoue rapidement les mêmes actions.

Vérifie:

pas de spam chat supplémentaire,

pas de comportement différent côté gameplay/UI,

pas de latence perceptible nouvelle.

6) Reset pour itération suivante
/mbdebug counters reset