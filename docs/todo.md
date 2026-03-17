# SimpleJumper -- Asset Integration TODO

## 1. Art -- Kenney's Pixel Platformer Sprites

### Download
- [x] Download Kenney Pixel Platformer
- [x] Extract into `assets/kenney_pixel/`

### Player
- [x] AnimatedSprite2D with idle/run/jump/fall (left + right)
- [x] Squash & stretch on land/jump
- [x] Crouch visual (squash sprite)
- [ ] Wall-slide animation frame
- [ ] Death animation (spin + fade)

### Platforms
- [x] Kenney grass tiles (left/mid/right edges), scale matches collision
- [x] One-way platforms, drop-through with Down
- [x] Moving: wood plank sprite, Crumbling: crate sprite
- [x] Ice platforms (blue tint), Conveyor belts (orange + arrows)
- [ ] Disappearing: replace ColorRect with sprite

### Enemies
- [x] AnimatedSprite2D red character walk cycle + direction flip
- [x] Squash death animation
- [ ] Shooter: turret sprite, Bullet: projectile sprite

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
- [ ] Coin icon next to score
- [ ] Heart sprites instead of text
- [ ] Shield icon instead of text

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
- [ ] Wall slide sound (scraping loop)
- [ ] Death jingle
- [ ] Background music loop
- [ ] Positional audio (AudioStreamPlayer2D)

---

## 4. Game Feel ("Juice")

- [x] Player squash on land, stretch on jump
- [x] Enemy squash on stomp
- [x] Vignette on low HP
- [x] Speed lines during dash
- [ ] Trampoline pad squash on bounce
- [ ] GPUParticles2D for jump dust, coin sparkle, enemy poof
- [ ] Landing impact ring

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

**DONE:** Sprites, sounds, camera effects, screen effects, parallax, pause menu, crouch, ice, conveyor, 7 map styles, difficulty scaling

**REMAINING (nice-to-have):**
- HUD sprite icons
- Disappearing platform sprite
- Shooter/bullet sprites
- GPUParticles2D
- Background music
- Wall slide sound
- Death jingle
- Advanced enemies (jumping, flying, boss)
- Wind zones
- Collectible keys
