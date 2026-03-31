# SimpleJumper -- Asset Integration TODO

## 1. Art -- Kenney's Pixel Platformer Sprites

### Download
- [x] Download Kenney Pixel Platformer
- [x] Extract into `assets/kenney_pixel/`

### Player
- [x] AnimatedSprite2D with idle/run/jump/fall (left + right)
- [x] Squash & stretch on land/jump
- [x] Crouch visual (squash sprite)
- [x] Wall-slide animation (fall frame + tilt toward wall)
- [x] Death animation (pop up, spin 2x, shrink, fade, then respawn)

### Platforms
- [x] Kenney grass tiles (left/mid/right edges), scale matches collision
- [x] One-way platforms, drop-through with Down
- [x] Moving: wood plank sprite, Crumbling: crate sprite
- [x] Ice platforms (blue tint), Conveyor belts (orange + arrows)
- [x] Disappearing: tiled grass sprites with cyan tint, fade on/off

### Enemies
- [x] AnimatedSprite2D red character walk cycle + direction flip
- [x] Squash death animation
- [x] Shooter: Kenney enemy sprite + barrel, Bullet: red diamond sprite

### Items & Hazards
- [x] Coins: Kenney coin sprite (24px pickup radius)
- [x] Spikes: spike sprite, Saws: saw sprite
- [x] Power-ups: heart (shield), diamond (speed)
- [x] Checkpoints: wooden post sprite

### Background
- [x] Kenney cloud/mountain tiles as decoration
- [x] Parallax layers (far mountains 0.15x, mid clouds 0.3x)
- [x] Stars on fixed layer

### HUD
- [x] Coin icon next to score
- [x] Heart sprites for HP (modulate dim when lost)
- [x] Shield icon (cyan tinted heart, shown/hidden with shield state)

---

## 2. Camera & Screen Effects

- [x] Camera shake on damage (5px) and stomp (3px)
- [x] Camera look-ahead (60px in facing direction)
- [x] Freeze frame on enemy stomp (0.05s)
- [x] Hit flash (white flash on damage)
- [x] Screen fade (fade to black on level switch, fade in on start)
- [x] Vignette pulse on low HP (1 HP = red overlay pulse)
- [x] Speed lines during dash

---

## 3. Sound Effects

- [x] AudioManager autoload with 12-player pool
- [x] Jump, double jump, dash, land sounds
- [x] Coin, power-up, shield break, checkpoint, portal, trampoline
- [x] Enemy stomp, shooter fire, bullet hit, crumble
- [x] Level complete jingle
- [x] Wall slide sound (looping scrape, starts/stops with wall slide state)
- [x] Death jingle (phaserDown3)
- [x] Background music (procedural chiptune square wave, 16-note melody)
- [x] Positional audio (AudioStreamPlayer2D on saw blades, 300px range)

---

## 4. Game Feel ("Juice")

- [x] Player squash on land, stretch on jump
- [x] Enemy squash on stomp
- [x] Vignette on low HP
- [x] Speed lines during dash
- [x] Trampoline squash & spring animation on bounce
- [x] GPUParticles2D for coin sparkle, enemy poof, crumble (reusable _spawn_burst)
- [x] Landing impact ring (expanding oval at feet on hard landing)

---

## 5. Gameplay Features

- [x] Drop-through platforms
- [x] Crouch (hold Down, half hitbox, slower movement)
- [x] Ice platforms (slippery)
- [x] Conveyor belts (push player)
- [x] Vertical Climb layout (7 styles total)
- [x] Pause menu (Escape, shows all controls)
- [x] Safe zones (no enemies near portals/spawn)
- [x] Post-teleport invincibility
- [x] Steeper difficulty curve
- [x] Jumping enemies (yellow, bounce on timer, medium+ difficulty)
- [x] Boss enemy (large, HP bar, shoots bullets, hard+ difficulty)
- [x] Wind zones (push player sideways, visual arrows)
- [x] Collectible keys to unlock exit (diamond icons, required on medium+)

---

## Done / Remaining

**DONE:** All core features complete -- sprites, sounds, camera effects, screen effects, parallax, pause menu, crouch, ice, conveyor, 7 map styles, difficulty scaling, HUD icons, disappearing platforms, shooter/bullet sprites, GPUParticles2D, background music, wall slide sound, death jingle, jumping/boss enemies, wind zones, collectible keys, GameState autoload, SaveData persistence, self-updating entities.

---

## 6. Polish -- Visual & Game Feel

### Sprites
- [x] Trampoline sprite (Kenney spring tile_0064, orange tinted)
- [x] Key sprite (Kenney key tile_0152, gold tinted)
- [x] Wind zone visual (GPUParticles2D streamlines flowing in wind direction)

### Particles & Effects
- [x] Screen shake on boss death (8px shake, 0.3s)
- [x] Particle trails on floating keys (gold GPUParticles2D sparkle)
- [x] Particle trails on floating power-ups (cyan for shield, orange for speed)
- [x] Dash afterimage (semi-transparent sprite copies trailing behind during dash)
- [x] Boss death explosion (32-particle red burst + white burst + screen flash)
- [x] Portal swirl particles (GPUParticles2D ring emission replacing static dots)

### Animation
- [x] Coin spin animation (horizontal scale oscillation)
- [x] Checkpoint flag wave (skew oscillation after activation)
- [x] Conveyor belt arrow scroll (arrows scroll in push direction with fade loop)

---

## 7. Gameplay -- New Features

### Menus & UI
- [x] Title screen / main menu (Play, Level Select, Quit)
- [x] Level select screen (grid with unlock status, best times, page navigation)
- [x] Death stats overlay (deaths, coins, time shown briefly on death)
- [x] Best time display on HUD (green label below timer)
- [x] Back to menu (M key during pause)

### Progression
- [x] Score persistence across levels (session_coins in GameState, saved on complete)
- [x] Unlockable abilities (triple jump at Lv5, longer dash at Lv10)
- [x] Star rating per level (gold/silver/bronze, shown on complete + level select)

### Level Design
- [x] New layout style: Maze (walled corridors with intersections, 9 styles total)
- [x] New layout style: Sky Islands (large gaps, small satellite platforms)
- [x] Bonus rooms (hidden green portal to off-screen coin area, 30% on medium+)
- [x] Moving saw blade patterns (circle + figure-8 orbit via SawOrbit.gd)

### Enemies
- [x] Flying enemy (purple, sine wave patrol, spawns on medium+ difficulty)
- [x] Shielded enemy (blue, 2 stomps to kill, shield flash on first hit)
- [x] Enemy spawner (pulsing magenta box, spawns patrol enemies, hard+ difficulty)

---

## 8. Architecture -- Code Quality

- [x] Extract pause menu into Effects.gd (World.gd just toggles)
- [ ] Convert entities to PackedScenes (.tscn) for editor editing
- [x] Ice/conveyor/wind as Area2D with body_entered signals (self-managing, no World loops)
- [x] Object pool for bullets (BulletPool.gd, 20 pre-allocated, reuse instead of instantiate/free)
- [x] Object pool for particle effects (ParticlePool.gd, 24 pre-allocated, reuse instead of instantiate/free)

---

## 9. Camera & Cinematics (CameraFX.gd)

- [x] Smooth camera transition on level start (zoom from 0.55x overview to 1.0x player)
- [x] Camera zoom-out on level complete (zoom to 0.6x to reveal full map)
- [x] Camera track boss (dynamic zoom-out based on player-boss distance, 0.55x-1.0x)
- [x] Cinematic pan to exit portal when spawned (camera detours to portal, then snaps back)
- [x] Death camera (0.4x slow-mo + 1.3x zoom-in, then restore)
- [x] Camera bounds (computed from platform_data/wall_data, dynamic per level)

---

## 10. Gameplay -- Next Features

### Combat & Scoring
- [x] Combo system (chain stomps/coins within 2s window, up to 3x multiplier, HUD pop label)
- [x] Unlockable player skins with different stats (6 skins: default, speedster, tank, floaty, golden, shadow)
- [x] Shop (buy/equip skins with coins earned from level completions)

### Level Variety
- [x] Water/swim sections (WaterZone.gd: drag, buoyancy, swim-up with jump, oxygen timer)
- [x] Gravity flip zones (GravityZone.gd: reversed gravity while inside purple zone)
- [x] Destructible blocks (DestructibleBlock.gd: dash through to shatter, crumble FX)
- [x] Mini-boss variants (3 types: normal patrol, charger with dash, jumper with leap)
- [x] Moving platform paths (circle path added alongside x/y, uses CirclePlatform.gd)

### Modes
- [x] Timed challenge mode (Daily Challenge uses deterministic date seed, shared level)
- [x] Daily seed (GameState.daily_seed() from year/month/day, accessible from title menu)
- [x] Endless mode (auto-advance on coin collection, no exit portal needed)

---

## 11. 2.5D / 3D Transition (Post Lv10)

- [x] 2.5D renderer: Renderer25D.gd overlays 3D meshes on 2D physics, toggle with V key

---

## 12. Advanced Movement & Interactivity

- [x] Grappling hook (C key, aim with mouse, pull toward target within 350px range)
- [x] Glider/parachute (hold Jump while falling to float at 60px/s)
- [x] Wall climb (hold Up while wall sliding to climb upward)
- [x] Ground pound (X key in air, slam down at 800px/s, damages nearby enemies on landing)
- [x] Dash-kill (dash through enemies to kill them, works on all enemy types)
- [x] 3D camera angle (orbiting camera around hub room, 50 FOV perspective)
- [x] 3D reward hub room (HubRoom3D.gd, shown every 5 levels after Lv10, pillars/gems/stars)
- [x] 3D models for player (low-poly box body + head with skin tint, idle bob + rotation)
- [x] Depth-of-field and lighting effects (far DOF blur, glow, directional + 3 point lights, ACES tonemap)
