WoW 1.12.1 addon for Hunters. Use `/Quiver` or `/qq` to open the configuration menu.

<img src="/Media/Config_UI.jpg" height="462px" align="right">

- [Installation](#installation)
- [Contributing](#contributing)

## Features
- [Aspect Tracker](#aspect-tracker)
- [Auto Shot Timer](#auto-shot-timer)
- [Castbar](#castbar)
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

The Auto Shot Timer module enables macros that avoid clipping auto shot:
- Aimed Shot `/qqaimedshot`
- Multi-Shot `/qqmultishot`
- Trueshot `/qqtrueshot`

Casting this way won't interrupt current cast, so move first if casting volley.

Quiver uses a more reliable state machine than any other auto shot timer addon. If you think you've found a bug, record your game with "verbose logging" enabled in the Quiver configuration menu. Sometimes the bar gets stuck from the game not triggering addon events, which is common for movement inside instances, but rare when firing shots. A shot without a corresponding ITEM_LOCK_CHANGED event will break every auto shot timer addon.

Inspired by:
- [HSK](https://github.com/anstellaire/HunterSwissKnife) -- Ignores instant spells such as Arcane Shot
- [YaHT](https://github.com/Aviana/YaHT/tree/1.12.1) -- Resets swing timer while casting a shot

### Castbar
<img src="/Media/Bar_3_Casting.jpg" height="180px">

- Shows Aimed Shot, Multi-Shot, and Trueshot

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

# Installation
1. [Download](https://github.com/SabineWren/Quiver/releases) latest version
2. Extract the Zip file
3. Change the folder name to `Quiver`
4. Move folder into `<WoW install>/Interface/AddOns/`
5. Restart WoW.

# Possible Future Features
I currently have no plans to work on more features.

### Hunter's Mark Timer
Maybe something like the Tranq UI for keeping track of hunters mark for each hunter and target.

### Pet Management
It's a rabbit hole to go down, and other addons exist for pet management.

## Contributing
### Localization
Quiver localizes text, so theoretically it supports translations, but I don't know where to download a non-English client.

### Custom Events
Files in `/Events` hook into game functions. Use these events if possible instead of declaring your own hooks.
- Spellcast: CastSpell, CastSpellByName, UseAction

### Module Fields and Lifecycle Hooks
```
Id: string
Name: string (use locale)

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
