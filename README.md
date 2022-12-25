WoW 1.12.1 addon for Hunters. Use `/Quiver` or `/qq` to open the configuration menu.

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
Never lose track of your current aspect:
- Shows nothing while in Aspect of the Hawk
- Shows Hawk when no aspect enabled
- Shows current aspect otherwise

### Auto Shot Timer
- Resets swing timer while casting a shot; taken from [YaHT](https://github.com/Aviana/YaHT/tree/1.12.1)
- Ignores instant spells such as Arcane Shot; taken from [HSK](https://github.com/anstellaire/HunterSwissKnife)
- Works with Trueshot

### Castbar
- Shows Aimed Shot, Multi-Shot, and Trueshot
- Includes a pfUI module that adds Trueshot support to the pfUI castbar

### Range Indicator
- Based on [Egnar](https://github.com/Medeah/Egnar)
- Automatically locates action bar slots
- Warns you when abilities missing from action bar
- Persists size and position

Requires some raw spellbook abilities on your action bars (not macros). Hidden action bars work fine.

### Tranq Shot Announcer
- Based on [Xtranq](https://github.com/unknauwn/XTranqManager/tree/master)

It's deliberately less customizable than Xtranq, so disable this module and run Xtranq if that bothers you. I'm open to adding tranq rotation features, but I'm not a fan of how Xtranq does it. Perhaps letting one hunter configure the rotation for all? Feel free to request features.

### Trueshot Aura Alarm
This checks if you have Trueshot Aura talented. If so, Quiver tracks the buff and duration, and warns you with a texture overlay to recast it.

# Installation
1. [Download](https://github.com/SabineWren/Quiver/releases) latest version
2. Extract the Zip file
3. Remove the `-main` from the directory name
4. Move directory into `<WoW install>/Interface/AddOns/`
5. Restart WoW.

# Possible Futre Features
### Pet Pamper
Roid can't do everything for pets. Amarra made a pet utils addon with features like auto-find food when feeding pet. This might be a deep rabbit hole.

### Macro Replacements
Every hunter needs aspect and trap macros. Mine are copy-pasted Roid macros, but HSK implements its own version of aspect overrides.

### Low Ammo Warning

### Hunter's Mark Timer

## Contributing
Open an issue or PM me on Discord:
- Code
- Translations
- Bug reports

## Localization
Quiver looks up spells by name, which change with client locale. I use Wowhead to find the spell names for each locale. Theoretically, Quiver should work with a `/Locale` file matching your client, but the translations aren't complete.

## Custom Events
Files in `/Events` hook into game functions. Use these events if possible instead of declaring your own hooks.
- Spellcast: CastSpell, CastSpellByName, UseAction

## Module Lifecycle Hooks
The UI code is a mess right now, but soon there will be an event for attaching a frame to the Main Menu. If creating a new module, include a name for it in the locale file.
```
OnInitFrames
{ IsReset: Boolean } -> unit
Called with false after restoring saved variables.
Called with true after user resets frames.

OnEnable
unit -> unit
Called every time user enables the module.
Called during initialization after RestoreSavedVariables.

OnDisable
unit -> unit
Called every time user disables the module.

OnInterfaceLock
unit -> unit
Not called while module disabled.
Called every time user locks the UI.

OnInterfaceUnlock
unit -> unit
Not called while module disabled.
Called every time user unlocks the UI.

OnSavedVariablesRestore
table -> unit
GameEvent: "PLAYER_LOGIN"
Loads one table from SavedVariables used exclusively by the module.
Called exactly once, even for disabled modules.

OnSavedVariablesPersist
unit -> table
GameEvent: "PLAYER_LOGOUT"
Persists state used exclusively by the module.
Called exactly once, even for disabled modules.
```
