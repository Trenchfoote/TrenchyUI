# TrenchyUI — TODO

<!-- Add items below. Mark done with [x] when complete. -->
<!-- Priority: !!! = urgent, !! = next, ! = backlog -->

## Bugs
- [x] !!! CDM icons flicker — fixed by leaving icons in Blizzard viewer, positioning in-place with cross-parent SetPoint, immediate relayout in RefreshLayout post-hook
- [x] ! Eltruism compat — now checks `E.db.ElvUI_EltreumUI.glow.enable` only (removed `.pixel` — any glow type conflicts)
- [x] !! TDM Apply to all not affecting TDM Window 4 — could not reproduce; code loops 2-4 correctly. Likely one-time state issue.

## Features
- [x] ! Keep Size Ratio toggle added to CDM layout — mirrors ElvUI pattern
- [x] Ironfur bar timer smoothing — removed 10fps throttle from OnUpdate ticker, now drains every frame for smooth animation.

## Iteration
- [x] ! Add /tdm command that opens directly to the tdm config
- [x] ! Update default mover positions for TDM windows 2, 3, 4 — Window 2: BOTTOMRIGHT -2, 189; Window 3: BOTTOMRIGHT -416, 2; Window 4: BOTTOMRIGHT -416, 189
