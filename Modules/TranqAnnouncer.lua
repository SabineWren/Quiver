local MODULE_ID = "TranqAnnouncer"
local store = nil
local frame = nil
local TRANQ_CD_SEC = 20
local ADDON_MESSAGE_CAST = "Quiver_Tranq_Shot"
local INSET = 4
local HEIGHT_BAR = 20

--local TODO_SPELL_NAME = QUIVER_T.Spellbook.Tranquilizing_Shot
local TODO_SPELL_NAME = QUIVER_T.Spellbook.Serpent_Sting

local createProgressBar = function()
	local BORDER_BAR = 1
	local MARGIN_TEXT = 4
	local f = CreateFrame("Frame")
	f:SetFrameStrata("Low")
	f:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8", tile = false,
		edgeFile = "Interface/BUTTONS/WHITE8X8", edgeSize = BORDER_BAR,
	})
	f:SetBackdropColor(0, 0.5, 0, 0.3)
	f:SetBackdropBorderColor(0.1, 0.3, 0.1, 0.5)

	local centerVertically = function(ele)
		ele:SetPoint("Top", f, "Top", 0, -BORDER_BAR)
		ele:SetPoint("Bottom", f, "Bottom", 0, BORDER_BAR)
	end

	f.ProgressFrame = CreateFrame("Frame", nil, f)
	centerVertically(f.ProgressFrame)
	f.ProgressFrame:SetPoint("Left", f, "Left", BORDER_BAR, 0)
	f.ProgressFrame:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8", tile = false,
	})
	f.ProgressFrame:SetBackdropColor(0, 1.0, 0, 0.9)

	f.FsPlayerName = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	centerVertically(f.FsPlayerName)
	f.FsPlayerName:SetPoint("Left", f, "Left", MARGIN_TEXT, 0)
	f.FsPlayerName:SetJustifyH("Left")
	f.FsPlayerName:SetJustifyV("Center")
	f.FsPlayerName:SetTextColor(1, 1, 1)

	f.FsCdTimer = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	centerVertically(f.FsCdTimer)
	f.FsCdTimer:SetPoint("Right", f, "Right", -MARGIN_TEXT, 0)
	f.FsCdTimer:SetJustifyH("Right")
	f.FsPlayerName:SetJustifyV("Center")
	f.FsCdTimer:SetTextColor(1, 1, 1)

	return f
end

local poolProgressBar = (function()
	local fs = {}
	return {
		Acquire = function(parent)
			local f = table.remove(fs) or createProgressBar()
			f:SetParent(parent)
			return f
		end,
		Release = function(f)
			f:Hide()
			f:SetParent(nil)
			f:ClearAllPoints()
			table.insert(fs, f)
		end,
	}
end)()

local setFramePosition = function(f, s)
	s.FrameMeta = Quiver_Event_FrameLock_RestoreSize(s.FrameMeta, {
		w=160, h=HEIGHT_BAR + 2 * INSET, dx=160 * -0.5, dy=200,
	})
	f:SetWidth(s.FrameMeta.W)
	f:SetHeight(s.FrameMeta.H)
	f:SetPoint("TopLeft", s.FrameMeta.X, s.FrameMeta.Y)
end

local createUI = function()
	local f = CreateFrame("Frame", nil, UIParent)
	f.Bars = {}
	setFramePosition(f, store)
	Quiver_Event_FrameLock_MakeMoveable(f, store.FrameMeta)
	Quiver_Event_FrameLock_MakeResizeable(f, store.FrameMeta, { GripMargin=4 })

	f:SetFrameStrata("Low")
	f:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 8,
		edgeSize = 16,
		insets = { left=INSET, right=INSET, top=INSET, bottom=INSET },
	})
	f:SetBackdropColor(0, 0, 0, 0.2)
	f:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)

	return f
end

local handleCast = function(spellName)
	if spellName == TODO_SPELL_NAME then
		local playerName = UnitName("player")
		local _,_, msLatency = GetNetStats()
		local msg = ADDON_MESSAGE_CAST..":"..playerName..":"..msLatency
		SendAddonMessage("Quiver", msg, "Raid")
	end
end

local handleUpdate = function()
	local now = GetTime()
	for _k, bar in frame.Bars do
		local secElapsed = now - bar.ProgressFrame.TimeCastSec
		local secProgress = secElapsed > TRANQ_CD_SEC and TRANQ_CD_SEC or secElapsed
		local width = bar:GetWidth() * secProgress / TRANQ_CD_SEC
		bar.ProgressFrame:SetWidth(width)
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
			-- This is not deterministically ordered, since reported latency can change
			-- between two nearly-simultaneous messages, flipping their order for some users.
			-- TODO order is more important than exact timing, so this either requires
			-- an accuracy tradeoff, or a smarter algorithm to guarantee ordering.
			local _,_, msLatency = GetNetStats()
			bar.ProgressFrame.TimeCastSec = GetTime() - (msLatencyCaster + msLatency) / 1000
			bar.ProgressFrame:SetWidth(1)
			bar.FsPlayerName:SetText(nameCaster)

			local height = 0
			for _i, b in frame.Bars do
				height = height + b:GetHeight()
			end

			bar:SetPoint("Left", frame, "Left", INSET, 0)
			bar:SetPoint("Right", frame, "Right", -INSET, 0)
			bar:SetPoint("Top", frame, "Top", 0, -height - INSET)
			bar:SetHeight(HEIGHT_BAR)

			table.insert(frame.Bars, bar)
			frame:SetHeight(height + HEIGHT_BAR + 2 * INSET)
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
	if Quiver_Store.IsLockedFrames then frame:Hide() else frame:Show() end
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
	OnInterfaceLock = function() return nil end,
	OnInterfaceUnlock = function() return nil end,
	OnResetFrames = function()
		store.FrameMeta = nil
		if frame then setFramePosition(frame, store) end
	end,
	OnSavedVariablesRestore = function(savedVariables)
		store = savedVariables
		store.MsgTranqMiss = savedVariables.MsgTranqMiss or QUIVER_T.Tranq.DefaultMiss

		-- TODO temp code to force default position
		store.FrameMeta = nil

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
