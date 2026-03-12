# TrenchyUI Changelog

## v0.9.4

### New Features
- Datatexts: New custom datatexts inspired by the Shadow and Light ElvUI Plugin. Go check it out!
  - New custom Guild datatext with interactive tooltip — shows online members with class colors, level, zone, and click-to-whisper/invite
  - New custom Friends datatext with interactive tooltip — shows character friends and Battle.net friends grouped by game client, with click-to-whisper/invite
  - Custom font options (font, size, outline) for Guild and Friends tooltip text, configurable per-datatext in the Customization tab
- QoL: New cursor circle overlay — a ring follows your cursor to help you find it. Configurable size, thickness, color, and class color option
- Cooldown Manager: New "Hide When Inactive" toggle for the Buff Icon viewer — Mirrors Blizzard CDM behavior, hides the icons unleess the buff is present.

### Bug Fixes
- Nameplates: Fixed interrupt marker snapping to the edge of the castbar and persisting on non-targeted nameplates after a successful interrupt
- Nameplates: Fixed nameplate colors staying stuck on threat color after abruptly dropping combat (e.g. Shadowmeld, Feign Death)
- Nameplates: Fixed a crash that could occur when castbar state was stale after a failed cast
- Cooldown Manager: Fixed ArcUI not being detected by the compatibility checker — the conflict popup now correctly appears when both addons are installed

### Improvements
- Cooldown Manager: Right-clicking a mover now opens config directly to that viewer's settings
