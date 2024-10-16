# 3.1.0
### Features
Implemented tooltip border style option for auto shot timer and castbar. Improved grid-snapping for these frames when dragging or resizing.

API functions:
- Quiver.FdPrepareTrap
- Quiver.GetSecondsRemainingReload
- Quiver.GetSecondsRemainingShoot
```lua
-- Spammable FD-Trap macro
-- Checks: FD CD, Trap CD, is-player-in-combat, is-pet-in-combat
-- Casts: FD, petPassive, petFollow
-- WARNING: this will pull your pet even if you're stunned etc.
/script CastSpellByName("Frost Trap"); Quiver.FdPrepareTrap()
```

Timing functions return true/false (isShooting/isReloading) and the time remaining (zero if false).
```lua
-- This macro detects when the auto shot timer bugs out by more than
-- 0.25 seconds, and switches from CastNoClip to CastSpellByName.
-- Trueshot can hang a while before firing, so tune the cutoff.
/script local a, b = Quiver.GetSecondsRemainingShoot(); local c = a and b < -0.25; local f = c and CastSpellByName or Quiver.CastNoClip; f("Trueshot")
```

### Bugfixes
1. Fixed Multi-Shot occasionally triggering a reload on the auto shot bar.
2. Adjusted shoot time from 0.65 to 0.5 seconds. This is different from other addons, but seems more accurate.

# 3.0.0
### Breaking Changes
1. Quiver now has a build step. See Readme for updated installation instructions.

2. Removed specialized /qq-macros. Instead, Quiver exposes global functions for use within user-defined macros.

CastNoClip – Cast spell by name if it won't clip a shot.
```lua
-- ex. equivalent to the old /qqtrueshot
/script Quiver.CastNoClip("Trueshot")
```

CastPetAction – Find and cast pet action if possible.
```lua
/script Quiver.CastPetAction("Furious Howl"); CastSpellByName("Multi-Shot")
```

PredMidShot – Low level predicate for no-clip behavior. Used internally to implement CastNoClip.
```lua
/script if not Quiver.PredMidShot() then DEFAULT_CHAT_FRAME:AddMessage("Reloading") end
```

### Features
Implemented localization. Translation files for zhCN locale.

### Bugfixes
Fixes several common problems with the Range Indicator or Castbar not working. You no longer need raw spell abilities on your bars for Quiver to detect them, although this might fix edge cases. Macros that use textures of important spells (ex. Multi-Shot, Hunter's Mark) and cast unrelated spells can interfere with Quiver.
