local MODULE_ID = "TranqAnnouncer"
local store = nil
local frame = nil
local TRANQ_CD_SEC = 20
local ADDON_MESSAGE_CAST = "Quiver_Tranq_Shot"
local INSET = 4
local BORDER_BAR = 1
local HEIGHT_BAR = 17
local WIDTH_FRAME_DEFAULT = 120

--local TODO_SPELL_NAME = QUIVER_T.Spellbook.Tranquilizing_Shot
local TODO_SPELL_NAME = QUIVER_T.Spellbook.Serpent_Sting

local createProgressBar = function()
	local MARGIN_TEXT = 4
	local bar = CreateFrame("Frame")
	bar:SetFrameStrata("Low")
	bar:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8", tile = false,
		edgeFile = "Interface/BUTTONS/WHITE8X8", edgeSize = 1,
	})
	bar:SetBackdropColor(0, 0.5, 0, 0.3)
	bar:SetBackdropBorderColor(0, 0, 0, 0.3)

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
	bar.ProgressFrame:SetBackdropColor(0, 1.0, 0, 0.9)

	bar.FsPlayerName = bar:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	centerVertically(bar.FsPlayerName)
	bar.FsPlayerName:SetPoint("Left", bar, "Left", MARGIN_TEXT, 0)
	bar.FsPlayerName:SetJustifyH("Left")
	bar.FsPlayerName:SetJustifyV("Center")
	bar.FsPlayerName:SetTextColor(1, 1, 1)

	bar.FsCdTimer = bar:CreateFontString(nil, "ARTWORK", "GameFontNormal")
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
			local f = table.remove(fs) or createProgressBar()
			f:SetParent(parent)
			f:Show()-- Necessary for recycling frames.
			return f
		end,
		Release = function(f)
			f:SetParent(nil)-- This also hides the frame.
			f:ClearAllPoints()
			table.insert(fs, f)
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
		w=WIDTH_FRAME_DEFAULT, h=height, dx=-0.5 * WIDTH_FRAME_DEFAULT, dy=200,
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
		local playerName = UnitName("player")
		local _,_, msLatency = GetNetStats()
		local msg = ADDON_MESSAGE_CAST..":"..playerName..":"..msLatency
		SendAddonMessage("Quiver", msg, "Raid")
	end
end

local getCanHide = function()
	local now = GetTime()
	local getIsFinished = function(v)
		local secElapsed = now - v.ProgressFrame.TimeCastSec
		return secElapsed >= TRANQ_CD_SEC
	end
	return not UnitAffectingCombat('player')
		and Quiver_Lib_F.Every(frame.Bars, getIsFinished)
		and Quiver_Store.IsLockedFrames
end

local hideFrameDeleteBars = function()
	frame:Hide()
	for k, bar in frame.Bars do
		poolProgressBar.Release(bar)
		frame.Bars[k] = nil
	end
end

local handleUpdate = function()
	if getCanHide() then hideFrameDeleteBars() end
	-- Animate Progress Bars
	local now = GetTime()
	for _k, bar in frame.Bars do
		local secElapsed = now - bar.ProgressFrame.TimeCastSec
		local secProgress = secElapsed > TRANQ_CD_SEC and TRANQ_CD_SEC or secElapsed
		local width = (bar:GetWidth() - 2 * BORDER_BAR) * secProgress / TRANQ_CD_SEC
		bar.ProgressFrame:SetWidth(width > 1 and width or 1)
		local format = secProgress == TRANQ_CD_SEC and "%.0f / %.0f" or "%.1f / %.0f"
		bar.FsCdTimer:SetText(string.format(format, secProgress, TRANQ_CD_SEC))
	end
end

local handleEvent = function()
	-- For compatibility with other tranq addons, ignore the addon name (arg1).
	if event == "CHAT_MSG_ADDON" then
		local _, _, nameCaster, msLatencyCaster = string.find(arg2, ADDON_MESSAGE_CAST..":(.*):(.*)")
		if nameCaster ~= nil and msLatencyCaster ~= nil then
			local bar = poolProgressBar.Acquire(frame)
			bar:SetHeight(HEIGHT_BAR)
			-- This is not deterministically ordered, since reported latency can change
			-- between two nearly-simultaneous messages, flipping their order for some users.
			-- TODO order is more important than exact timing, so this either requires
			-- an accuracy tradeoff, or a smarter algorithm to guarantee ordering.
			local _,_, msLatency = GetNetStats()
			bar.ProgressFrame.TimeCastSec = GetTime() - (msLatencyCaster + msLatency) / 1000
			bar.FsPlayerName:SetText(nameCaster)

			table.insert(frame.Bars, bar)
			adjustBarYOffsets()

			frame:SetHeight(getIdealFrameHeight())
			frame:Show()
		end
	elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
		--local _, _, targetHit = string.find(arg1, QUIVER_T.CombatLog.Tranq.Hit)
		--if targetHit ~= nil then Quiver_Lib_Print.Say(store.MsgTranqHit) end
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
