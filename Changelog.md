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
