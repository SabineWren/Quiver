WoW 1.12.1 addon for Hunters. Use `/Quiver` or `/qq` to open the configuration menu.

<img src="/Media/Quiver_colours.jpg" height="502px" align="right">

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

- Resets swing timer while casting a shot; taken from [YaHT](https://github.com/Aviana/YaHT/tree/1.12.1)
- Ignores instant spells such as Arcane Shot; taken from [HSK](https://github.com/anstellaire/HunterSwissKnife)
- Works with Trueshot

### Castbar
<img src="/Media/Bar_3_Casting.jpg" height="180px">

- Shows Aimed Shot, Multi-Shot, and Trueshot
- Includes a pfUI module that adds Trueshot support to the pfUI castbar

### Range Indicator
[Watch Video Preview](https://raw.githubusercontent.com/SabineWren/Quiver/main/Media/Range_Indicator_Preview.mp4)

- Based on [Egnar](https://github.com/Medeah/Egnar)
- Automatically locates action bar slots
- Warns you when abilities missing from action bar
- Persists size and position

Requires some raw spellbook abilities on your action bars (not macros). Hidden action bars work fine.

### Tranq Shot Announcer
Screenshot or video coming soon.

Announces when casting Tranquilizing Shot, and again if the shot misses. Shows the Tranq cooldown of every hunter, sorted by time left.

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
I don't plan to implement any of these at the moment, but they're ideas for where Quiver could go.

### Ammo Counter
Not sure where to scope this, as other addons can track ammo stored on bank alts. Perhaps an overlay warning when currently equipped ammo runs low in inventory.

### Hunter's Mark Timer
Maybe something like the Tranq UI for keeping track of which hunters mark each target, and the remaining time.

### Macro Replacements
Every hunter needs aspect and trap macros. Mine are copy-pasted Roid macros, but HSK implements its own version of aspect overrides.

### Pet Pamper
It's a deep rabbit hole to go down, and other addons exist for pet management.

## Contributing
### Localization
Quiver localizes all text, so theoretically it supports translations, but I don't know where to download a non-English client.

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

(optional) OnResetFrames: unit -> unit
Called when user clicks a reset button.
The reset-all button will call this even if module disabled.

OnSavedVariablesRestore: table -> unit
GameEvent: "PLAYER_LOGIN"
Loads state used exclusively used by the module (don't add SavedVariables to the .toc).
Called exactly once, even for disabled modules.

OnSavedVariablesPersist: unit -> table
GameEvent: "PLAYER_LOGOUT"
Persists state used exclusively by the module.
Called exactly once, even for disabled modules.
```
