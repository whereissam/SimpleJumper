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
- [ ] Moving saw blade patterns (figure-8, circular orbit)

### Enemies
- [x] Flying enemy (purple, sine wave patrol, spawns on medium+ difficulty)
- [x] Shielded enemy (blue, 2 stomps to kill, shield flash on first hit)
- [x] Enemy spawner (pulsing magenta box, spawns patrol enemies, hard+ difficulty)

---

## 8. Architecture -- Code Quality

- [ ] Extract pause menu into standalone PauseMenu.gd script
- [ ] Convert entities to PackedScenes (.tscn) for editor editing
- [ ] Ice/conveyor/wind as Area2D with body_entered signals (remove per-frame distance checks)
- [ ] Object pool for bullets (reuse instead of instantiate/free)
- [ ] Object pool for particle effects (reuse GPUParticles2D nodes)
