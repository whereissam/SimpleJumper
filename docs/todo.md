# SimpleJumper -- Asset Integration TODO

## 1. Art -- Kenney's Pixel Platformer Sprites

### Download
- [x] Download Kenney Pixel Platformer from https://kenney.nl/assets/pixel-platformer
- [x] Extract into `assets/kenney_pixel/` folder

### Player
- [x] Replace player ColorRect body with AnimatedSprite2D
- [x] Add idle, run, jump, fall animation frames (left + right)
- [x] Remove eye/pupil/mouth ColorRects (sprites handle face)
- [x] Squash & stretch on land/jump
- [ ] Add wall-slide animation frame
- [ ] Add dash animation (stretch or ghost trail with sprite)
- [ ] Add death animation (spin + fade)

### Platforms
- [x] Replace ColorRect platforms with tiled Kenney grass sprites (left/mid/right edges)
- [x] Sprite scale matches collision shape exactly (no invisible blocking)
- [x] One-way platforms (jump through from below, drop through with Down)
- [x] Moving platforms: use Kenney wood plank sprite (purple tinted)
- [x] Crumbling platforms: use Kenney crate sprite
- [ ] Different tile styles per background theme (grass, cave, sky, etc.)
- [ ] Disappearing platforms: replace ColorRect with sprite

### Enemies
- [x] Replace enemy ColorRect with AnimatedSprite2D (red character walk cycle)
- [x] Enemy animation flips direction based on patrol direction
- [x] Enemy squash animation on stomp death
- [ ] Shooter enemy: use turret sprite (kept ColorRect)
- [ ] Bullet: use small projectile sprite (kept Polygon2D)

### Coins
- [x] Replace Polygon2D coin with Kenney coin Sprite2D
- [x] Increased pickup radius (24px)
- [ ] Collect effect: use Kenney sparkle sprites (kept ColorRect particles)

### Hazards
- [x] Spikes: use Kenney spike tile sprite
- [x] Saw blades: use Kenney circular saw sprite with rotation
- [ ] Trampoline: use spring sprite with squash animation (kept ColorRect)

### Portals
- [ ] Use Kenney door/portal sprites or keep procedural effect
- [ ] Exit portal: add glowing animated sprite

### Checkpoints
- [x] Flag pole: use Kenney wooden post sprite
- [ ] Replace flag triangle Polygon2D with flag sprite

### Power-ups
- [x] Shield: use Kenney heart sprite
- [x] Speed boost: use Kenney diamond sprite

### Background
- [x] Add Kenney cloud/mountain background tiles as decoration layer
- [x] Stars: kept procedural
- [ ] Add 2-3 parallax layers for depth

### HUD
- [ ] Coin icon next to score
- [ ] Heart sprites instead of text hearts
- [ ] Shield icon instead of text

### Infrastructure
- [x] Created `Sprites.gd` -- centralized sprite path mapping and helper functions
- [x] `make_player_animated()` -- builds SpriteFrames with all player animations
- [x] `make_enemy_animated()` -- builds SpriteFrames with enemy walk cycle
- [x] `TEXTURE_FILTER_NEAREST` set on all sprites for crisp pixel art
- [x] Sprite scale matches collision (platform_height / 18px)

---

## 2. Camera -- ProCam2D or Manual Improvements

### Screen Shake
- [x] Add camera shake on player damage (intensity: 5px, duration: 0.2s)
- [x] Add camera shake on enemy stomp (intensity: 3px, duration: 0.1s)
- [ ] Add camera shake on landing from high fall

### Smooth Camera
- [x] Add look-ahead: camera leads 60px in the direction player is moving
- [x] Slight upward offset (-15px) for better visibility below
- [ ] Smooth zoom transitions when entering different areas

### Screen Effects
- [ ] Hit flash: brief white overlay (0.05s) when taking damage
- [x] Freeze frame: 0.05s pause on enemy stomp for impact feel
- [ ] Screen fade on level transition (fade to black, load, fade in)

---

## 3. Sound Effects

### Download
- [x] Download Kenney digital-audio, impact-sounds, interface-sounds
- [x] Place audio files in `assets/audio/` folder

### Player Sounds
- [x] Jump (phaseJump1)
- [x] Double jump (phaseJump3, higher pitch)
- [x] Land (footstep_concrete, on hard landing)
- [x] Dash (phaserUp2)
- [ ] Wall slide (scraping loop)
- [x] Take damage (impactPunch_heavy)
- [x] Death (lowDown)
- [ ] Respawn (chime)

### World Sounds
- [x] Coin collect (confirmation_002, random pitch)
- [x] Power-up pickup (powerUp2)
- [x] Shield break (glass_004)
- [x] Checkpoint activate (maximize_006)
- [x] Portal enter (phaserDown2)
- [x] Trampoline bounce (pepSound3)

### Enemy Sounds
- [x] Enemy stomp (impactSoft_heavy)
- [x] Shooter fire (laser3)
- [x] Bullet hit (impactGeneric_light)

### Hazard Sounds
- [ ] Spike hit (needs separate sound from generic hit)
- [ ] Saw blade (ambient buzz loop when nearby)
- [x] Crumble platform (impactPlank_medium)
- [ ] Disappear platform (phase out hum)

### Music
- [ ] Background music loop (chiptune or ambient, per difficulty tier)
- [x] Level complete jingle (threeTone1)
- [ ] Death jingle (short)

### Implementation
- [x] Create AudioManager autoload singleton
- [x] Preload all sounds at startup (with graceful fallback)
- [x] AudioStreamPlayer pool (12 simultaneous sounds)
- [ ] Use AudioStreamPlayer2D for positional sounds
- [ ] Volume sliders in pause menu (stretch goal)

---

## 4. Game Feel ("Juice")

### Squash & Stretch
- [x] Player squashes on land (proportional to fall speed)
- [x] Player stretches on jump
- [x] Enemies squash flat when stomped (then burst into particles)
- [ ] Trampoline pad squashes on bounce

### Particles (upgrade from ColorRect to GPUParticles2D)
- [ ] Jump dust cloud
- [ ] Dash trail
- [ ] Coin collect sparkle burst
- [ ] Enemy death poof
- [ ] Landing impact ring
- [ ] Speed boost trail behind player

### Screen Effects
- [ ] Vignette on low HP
- [ ] Speed lines during dash
- [ ] Subtle chromatic aberration on damage

---

## 5. Gameplay Features (added)

- [x] Drop-through platforms (press Down on one-way platforms)
- [x] Vertical Climb layout style (zigzag upward to goal)
- [x] 7 layout styles total (Zigzag, Spiral, Towers, Scattered, Staircase, Islands, Climb)
- [x] Steeper difficulty curve (more enemies, faster, more hazards)
- [ ] Moving enemies (not just patrol -- jumping enemies, flying enemies)
- [ ] Boss enemy at end of hard levels
- [ ] Conveyor belt platforms
- [ ] Ice platforms (slippery)
- [ ] Wind zones (push player sideways)
- [ ] Collectible keys to unlock exit

---

## Priority Order (updated)

1. ~~**Kenney sprites**~~ DONE
2. ~~**Sound effects**~~ DONE (core sounds wired)
3. ~~**Camera shake + freeze frame**~~ DONE
4. ~~**Squash & stretch**~~ DONE
5. **Hit flash + screen fade** (quick wins)
6. **Remaining sprite polish** (shooter, bullet, trampoline, portal, HUD icons)
7. **Parallax background** (depth)
8. **GPUParticles2D** (replace ColorRect particles)
9. **Music** (atmosphere)
10. **Advanced gameplay** (moving enemies, boss, conveyor, ice, wind)
