# 3.1.1
Config menu improvements:
- [Aero](https://github.com/gashole/Aero) integration (dialog animations)
- Escape key closes the dialog
- Open/Close dialog sound effects

# 3.1.0-twow-cc2
Added "Steady Shot" alias for "Trueshot".
- Only necessary for English clients on Turtle WoW 1.17.2 servers

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
-- Steady Shot can hang a while before firing, so tune the cutoff.
/script local a, b = Quiver.GetSecondsRemainingShoot(); local c = a and b < -0.25; local f = c and CastSpellByName or Quiver.CastNoClip; f("Steady Shot")
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

# 2.7.1
Fixes bugs reported by brcz:
- Spells can partially reset auto shot timer
- Aspect of the Beast uses correct texture

# 2.7.0
### Features
Added new default mode for auto shot timer "left-to-right". You can revert to "both-directions" using a config dropdown.

### Fixes
Fixed the auto shot timer getting stuck*.

[*] The game _must _trigger__ an ITEM_LOCK_CHANGED event for Quiver to handle a shot. If that event isn't there, then it's not a Quiver bug. If you think there's a bug in the auto shot timer, enable "verbose logging" in the config menu and record it to verify the game fired events. Movement often doesn't reset the timer inside instances, and that's also a game bug.

# 2.6.3
- New optional debug logging (dropdown in config menu).
- Fixed a bug (reported by Khoni) where the auto shot timer could break by treating auto shots as casted shots.
- There's still a bug where on rare occasions auto shot doesn't trigger an event, resulting a stuck timer bar. If you can reproduce any bugs related to the auto shot timer, please turn on debug logging and send me a video recording.

# 2.6.2
Fixed ranged weapon haste calculation.

# 2.6.1
Fixes false positives on Trueshot Alarm due to Turtle WoW update.

# 2.6.0
Auto Shot Timer module also enables macros that avoid clipping auto shot:
- Aimed Shot `/qqaimedshot`
- Multi-Shot `/qqmultishot`
- Trueshot `/qqtrueshot`

Casting this way won't interrupt current cast, so move first if casting volley.

Added chat warnings when missing the corresponding action bar icons for castable shots.

# 2.5.3
- Fixed false-positive Tranquilizing Shot announcements (for real this time).
- Fixed saving frame positions when moving them following a frame reset.
- Fixed default frame positions when "Use UI Scale" disabled in video settings.

# 2.5.2
- Added dropdown for Tranq Announce channel (say, raid, none).
- Tranq progress bars now perceptually uniform brightness (the green was too bright).
- Fixed Castbar when using Kiss of the Spider trinket.

# 2.5.1
Fixed a bug where Tranquilizing Shot announced without firing (facing away, stunned, etc.). This version checks you fired a shot before announcing. You can intentionally trigger the bug by mashing Tranq while casting another spell, but that's unlikely to happen in raid.

# 2.5.0 beta
Rebuilt Tranq Announce module with UI for showing cooldowns of other hunters.

# 2.4.1
Added full color customization.
Fixed several strata hierarchy problems.

# 2.3.1
Created "Reset Frames" options for each individual module.
Fixed previous colour -> color config migration for auto shot.

# 2.3.0
New Feature - Update Notifier

# 2.2.1
New Feature - Aspect Tracker
Trueshot Aura Alarm using dynamic update frequency for aura refreshes.

# 2.1.0 beta
New feature - Trueshot Aura Alarm

Some changes to frame positioning due to UI scaling.

# 2.0.1
- Fixed version checking

# 2.0.0
- Added first pass of migration support. This allows updates without damaging saved variables.
- Renamed Auto Shot Castbar to Auto Shot Timer, and changed 'colours' to American spelling.
- Increased Trueshot cast time from the spellbook value of 1.0 to an under-estimate of 1.3. This improves the user experience for now, but isn't perfect.
