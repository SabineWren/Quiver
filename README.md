> [!IMPORTANT]
> $${\color{red}\* \color{orange}\* \color{yellow}\*}$$ **[Installation Methods](#installation)** $${\color{yellow}\* \color{orange}\* \color{red}\*}$$

## Features
- [Aspect Tracker](#aspect-tracker)
- [Auto Shot Timer](#auto-shot-timer)
- [Castbar](#castbar)
- [Lua Functions](#lua-functions)
- [Range Indicator](#range-indicator)
- [Tranq Shot Announcer](#tranq-shot-announcer)
- [Trueshot Aura Alarm](#trueshot-aura-alarm)

<img src="/Media/Config_UI_0f9e20.jpg" height="400px">

Use `/Quiver` or `/qq` to open the configuration menu.

### Aspect Tracker
Never lose track of your current aspect
<table>
   <tr>
      <td>None</td>
      <td>Pack</td>
      <td>Cheetah</td>
   </tr>
   <tr>
      <td><img src="/Media/Aspect_None.png" height="64px"></td>
      <td><img src="/Media/Aspect_Pack.png" height="64px"></td>
      <td><img src="/Media/Aspect_Cheetah.jpg" height="64px"></td>
   </tr>
</table>

- No UI while in Aspect of the Hawk
- Displays Hawk texture when no aspect enabled
- Shows border while Pack active (potentially other hunters)

### Auto Shot Timer
<figure>
   <figcaption>Shooting</figcaption>
   <img src="/Media/Bar_1_Shooting.jpg" height="180px">
</figure>
<figure>
   <figcaption>Reloading</figcaption>
   <img src="/Media/Bar_2_Reloading.jpg" height="180px">
</figure>

Inspired by:
- [HSK](https://github.com/anstellaire/HunterSwissKnife) -- Ignores instant spells such as Arcane Shot
- [YaHT](https://github.com/Aviana/YaHT/tree/1.12.1) -- Resets swing timer while casting a shot

### Castbar
<img src="/Media/Bar_3_Casting.jpg" height="180px">

- Shows Aimed Shot, Multi-Shot, and Steady Shot

### Lua Functions
#### CastNoClip
Cast spell by name if it won't clip a shot. Requires the Auto Shot module enabled in the config menu.
```lua
/script Quiver.CastNoClip("Steady Shot")
```

#### CastPetAction
Find and cast pet action if possible.
```lua
/script Quiver.CastPetAction("Furious Howl"); CastSpellByName("Multi-Shot")
```

#### FdPrepareTrap
- Spammable FD-Trap macro
- Checks: FD CD, Trap CD, is-player-in-combat, is-pet-in-combat
- Casts: FD, petPassive, petFollow

```lua
/script CastSpellByName("Frost Trap"); Quiver.FdPrepareTrap()
```
> [!WARNING]
> this will pull your pet even if you're stunned etc.

#### GetSecondsRemainingReload
#### GetSecondsRemainingShoot
Timing functions return true/false (isShooting/isReloading) and the time remaining (zero if false).
```lua
-- This macro detects when the auto shot timer bugs out by more than
-- 0.25 seconds, and switches from CastNoClip to CastSpellByName.
-- Steady Shot can hang a while before firing, so tune the cutoff.
/script local a, b = Quiver.GetSecondsRemainingShoot(); local c = a and b < -0.25; local f = c and CastSpellByName or Quiver.CastNoClip; f("Steady Shot")
```

#### PredMidShot – Low level predicate for no-clip behavior. Used internally to implement CastNoClip.
```lua
/script if not Quiver.PredMidShot() then DEFAULT_CHAT_FRAME:AddMessage("Reloading") end
```

### Range Indicator
[<img src="/Media/Range_Indicator_Thumbnail.jpg" height="180px">](https://raw.githubusercontent.com/SabineWren/Quiver/main/Media/Range_Indicator_Preview.mp4)

- Based on [Egnar](https://github.com/Medeah/Egnar)
- Automatically locates action bar slots
- Warns you when abilities missing from action bar

Requires corresponding spellbook abilities on your action bars. Hidden action bars work fine, but macros are [ignored](https://github.com/SabineWren/Quiver/issues/21).

### Tranq Shot Announcer
<img src="/Media/Tranq_UI.png">

Shows the Tranquilizing Shot cooldown of every hunter. Announces when casting Tranq, and again if the shot misses.

### Trueshot Aura Alarm
<table>
   <tr>
      <td>None</td>
      <td>Expiring</td>
   </tr>
   <tr>
      <td><img src="/Media/Trueshot_None.png" height="64px"></td>
      <td><img src="/Media/Trueshot_Low.png" height="64px"></td>
   </tr>
</table>

This checks if you have Trueshot Aura talented. If so, Quiver tracks the buff and duration, and warns you to recast it.

## Installation
### Option 1 - Pre-bundled release zip
Simplest installation, but doesn't automate version updates.
1. [Download](https://github.com/SabineWren/Quiver/releases) latest version
2. Extract the Zip file
3. Change the folder name from `Quiver-x.x.x` to `Quiver`
4. Move folder into `<WoW install>/Interface/AddOns/`
5. Restart WoW

> [!Tip]
> Release zip filenames ends with a version `-x.x.x` and contain the file `Quiver.bundle.lua`.

### Option 2 - Clone latest release
Requires Git. Easy to update with addon managers or `git pull --rebase`
1. Open a terminal in your addons directory
2. `git clone https://github.com/SabineWren/Quiver --branch latest-release`
3. Restart WoW
> [!Tip]
> If you download Quiver through an addon manager, it may default to source code. Change the branch to `latest-release`.
>
> Addon managers do not warn you about breaking changes. See the [changelog](https://github.com/SabineWren/Quiver/blob/main/Changelog.md) or [release notes](https://github.com/SabineWren/Quiver/releases) after updating.

### Option 3 - Build from source
Do you live on the bleeding edge?
1. Open a terminal in your addons directory
2. `git clone https://github.com/SabineWren/Quiver`
3. `npm install`
4. `npm run bundle-once`
5. Restart WoW

## Contributing
### Localization
Quiver is fully localized. If you want to contribute a new locale, see zhCN for reference in `/Locale/`:
1. `<locale>.client.lua` for values that exactly correspond to the client, ex. "Multi-Shot". Should be identical values to what other addons use.
2. `<locale>.translations.lua` for Quiver-specific text that requires translation.

### Dependencies
Type definitions are gitignored, so [clone](https://github.com/SabineWren/wow-api-type-definitions) them separately.

See `package.json` for everything else.

### Custom Events
Files in `/Events` hook into game functions. Use these events if possible instead of declaring your own hooks.
- Spellcast: CastSpell, CastSpellByName, UseAction

### Module Lifecycle
Features are packaged and enabled as 'modules' that implement lifecycle hooks. See the type definitions for details.

### Missing Functionality
- Layout engine [1](https://github.com/wolf81/composer) [2](https://www.youtube.com/watch?v=DYWTw19_8r4)
- Full type safety
- FD macro LoseControl integration (state not exposed, and no license provided)
- Extra features (pet happiness alerts, aspect debouncing, proc watching)
