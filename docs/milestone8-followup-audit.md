# Audit Milestone 8 Followup — migration Quests vers Ace3

Date d’audit: 2026-03-29
Branche auditée: `work` (HEAD local)

## Verdict (mis à jour)

La migration Quests/GameObject est désormais **complète pour le périmètre Milestone 8** :

- ✅ Frames Quests/GameObject extraites dans des fichiers dédiés `UI/`.
- ✅ Popups Quests (`Log`, `Incomplete`, `Completed`, `All`) rendus via widgets AceGUI.
- ✅ Popups GameObject (`Results`, `Copy`) en flux AceGUI nettoyé.
- ✅ Helpers legacy de construction de scroll/html supprimés de `UI/MultiBotQuestUIShared.lua`.
- ✅ Le menu Quests de la barre droite est maintenant traité comme validé pour le scope M8 (pas de blocage de migration restant).

## Changements validés depuis l’audit initial

### Popups migrés en rendu AceGUI
- `UI/MultiBotQuestLogFrame.lua`
- `UI/MultiBotQuestIncompleteFrame.lua`
- `UI/MultiBotQuestCompletedFrame.lua`
- `UI/MultiBotQuestAllFrame.lua`
- `UI/MultiBotGameObjectResultsFrame.lua`
- `UI/MultiBotGameObjectCopyFrame.lua`

### Nettoyage de code legacy
- Suppression des anciens constructeurs UI legacy maintenant inutiles dans `UI/MultiBotQuestUIShared.lua`:
  - `ClearFrameChildren`
  - `CreateSectionTitle`
  - `CreateSummaryLabel`
  - `CreateStyledScrollArea`
  - `CreateQuestHTML`
  - `BindHyperlinkTooltip`

## État fonctionnel

### Conservé
- Logique métier de parsing/agrégation Quests/GameObject.
- Modes groupe/whisper et enchaînement des actions.
- Tooltips, loading, close/hide, ESC, persistance de position.

### Finalisation
1. Validation in-game complète effectuée sur le scope Quests/GameObject M8 (parité visuelle + interactions).
2. Trackers docs M8 mis à jour pour refléter la clôture du milestone.
3. Les actions restantes sont du polish optionnel hors critère de complétion M8.

## Conclusion opérationnelle

Par rapport à l’objectif “on supprime la frame legacy et ses contours et on recode en Ace3”:

- ✅ **Objectif Milestone 8 atteint sur la migration Quests/GameObject**.
- ✅ **Aucun reliquat bloquant de migration n’est conservé dans le scope M8**.