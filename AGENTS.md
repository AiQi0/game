# Project Instructions

- Keep `GAME_REFERENCE.txt` updated whenever gameplay entities, environment entities, NPCs, controls, UI, scripts, building definitions, placement rules, demolition rules, or tests are added, removed, or changed.
- Before finishing any gameplay change, check whether `GAME_REFERENCE.txt` needs an update.
- Keep gameplay data separated from gameplay logic. New or changed entity definitions, building/tool/NPC/monster values, economy numbers, timing values, colors, role stats, and similar tunable data should be added to or routed through the data layer first, currently `scripts/GameData.gd` plus existing catalogs/rules such as `scripts/BuildingCatalog.gd`, instead of being hardcoded inside manager or behavior scripts.
- Future gameplay changes must preserve this data separation. If a value must remain in logic for a specific reason, document the reason in `GAME_REFERENCE.txt`.
