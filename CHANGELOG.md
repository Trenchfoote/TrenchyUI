# TrenchyUI Changelog

## v0.9.7

### Bug Fixes
- Minimap Buttons: Fixed growth direction not working — buttons now correctly expand in the configured direction (e.g. "Up, then Left")
- Cooldown Manager: Fixed viewer growth direction — viewers now grow from the top or bottom of the anchor instead of from center
- Nameplates: Fixed interrupt marker position on reverse-fill castbars

### New Features
- Cooldown Manager: Buff Bar viewer with customizable bar width, height, textures, icon toggle, spark, and full text styling for name, duration, and stacks
- Cooldown Manager: Per-spell bar color overrides — right-click a buff bar to set custom foreground and background colors
- Cooldown Manager: Mirrored columns layout for buff bars — splits bars into two side-by-side columns
- Cooldown Manager: Per-spell glow settings for buff icons — right-click a buff icon to customize glow type, color, and animation
- Cooldown Manager: "Player Fader" visibility mode — mirrors the player unitframe's fader alpha
- Skins: Blizzard Cooldown Manager alert editor panel now inherits ElvUI skin

### Improvements
- Cooldown Manager: "Hide When Inactive" option now available for the Buff Bar viewer
- Config: Reorganized Click Casting button placement and styling
- General: Multiple fixes for code alignment
