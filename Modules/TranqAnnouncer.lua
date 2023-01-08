local MODULE_ID = "TranqAnnouncer"
local store = nil
local frame = nil
local TRANQ_CD_SEC = 20
local INSET = 4
local BORDER_BAR = 1
local HEIGHT_BAR = 17
local WIDTH_FRAME_DEFAULT = 120

local messaging = (function()
	--local ADDON_MESSAGE_CAST = "Quiver_Tranq_Shot"
	local ADDON_MESSAGE_CAST = "Quiver_Tranq_Shot_DEV_BUILD"
	local MATCH = ADDON_MESSAGE_CAST..":(.*):(.*)"
	return {
		Broadcast = function()
			local playerName = UnitName("player")
			local _,_, msLatency = GetNetStats()
			local serialized = ADDON_MESSAGE_CAST..":"..playerName..":"..msLatency
			SendAddonMessage("Quiver", serialized, "Raid")
		end,
		Deserialize = function(msg)
			local _, _, nameCaster, latencyOrZero = string.find(msg, MATCH)
			local msLatencyCaster = latencyOrZero and latencyOrZero or 0
			-- Game client updates latency every 30 seconds, so it's unlikely
			-- to break deterministic ordering, but could happen in rare cases.
			-- Might consider a logical clock or something in the future.
			local _,_, msLatency = GetNetStats()
			local timeCastSec = GetTime() - (msLatency + msLatencyCaster) / 1000
			return nameCaster, timeCastSec
		end,
	}
end)()

local getColorForeground = (function()
	-- It would be expensive to compute non-rgb gradients in Lua during the update loop,
	-- so we design stop points using an online gradient generator and convert them to RGB.
	-- LCH color space: hsl(0, 90%, 50%) to hsl(120, 90%, 50%)
	-- https://non-boring-gradients.netlify.app/
	local COLOR_FG = {
		{ 0.95, 0.05, 0.05 },
		{ 0.95, 0.20, 0.0 },
		{ 0.85, 0.37, 0.10 },
		{ 0.85, 0.42, 0.04 },
		{ 0.84, 0.46, 0.0 },
		{ 0.83, 0.51, 0.0 },
		{ 0.81, 0.55, 0.0 },
		{ 0.79, 0.59, 0.0 },
		{ 0.77, 0.63, 0.0 },
		{ 0.74, 0.67, 0.0 },
		{ 0.71, 0.71, 0.0 },
		{ 0.68, 0.75, 0.0 },
		{ 0.64, 0.78, 0.0 },
		{ 0.60, 0.82, 0.12 },
		{ 0.55, 0.86, 0.20 },
		{ 0.31, 0.91, 0.0 },
		{ 0.05, 0.95, 0.05 },
	}
	return function(progress)
		local i = math.ceil(progress * 17)-- stop points 6.25% apart
		--Fixes Rare bug. I suspect floating point error yielding 17.00001
		local index = i <= 17 and i or 17
		return unpack(COLOR_FG[index])
	end
end)()

--local TODO_SPELL_NAME = QUIVER_T.Spellbook.Tranquilizing_Shot
local TODO_SPELL_NAME = QUIVER_T.Spellbook.Serpent_Sting

local createProgressBar = function()
	local MARGIN_TEXT = 4
	local bar = CreateFrame("Frame")
	bar:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8", tile = false,
		edgeFile = "Interface/BUTTONS/WHITE8X8", edgeSize = 1,
	})
	bar:SetBackdropBorderColor(0, 0, 0, 0.6)

	local centerVertically = function(ele)
		ele:SetPoint("Top", bar, "Top", 0, -BORDER_BAR)
		ele:SetPoint("Bottom", bar, "Bottom", 0, BORDER_BAR)
	end

	bar.ProgressFrame = CreateFrame("Frame", nil, bar)
	centerVertically(bar.ProgressFrame)
	bar.ProgressFrame:SetPoint("Left", bar, "Left", BORDER_BAR, 0)
	bar.ProgressFrame:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8", tile = false,
	})

	bar.FsPlayerName = bar.ProgressFrame:CreateFontString(nil, "Overlay", "GameFontNormal")
	centerVertically(bar.FsPlayerName)
	bar.FsPlayerName:SetPoint("Left", bar, "Left", MARGIN_TEXT, 0)
	bar.FsPlayerName:SetJustifyH("Left")
	bar.FsPlayerName:SetJustifyV("Center")
	bar.FsPlayerName:SetTextColor(1, 1, 1)

	bar.FsCdTimer = bar.ProgressFrame:CreateFontString(nil, "Overlay", "GameFontNormal")
	centerVertically(bar.FsCdTimer)
	bar.FsCdTimer:SetPoint("Right", bar, "Right", -MARGIN_TEXT, 0)
	bar.FsCdTimer:SetJustifyH("Right")
	bar.FsPlayerName:SetJustifyV("Center")
	bar.FsCdTimer:SetTextColor(1, 1, 1)

	return bar
end

local poolProgressBar = (function()
	local fs = {}
	return {
		Acquire = function(parent)
			local bar = table.remove(fs) or createProgressBar()
			bar:SetParent(parent)
			-- Clearing parent on release has side effects: hides frame and change stratas
			bar:SetFrameStrata("Low")
			bar.ProgressFrame:SetFrameStrata("Medium")
			bar:Show()
			return bar
		end,
		Release = function(bar)
			bar:SetParent(nil)
			bar:ClearAllPoints()
			table.insert(fs, bar)
		end,
	}
end)()

local getIdealFrameHeight = function()
	local height = 0
	for _i, bar in frame.Bars do
		height = height + bar:GetHeight()
	end
	-- Make space for at least 1 bar when UI unlocked
	if height == 0 then height = HEIGHT_BAR end
	return height + 2 * INSET
end

local adjustBarYOffsets = function()
	local height = 0
	for _i, bar in frame.Bars do
		bar:SetPoint("Left", frame, "Left", INSET, 0)
		bar:SetPoint("Right", frame, "Right", -INSET, 0)
		bar:SetPoint("Top", frame, "Top", 0, -height - INSET)
		height = height + bar:GetHeight()
	end
end

local setFramePosition = function(f, s)
	local height = getIdealFrameHeight()
	s.FrameMeta = Quiver_Event_FrameLock_RestoreSize(s.FrameMeta, {
		w=WIDTH_FRAME_DEFAULT, h=height, dx=110, dy=150,
	})
	f:SetWidth(s.FrameMeta.W)
	f:SetHeight(s.FrameMeta.H)
	f:SetPoint("TopLeft", s.FrameMeta.X, s.FrameMeta.Y)
end

local createUI = function()
	frame = CreateFrame("Frame", nil, UIParent)
	frame.Bars = {}

	frame:SetFrameStrata("Low")
	frame:SetBackdrop({
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 16,
		insets = { left=INSET, right=INSET, top=INSET, bottom=INSET },
	})
	frame:SetBackdropBorderColor(0.6, 0.9, 0.7, 1.0)

	setFramePosition(frame, store)
	Quiver_Event_FrameLock_MakeMoveable(frame, store.FrameMeta)
	Quiver_Event_FrameLock_MakeResizeable(frame, store.FrameMeta, { GripMargin=4 })
	return frame
end

local handleCast = function(spellName)
	if spellName == TODO_SPELL_NAME then
		messaging.Broadcast()
		--Quiver_Lib_Print.Say(store.MsgTranqHit)
		DEFAULT_CHAT_FRAME:AddMessage(store.MsgTranqHit)
	end
end

local getCanHide = function()
	local now = GetTime()
	local getIsFinished = function(v)
		local secElapsed = now - v.TimeCastSec
		return secElapsed >= TRANQ_CD_SEC
	end
	return not UnitAffectingCombat('player')
		and Quiver_Lib_F.Every(frame.Bars, getIsFinished)
		and Quiver_Store.IsLockedFrames
end

local hideFrameDeleteBars = function()
	frame:Hide()
	for _k, bar in frame.Bars do
		poolProgressBar.Release(bar)
	end
	-- Couldn't figre out how to clear all values without remaking the table.
	frame.Bars = {}
end

local handleUpdate = function()
	if getCanHide() then hideFrameDeleteBars() end
	-- Animate Progress Bars
	local now = GetTime()
	for _k, bar in frame.Bars do
		local secElapsed = now - bar.TimeCastSec
		local secProgress = secElapsed > TRANQ_CD_SEC and TRANQ_CD_SEC or secElapsed
		local percentProgress = secProgress / TRANQ_CD_SEC
		local width = (bar:GetWidth() - 2 * BORDER_BAR) * percentProgress
		bar.ProgressFrame:SetWidth(width > 1 and width or 1)
		bar.FsCdTimer:SetText(string.format("%.1f / %.0f", secProgress, TRANQ_CD_SEC))

		local r, g, b = getColorForeground(percentProgress)
		-- RGB scaling doesn't change brightness equally for all colors,
		-- so we may need to make a separate gradient for bg
		local s = 0.7
		bar:SetBackdropColor(r*s, g*s, b*s, 0.8)
		bar.ProgressFrame:SetBackdropColor(r, g, b, 0.9)
	end
end

local handleEvent = function()
	-- For compatibility with other tranq addons, ignore the addon name (arg1).
	if event == "CHAT_MSG_ADDON" then
		local nameCaster, timeCastSec = messaging.Deserialize(arg2)
		if nameCaster ~= nil then
			local bar = poolProgressBar.Acquire(frame)
			bar:SetHeight(HEIGHT_BAR)

			bar.TimeCastSec = timeCastSec
			bar.FsPlayerName:SetText(nameCaster)

			table.insert(frame.Bars, bar)
			table.sort(frame.Bars, function(a,b) return a.TimeCastSec < b.TimeCastSec end)
			adjustBarYOffsets()

			frame:SetHeight(getIdealFrameHeight())
			frame:Show()
		end
	elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
		if string.find(arg1, QUIVER_T.CombatLog.Tranq.Miss)
			or string.find(arg1, QUIVER_T.CombatLog.Tranq.Resist)
			or string.find(arg1, QUIVER_T.CombatLog.Tranq.Fail)
		then
			Quiver_Lib_Print.Say(store.MsgTranqMiss)
		end
	end
end

local EVENTS = {
	"CHAT_MSG_ADDON",
	"CHAT_MSG_SPELL_SELF_DAMAGE",
}
local onEnable = function()
	if frame == nil then frame = createUI() end
	frame:SetScript("OnEvent", handleEvent)
	frame:SetScript("OnUpdate", handleUpdate)
	for _k, e in EVENTS do frame:RegisterEvent(e) end
	Quiver_Event_Spellcast_Instant.Subscribe(MODULE_ID, handleCast)
	if getCanHide() then hideFrameDeleteBars() else frame:Show() end
end
local onDisable = function()
	frame:Hide()
	Quiver_Event_Spellcast_Instant.Dispose(MODULE_ID)
	for _k, e in EVENTS do frame:UnregisterEvent(e) end
end

Quiver_Module_TranqAnnouncer = {
	Id = MODULE_ID,
	Name = QUIVER_T.ModuleName[MODULE_ID],
	OnEnable = onEnable,
	OnDisable = onDisable,
	OnInterfaceLock = function()
		if getCanHide() then hideFrameDeleteBars() end
	end,
	OnInterfaceUnlock = function() frame:Show() end,
	OnResetFrames = function()
		store.FrameMeta = nil
		if frame then setFramePosition(frame, store) end
	end,
	OnSavedVariablesRestore = function(savedVariables)
		store = savedVariables
		store.MsgTranqMiss = savedVariables.MsgTranqMiss or QUIVER_T.Tranq.DefaultMiss

		-- TODO move to migration and rename hit -> cast
		-- We notify on tranq cast instead of hit. To prevent a breaking
		-- release version, attempt changing contradictory text.
		if store.MsgTranqHit then
			local startPos, _ = string.find(string.lower(store.MsgTranqHit), "hit")
			if startPos then
				store.MsgTranqHit = QUIVER_T.Tranq.DefaultCast
				DEFAULT_CHAT_FRAME:AddMessage("Changed tranq message to new default", 1, 0, 0)
			end
		else
			store.MsgTranqHit = QUIVER_T.Tranq.DefaultCast
		end
	end,
	OnSavedVariablesPersist = function() return store end,
}
