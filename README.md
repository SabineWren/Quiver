WoW 1.12.1 addon for Hunters. Use `/Quiver` or `/qq` to open the configuration menu.

- [Installation](#installation)
- [Contributing](#contributing)

## Features
- [Auto Shot Castbar](#auto-shot-castbar)
- [Castbar](#castbar)
- [Range Indicator](#range-indicator)
- [Tranq Shot Announcer](#tranq-shot-announcer)

### Auto Shot Castbar
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

# Installation
1. [Download](https://github.com/SabineWren/Quiver/archive/main.zip) latest version
2. Extract the Zip file
3. Remove the `-main` from the directory name
4. Move directory into `<WoW install>/Interface/AddOns/`
5. Restart WoW.

# Planned Features
### Trueshot Alarm
Power Auras works great for PvE, although it's not spec aware. I don't want a constant reminder to recast Trueshot Aura while it's not talented, and Quiver already has code implemented to monitor available spells on action bars.

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

## Module Lifecycle Events
The UI code is a mess right now, but soon there will be an event for attaching a frame to the Main Menu.
```
OnRestoreSavedVariables
table -> unit
GameEvent: "PLAYER_LOGIN"
Loads one table from SavedVariables used exclusively by the module.
Called exactly once, even for disabled modules.
Second table holds state for one customizable frame { W, H, X, Y }.
Mutate the frame metadata to set default values.

OnPersistSavedVariables
unit -> table
GameEvent: "PLAYER_LOGOUT"
Persists state used exclusively by the module.
Called exactly once, even for disabled modules.

OnInitFrames
table -> { IsReset: Boolean } -> unit
Loads saved frame size and position
Called with false after restoring saved variables
Called with true after user resets frames

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
```
Stub for new modules
```
Quiver_Module_<ModuleName> = {
	Id = "<ModuleName>",
	OnRestoreSavedVariables = function(savedVariables) end,
	OnPersistSavedVariables = function() return {} end,
	OnInitFrames = function(savedFrameMeta, options) end,
	OnEnable = function() end,
	OnDisable = function() end,
	OnInterfaceLock = function() end,
	OnInterfaceUnlock = function() end,
}
```
