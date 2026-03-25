# SimpleJumper

A Godot 4 procedurally generated platformer with infinite random levels, multiple hazards, and a full set of movement mechanics.

![Title Screen](docs/game.png)

https://github.com/user-attachments/assets/docs/game.mp4

## Run

1. Open this folder in Godot 4.6.
2. Load `project.godot`.
3. Press `F5` to run.

## Controls

| Key | Action |
|---|---|
| `Left / Right` | Move |
| `Space` or `Up` | Jump (double jump, triple jump at Lv5) |
| `Z` | Dash (longer at Lv10) |
| `Down` | Crouch / drop through / portal enter |
| `Down + Space` | Drop-jump through one-way platforms |
| Hold toward wall | Wall slide / wall jump |
| `Scroll wheel` | Zoom in / out |
| `Esc` | Pause menu |
| `M` (paused) | Return to main menu |

### In-Game Shortcuts

| Key | Action |
|---|---|
| `1-4` | Jump to Easy / Medium / Hard / Extreme |
| `R` | Reroll map |
| `N / B` | Next / previous level |

## Features

- **9 procedural layout styles** -- Zigzag, Spiral, Towers, Scattered, Staircase, Islands, Climb, Maze, Sky Islands
- **Difficulty scaling** -- platforms shrink, enemies get faster, more hazards as level increases
- **Movement** -- double/triple jump, coyote time, jump buffer, wall slide, wall jump, dash with afterimage
- **Hazards** -- spikes, saw blades (linear, circular, figure-8), bullets, crumbling/disappearing/ice/conveyor platforms
- **Enemies** -- patrol (red), jumping (yellow), flying (purple), shielded (blue, 2 stomps), boss (scaled, shoots), enemy spawner
- **Items** -- coins, keys, shield power-up, speed boost, checkpoints, trampolines, portals, bonus rooms
- **Menus** -- title screen, level select with star ratings and best times, pause menu
- **Progression** -- SaveData persistence, unlockable abilities, star ratings (gold/silver/bronze)
- **Effects** -- GPUParticles2D, squash & stretch, camera shake, freeze frames, screen flash, parallax backgrounds
- **Sound** -- procedural chiptune music, full SFX set, positional audio

## Project Structure

```
scripts/
  World.gd          -- Orchestrator: state, callbacks, level switching
  Builder.gd        -- Static factory for all level elements
  Effects.gd        -- Particles, overlays, pause menu
  Player.gd         -- Player controller (movement, combat, power-ups)
  LevelData.gd      -- Procedural level generator (9 styles)
  GameState.gd      -- Autoload: level transitions, save data, unlocks
  SaveData.gd       -- Resource-based persistence (best times, stars)
  BulletPool.gd     -- Object pool for bullet reuse
  TitleScreen.gd    -- Main menu
  LevelSelect.gd    -- Level select grid
  AudioManager.gd   -- SFX pool + procedural music
  Portals.gd        -- Portal creation and teleport logic
  Minimap.gd        -- Minimap overlay
  Colors.gd         -- Color constants
  Sprites.gd        -- Kenney sprite textures and helpers
  PauseHandler.gd   -- ESC/M key handler (always processes)
  entities/          -- Self-updating entity scripts
    PatrolEnemy.gd, JumpingEnemy.gd, FlyingEnemy.gd,
    ShieldedEnemy.gd, BossEnemy.gd, EnemySpawner.gd,
    Bullet.gd, Shooter.gd, SawOrbit.gd,
    CrumblePlatform.gd, DisappearPlatform.gd,
    IcePlatform.gd, ConveyorPlatform.gd, WindZone.gd
scenes/
  TitleScreen.tscn   -- Entry scene (main menu)
  LevelSelect.tscn   -- Level select
  World.tscn         -- Game scene
assets/
  kenney_pixel/      -- Kenney Pixel Platformer sprites
  audio/             -- Sound effects
```

## Gameplay

- Every run generates a fresh random map with a unique seed
- Collect all coins (and keys on medium+) to spawn an exit portal
- Walk to the exit portal and press Down to advance
- Falling off costs 1 HP and respawns at last checkpoint
- Losing all HP resets coins, enemies, and timer
- Star ratings based on completion time (gold/silver/bronze)
- Abilities unlock as you progress (triple jump at Lv5, longer dash at Lv10)

## Requirements

- Godot 4.6 with GL Compatibility renderer
