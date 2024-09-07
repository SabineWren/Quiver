WoW 1.12.1 addon for Hunters. Use `/Quiver` or `/qq` to open the configuration menu.

$${\color{red}\* \color{orange}\* \color{yellow}\*}$$
**[Installation Methods](#installation)**
$${\color{yellow}\* \color{orange}\* \color{red}\*}$$

<img src="/Media/Config_UI.jpg" height="462px" align="right">

## Features
- [Aspect Tracker](#aspect-tracker)
- [Auto Shot Timer](#auto-shot-timer)
- [Castbar](#castbar)
- [Lua Functions](#lua-functions)
- [Range Indicator](#range-indicator)
- [Tranq Shot Announcer](#tranq-shot-announcer)
- [Trueshot Aura Alarm](#trueshot-aura-alarm)

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

- Shows Aimed Shot, Multi-Shot, and Trueshot

### Lua Functions
CastNoClip – Cast spell by name if it won't clip a shot. Requires the Auto Shot module.
```lua
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

### Range Indicator
[<img src="/Media/Range_Indicator_Thumbnail.jpg" height="180px">](https://raw.githubusercontent.com/SabineWren/Quiver/main/Media/Range_Indicator_Preview.mp4)

- Based on [Egnar](https://github.com/Medeah/Egnar)
- Automatically locates action bar slots
- Warns you when abilities missing from action bar

Requires some raw spellbook abilities on your action bars (not macros). Hidden action bars work fine.

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
### Option 1 - Pre-bundled zip
Simplest installation, but doesn't automate version updates.
1. [Download](https://github.com/SabineWren/Quiver/releases) latest version
2. Extract the Zip file
3. Change the folder name to `Quiver`
4. Move folder into `<WoW install>/Interface/AddOns/`
5. Restart WoW

### Option 2 - Clone latest release
Requires Git. Easy to update with addon managers or `git pull`
1. Open a terminal in your addons directory
2. `git clone https://github.com/SabineWren/Quiver --branch latest-release`
3. Restart WoW

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

### Custom Events
Files in `/Events` hook into game functions. Use these events if possible instead of declaring your own hooks.
- Spellcast: CastSpell, CastSpellByName, UseAction

### Module Fields and Lifecycle Hooks
```
Id: string
Name: string (use locale)
TooltipText: nil|string (use locale)

OnEnable: unit -> unit
Called every time user enables the module.
Called during initialization after RestoreSavedVariables.

OnDisable: unit -> unit
Called every time user disables the module.

OnInterfaceLock: unit -> unit
Not called while module disabled.
Called every time user locks the UI.

OnInterfaceUnlock: unit -> unit
Not called while module disabled.
Called every time user unlocks the UI.

OnResetFrames: unit -> unit
Called when user clicks a reset button.
Reset All calls this even while module disabled.

OnSavedVariablesRestore: table -> unit
GameEvent: "PLAYER_LOGIN"
Loads state used exclusively used by the module (don't add SavedVariables to the .toc).
Called exactly once, even for disabled modules.

OnSavedVariablesPersist: unit -> table
GameEvent: "PLAYER_LOGOUT"
Persists state used exclusively by the module.
Called exactly once, even for disabled modules.
```
