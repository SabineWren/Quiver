local MODULE_ID = "TranqAnnouncer"
local store = nil
local frame = nil
local TRANQ_CD_SEC = 20
local INSET = 4
local BORDER_BAR = 1
local HEIGHT_BAR = 17
local WIDTH_FRAME_DEFAULT = 120

local message = (function()
	local ADDON_MESSAGE_CAST = "Quiver_Tranq_Shot"
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
	local NUM_COLORS = 17
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
		-- Fixes floating point bugs
		local p = progress <= 0.0 and 0.001
			or progress >= 1.0 and 0.999
			or progress
		local i = math.ceil(p * NUM_COLORS)
		return unpack(COLOR_FG[i])
	end
end)()

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

-- ************ Frame Update Handlers ************
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

-- ************ Event Handlers ************
local handleMsg = function(_source, msg)
	-- For compatibility with other tranq addons, ignore the message source.
	local nameCaster, timeCastSec = message.Deserialize(msg)
	if nameCaster ~= nil then
		local barVisible = Quiver_Lib_F.Find(frame.Bars, function(bar)
			return bar.FsPlayerName:GetText() == nameCaster
		end)

		if barVisible then
			barVisible.TimeCastSec = timeCastSec
		else
			local barNew = poolProgressBar.Acquire(frame)
			barNew.TimeCastSec = timeCastSec
			barNew:SetHeight(HEIGHT_BAR)
			barNew.FsPlayerName:SetText(nameCaster)
			table.insert(frame.Bars, barNew)
		end

		table.sort(frame.Bars, function(a,b) return a.TimeCastSec < b.TimeCastSec end)
		adjustBarYOffsets()
		frame:SetHeight(getIdealFrameHeight())
		frame:Show()
	end
end

-- Using a state variable so we can remove most false positives.
-- Unhandled edge case -- Casting a different spell while mashing tranq shot will announce a tranq
local isClickedTranq = false
local handleCast = function(spellName)
	if spellName == QUIVER_T.Spellbook.Tranquilizing_Shot then
		isClickedTranq = true
	end
end

local EVENTS = {
	"CHAT_MSG_ADDON",-- Also works with macros
	"CHAT_MSG_SPELL_SELF_DAMAGE",
	"ITEM_LOCK_CHANGED",-- Inventory event, such as using ammo
	"SPELLCAST_STOP",-- Finished cast
	"SPELLCAST_FAILED",-- Too close, Spell on CD, already in progress, or success after dropping target
}
local handleEvent = function()
	if event == "CHAT_MSG_ADDON" then
		handleMsg(arg1, arg2)
	elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
		if string.find(arg1, QUIVER_T.CombatLog.Tranq.Miss)
			or string.find(arg1, QUIVER_T.CombatLog.Tranq.Resist)
			or string.find(arg1, QUIVER_T.CombatLog.Tranq.Fail)
		then
			Quiver_Lib_Print.Say(store.MsgTranqMiss)
		end
	elseif event == "SPELLCAST_STOP" or event == "SPELLCAST_FAILED" then
		isClickedTranq = false
	elseif event == "ITEM_LOCK_CHANGED" then
		if isClickedTranq then
			message.Broadcast()
			Quiver_Lib_Print.Say(store.MsgTranqCast)
			isClickedTranq = false
		end
	end
end

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
		store.MsgTranqCast = store.MsgTranqCast or QUIVER_T.Tranq.DefaultCast
	end,
	OnSavedVariablesPersist = function() return store end,
}
