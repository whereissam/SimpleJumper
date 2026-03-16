# SimpleJumper

A small Godot 4 platformer prototype with a single level, collectible coins, double jump, wall slide / wall jump, dash logic, and auto-respawn when the player falls.

## Project Structure

- `project.godot`: Godot project config. The main scene is `res://scenes/World.tscn`.
- `scenes/World.tscn`: Entry scene for the game.
- `scripts/World.gd`: Builds the level, coins, player, camera, background, and HUD at runtime.
- `scripts/Player.gd`: Handles player movement, jumping, wall movement, dash behavior, damage, and respawn.

## Requirements

- Godot `4.6` with the `GL Compatibility` renderer enabled in project settings.

## Run

1. Open this folder in Godot.
2. Load `project.godot`.
3. Press `F5` to run the project.

## Controls

- `Left / Right`: Move
- `Space` or `Up`: Jump
- Double jump is supported
- Wall slide and wall jump are supported when pressing toward a wall

## Dash Input

The player script uses a custom `dash` input action, but no `dash` mapping is currently present in `project.godot`.

If you want dash to work, add a `dash` action in Godot's Input Map and bind it to a key such as `Shift` or `X`.

## Gameplay

- Collect all coins to finish the level
- Falling off the map causes damage and respawns the player at the center
- The player has 3 HP and resets after running out

## Notes

- The level is generated from arrays in `scripts/World.gd`, not from manually placed scene nodes.
- The HUD text currently documents movement and jumping, but not dash, which matches the missing input mapping.
