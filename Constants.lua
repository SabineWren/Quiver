QUIVER = {
	-- I don't know if hidden auras show via GameTooltip.
	Buff_Cap = 32,-- I think UI shows up to 24.
	Debuff_Cap = 24,-- UI shows 16. Turtle allows 8 more hidden.
	Aura_Cap = 32 + 24,
	ColorDefault = {
		AutoShotReload = { 1, 0, 0 },
		AutoShotShoot = { 1, 1, 0 },
		Castbar = { 0.42, 0.41, 0.53 },
		Range = {
			Melee = { 0, 1, 0, 0.7 },
			DeadZone = { 1, 0.5, 0, 0.7 },
			ScareBeast = { 0, 1, 0.2, 0.7 },
			ScatterShot = { 0, 1, 0.8, 0.7 },
			Short = { 0, 0.8, 0.8, 0.7 },
			Long = { 0, 0.8, 0.8, 0.7 },
			Mark = { 1, 0.2, 0, 0.7 },
			TooFar = { 1, 0, 0, 0.7 },
		},
	},
	Size = {
		Border = 12,
		Button = 22,
		Gap = 8,
		Icon = 18,
	},
	Icon = {
		-- Custom
		ArrowsSwap = "Interface\\AddOns\\Quiver\\Textures\\arrow-right-arrow-left",
		CaretDown = "Interface\\AddOns\\Quiver\\Textures\\caret-down-fill",
		GripHandle = "Interface\\AddOns\\Quiver\\Textures\\grip-lines",
		LockClosed = "Interface\\AddOns\\Quiver\\Textures\\lock",
		LockOpen = "Interface\\AddOns\\Quiver\\Textures\\lock-open",
		Reset = "Interface\\AddOns\\Quiver\\Textures\\arrow-rotate-right",
		XMark = "Interface\\AddOns\\Quiver\\Textures\\xmark",
		-- Client
		Aspect_Beast = "Interface\\Icons\\Ability_Mount_PinkTiger",
		Aspect_Cheetah = "Interface\\Icons\\Ability_Mount_JungleTiger",
		Aspect_Hawk = "Interface\\Icons\\Spell_Nature_RavenForm",
		Aspect_Monkey = "Interface\\Icons\\Ability_Hunter_AspectOfTheMonkey",
		Aspect_Pack = "Interface\\Icons\\Ability_Mount_WhiteTiger",
		Aspect_Wild = "Interface\\Icons\\Spell_Nature_ProtectionformNature",-- 'form' is not a typo.
		Aspect_Wolf = "Interface\\Icons\\Ability_Mount_WhiteDireWolf",
		CurseOfTongues = "Interface\\Icons\\Spell_Shadow_CurseOfTounges",
		-- Confirmed correct casting on Turtle
		NaxxTrinket = "Interface\\Icons\\INV_Trinket_Naxxramas04",
		-- I think this is wrong, but other addons use this casing.
		-- Maybe Turtle changes the name? Can servers do that?
		NaxxTrinketWrong = "Interface\\Icons\\Inv_Trinket_Naxxramas04",
		Quickshots = "Interface\\Icons\\Ability_Warrior_InnerRage",
		RapidFire = "Interface\\Icons\\Ability_Hunter_RunningShot",
		TrollBerserk = "Interface\\Icons\\Racial_Troll_Berserk",
		Trueshot = "Interface\\Icons\\Ability_TrueShot",
	},
}
