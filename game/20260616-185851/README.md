# New Project

A minimal Godot 4.6 2D side-scroller prototype.

See `GAME_REFERENCE.txt` for the entity, key, feature, and file registry. Keep that registry updated whenever gameplay entities, controls, UI, or rules change.

## Run

Open this folder in Godot and press Play.

## Controls

- Left: `Left Arrow` or `A`
- Right: `Right Arrow` or `D`
- Select build target: top-row `1` to `4`
- Cancel selected build target: press the selected number again
- Build selected target: `E`
- Start demolition: `Q`
- Confirm demolition: `Q` again
- Cancel demolition: `E` or leave the building footprint
- Interact with homeless NPC: `E`

## Build Targets

- `1`: 铁匠铺
- `2`: 城墙
- `3`: 农田
- `4`: 酒馆

The build preview appears in front of the player. Green means the target can be built. Red means it overlaps another building and cannot be built.

Press `Q` while standing inside a demolishable footprint to mark it as a red demolition preview. Press `Q` again before leaving the footprint to remove it. The city hall cannot be demolished. Randomly placed trees can be demolished with the same `Q` flow.

The map has air walls at both ends, so the player cannot leave the ground span and build previews cannot be placed inside those end barriers. Every five minutes the game rolls a 30% chance to spawn 2-4 homeless NPCs at random map positions. Press `E` near a homeless NPC to turn them into a villager; villagers wander near the city hall.

Villagers prefer work over idling: after conversion, each villager reserves the nearest available non-city-hall building, walks to its front, then disappears inside to work. Each building holds one villager. Empty buildings have dark windows; occupied buildings have lit windows. If an occupied building is demolished, its villager appears at the demolished building's position. If no building is available, the villager stays near the city hall until an empty building exists.

The day-night cycle runs on a 10-minute loop: 5 minutes of day followed by 5 minutes of night. The sun appears during the day and the moon appears at night, both moving across the distant sky on an arc. Air walls at both map ends are now thicker, with matching build-blocking zones.
