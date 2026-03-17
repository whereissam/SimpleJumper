# SimpleJumper -- Asset Integration TODO

## 1. Art -- Kenney's Pixel Platformer Sprites

### Download
- [x] Download Kenney Pixel Platformer from https://kenney.nl/assets/pixel-platformer
- [x] Extract into `assets/kenney_pixel/` folder

### Player
- [x] Replace player ColorRect body with AnimatedSprite2D
- [x] Add idle, run, jump, fall animation frames (left + right)
- [x] Remove eye/pupil/mouth ColorRects (sprites handle face)
- [ ] Add wall-slide animation frame
- [ ] Add dash animation (stretch or ghost trail with sprite)
- [ ] Add death animation (spin + fade)

### Platforms
- [x] Replace ColorRect platforms with tiled Kenney grass sprites (left/mid/right edges)
- [ ] Different tile styles per background theme (grass, cave, sky, etc.)
- [x] Moving platforms: use Kenney wood plank sprite (purple tinted)
- [x] Crumbling platforms: use Kenney crate sprite
- [ ] Disappearing platforms: replace ColorRect with sprite (kept ColorRect for blink effect)

### Enemies
- [x] Replace enemy ColorRect with AnimatedSprite2D (red character walk cycle)
- [x] Enemy animation flips direction based on patrol direction
- [ ] Shooter enemy: use turret sprite (kept ColorRect)
- [ ] Bullet: use small projectile sprite (kept Polygon2D)
- [ ] Death particles: use Kenney particle sprites instead of ColorRect squares

### Coins
- [x] Replace Polygon2D coin with Kenney coin Sprite2D
- [ ] Collect effect: use Kenney sparkle sprites (kept ColorRect particles)

### Hazards
- [x] Spikes: use Kenney spike tile sprite
- [x] Saw blades: use Kenney circular saw sprite with rotation
- [ ] Trampoline: use spring sprite with squash animation (kept ColorRect)

### Portals
- [ ] Use Kenney door/portal sprites or keep procedural effect with sprite overlay
- [ ] Exit portal: add glowing animated sprite

### Checkpoints
- [x] Flag pole: use Kenney wooden post sprite
- [ ] Replace flag triangle Polygon2D with flag sprite (two frames: inactive/active)

### Power-ups
- [x] Shield: use Kenney heart sprite
- [x] Speed boost: use Kenney diamond sprite

### Background
- [x] Add Kenney cloud/mountain background tiles as decoration layer
- [ ] Add 2-3 parallax layers for depth (far mountains, mid trees, near bushes)
- [x] Stars: kept procedural

### HUD
- [ ] Coin icon next to score
- [ ] Heart sprites instead of text hearts
- [ ] Shield icon instead of text

### Infrastructure
- [x] Created `Sprites.gd` -- centralized sprite path mapping and helper functions
- [x] `make_player_animated()` -- builds SpriteFrames with all player animations
- [x] `make_enemy_animated()` -- builds SpriteFrames with enemy walk cycle
- [x] `TEXTURE_FILTER_NEAREST` set on all sprites for crisp pixel art
- [x] Sprites scaled 3x (tiles) and 2.5x (characters) for 1280x720 viewport

---

## 2. Camera -- ProCam2D or Manual Improvements

### Screen Shake
- [ ] Add camera shake on player damage (intensity: 4px, duration: 0.2s)
- [ ] Add camera shake on enemy stomp (intensity: 2px, duration: 0.1s)
- [ ] Add camera shake on landing from high fall (intensity: 3px, duration: 0.15s)

### Smooth Camera
- [ ] Add look-ahead: camera leads in the direction player is moving
- [ ] Add vertical dead zone: camera doesn't jitter on small jumps
- [ ] Smooth zoom transitions when entering different areas

### Screen Effects
- [ ] Hit flash: brief white overlay (0.05s) when taking damage
- [ ] Freeze frame: 0.05s pause on enemy stomp for impact feel
- [ ] Screen fade on level transition (fade to black, load, fade in)

---

## 3. Sound Effects

### Download
- [ ] Download from https://kenney.nl/assets (search "audio", "interface sounds", "impact sounds")
- [ ] Place audio files in `assets/audio/` folder

### Player Sounds
- [ ] Jump (short "boing" or whoosh)
- [ ] Double jump (higher pitch variant)
- [ ] Land (soft thud)
- [ ] Dash (whoosh)
- [ ] Wall slide (scraping loop)
- [ ] Take damage (hit sound)
- [ ] Death (deeper impact + sad tone)
- [ ] Respawn (chime)

### World Sounds
- [ ] Coin collect (classic ding/chime)
- [ ] Power-up pickup (rising sparkle)
- [ ] Shield break (glass shatter)
- [ ] Checkpoint activate (flag whoosh + chime)
- [ ] Portal enter (warp/teleport sound)
- [ ] Trampoline bounce (spring boing)

### Enemy Sounds
- [ ] Enemy stomp (squish)
- [ ] Shooter fire (pew/laser)
- [ ] Bullet hit (small impact)

### Hazard Sounds
- [ ] Spike hit (sharp sting)
- [ ] Saw blade (ambient buzz loop when nearby)
- [ ] Crumble platform (rumble then crack)
- [ ] Disappear platform (phase out hum)

### Music
- [ ] Background music loop (chiptune or ambient, per difficulty tier)
- [ ] Level complete jingle
- [ ] Death jingle (short)

### Implementation
- [ ] Create AudioManager autoload singleton
- [ ] Preload all sounds at startup
- [ ] Use AudioStreamPlayer for music (one global)
- [ ] Use AudioStreamPlayer2D for positional sounds (enemies, hazards)
- [ ] Volume sliders in pause menu (stretch goal)

---

## 4. Game Feel ("Juice")

### Squash & Stretch
- [ ] Player squashes on land, stretches on jump
- [ ] Trampoline pad squashes on bounce
- [ ] Enemies squash when stomped

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

## Priority Order (updated)

1. ~~**Kenney sprites**~~ DONE (core sprites integrated)
2. **Sound effects** (biggest remaining impact)
3. **Camera shake + freeze frame** (cheap wins)
4. **Remaining sprite polish** (shooter, bullet, trampoline, portal, HUD icons)
5. **Parallax background** (depth)
6. **Squash & stretch** (polish)
7. **GPUParticles2D** (replace ColorRect particles)
8. **Music** (atmosphere)
9. **Screen effects** (final polish)
