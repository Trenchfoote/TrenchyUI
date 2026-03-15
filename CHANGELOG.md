# TrenchyUI Changelog

## v0.9.9

### New Features
- UnitFrames: Added toggles for custom class bars (VDH Soul Fragments, Bear Ironfur) under the UnitFrames config section

### Bug Fixes
- Cooldown Manager: Fixed cooldown icons and buff bars not positioning correctly during combat
- Cooldown Manager: Fixed movers drifting back to previous positions after being repositioned
- Cooldown Manager: Fixed profile installer not enabling Blizzard's Cooldown Manager
- UnitFrames: Fixed pixel glow highlighting all debuffs instead of only those matched by ElvUI's aura highlight system
- UnitFrames: Fixed custom class bars not fading with the player frame
- Nameplates: Fixed interrupt marker not displaying correctly on castbars
- Nameplates: Fixed interrupt marker appearing on non-interruptible casts
- QoL: Fixed housing edit mode interactions being blocked by moveable frames
- Datatexts: Fixed Guild datatext showing garbled text instead of "No Guild" when not in a guild
- Skins: Removed widget status bar skin that was overriding colors and rendering bars white

### Improvements
- Nameplates: Improved performance in large pulls by consolidating interrupt marker processing
- Nameplates: Friendly nameplate realm names are now hidden
- Nameplates: Re-enabled classification-based nameplate coloring in instances
- Profiles: Updated TrenchyUI profile with new mover positions and datatext labels
