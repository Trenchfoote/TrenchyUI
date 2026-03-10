# TrenchyUI Changelog

## v0.8

### Bug Fixes
- Cooldown Manager: Fixed error on fresh installs caused by stale frame anchors from previous versions

### New Features
- Nameplates: Added quest NPC color override — highlights quest mob health bars with a custom color (open world only, disabled in instances)

### Improvements
- Profiles: Disabled smooth bar animations across all unit frames and nameplates
- Profiles: Removed action bar visibility overrides — bars now use ElvUI defaults
- Profiles: Adjusted player castbar position
- Profiles: Added resolution warning to the Profiles config tab (designed for 1440p)
- QoL: Minimap button bar now automatically hides during pet battles
- QoL: Internal code cleanup and performance improvements
- General: New features now highlighted in ElvUI's "What's New" search

## v0.7.1
- Changelogs now display properly on CurseForge and Wago

## v0.7

### Bug Fixes
- Damage Meter: Fixed first bar having extra spacing at the top of the window
- Profiles: Fixed private profile settings not persisting correctly

### New Features
- Compatibility Checker: Now detects conflicts between TrenchyUI glow and Eltruism glow settings
- Compatibility Checker: Improved detection of competing addons
- Compatibility Checker: Added detection for cooldown manager vs ArcUI, AyijeCDM, BCDM, CDMCentered
- Damage Meter: Added foreground and background bar texture selectors
- Damage Meter: Header now has a mouseover fade option
- Cooldown Manager: Settings and preview now automatically show/hide when navigating to/from the config tab
- QoL: New toggle — Hide Objectives in Combat, automatically hides the objective tracker when entering combat

### Improvements
- Damage Meter: Header color picker renamed from "Background" to "Backdrop Color" for clarity
- Cooldown Manager: Config now opens instantly (removed startup delay)
- General: Code cleanup and performance improvements

## v0.6

### Bug Fixes
- Damage Meter: Fixed embedded header not appearing on fresh profiles
- Damage Meter: Fixed embed accidentally hiding the right chat window
- Profiles: Fixed installation failing on fresh game data
- Profiles: Fixed private profile being overwritten during installation

### New Features
- Cooldown Manager: Profile defaults updated for all viewers (icon sizing and spacing)

### Improvements
- General: Internal code audit updated

## v0.5

### Bug Fixes
- Cooldown Manager: Fixed icons flickering during combat
- Compatibility Checker: Fixed Eltruism detection to catch all glow type conflicts
- Damage Meter: Investigated "Apply to all" not affecting Window 4 (could not reproduce)

### New Features
- Cooldown Manager: Added Keep Size Ratio toggle
- Damage Meter: /tdm command now opens directly to config
- Damage Meter: Updated default positions for windows 2-4

### Improvements
- Damage Meter: Ironfur bar timer animation is now smooth
- General: Code cleanup
