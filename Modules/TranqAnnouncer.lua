local Api = require "Api/Index.lua"
local FrameLock = require "Events/FrameLock.lua"
local BorderStyle = require "Modules/BorderStyle.provider.lua"
local L = require "Lib/Index.lua"
local Print = require "Util/Print.lua"

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
	-- lch(52% 100 40) to lch(52% 100 141)
	-- https://non-boring-gradients.netlify.app/
	local NUM_COLORS = 17
	local COLOR_FG = {
		{ 0.95, 0.05, 0.05 },
		{ 0.91, 0.19, 0.0 },
		{ 0.79, 0.35, 0.08 },
		{ 0.75, 0.38, 0.02 },
		{ 0.72, 0.40, 0.0 },
		{ 0.68, 0.43, 0.0 },
		{ 0.64, 0.45, 0.0 },
		{ 0.60, 0.46, 0.0 },
		{ 0.56, 0.48, 0.0 },
		{ 0.52, 0.49, 0.0 },
		{ 0.48, 0.51, 0.0 },
		{ 0.44, 0.52, 0.04 },
		{ 0.40, 0.53, 0.10 },
		{ 0.29, 0.55, 0.0 },
		{ 0.23, 0.55, 0.0 },
		{ 0.15, 0.56, 0.11 },
		{ 0.00, 0.56, 0.18 },
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
		bgFile = "Interface/BUTTONS/WHITE8X8",
		edgeFile = "Interface/BUTTONS/WHITE8X8",
		edgeSize = 1,
		tile = false,
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

	bar.FsPlayerName = bar.ProgressFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	centerVertically(bar.FsPlayerName)
	bar.FsPlayerName:SetPoint("Left", bar, "Left", MARGIN_TEXT, 0)
	bar.FsPlayerName:SetJustifyH("Left")
	bar.FsPlayerName:SetJustifyV("Center")
	bar.FsPlayerName:SetTextColor(1, 1, 1)

	bar.FsCdTimer = bar.ProgressFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
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
			bar:SetFrameStrata("LOW")
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
	local heightBars = L.Array.MapReduce(frame.Bars, Api._Height, L.M.Add)
	-- Make space for at least 1 bar when UI unlocked
	return math.max(heightBars, HEIGHT_BAR) + 2 * INSET
end

local adjustBarYOffsets = function()
	local height = 0
	for _i, v in ipairs(frame.Bars) do
		v:SetPoint("Left", frame, "Left", INSET, 0)
		v:SetPoint("Right", frame, "Right", -INSET, 0)
		v:SetPoint("Top", frame, "Top", 0, -height - INSET)
		height = height + v:GetHeight()
	end
end

local setFramePosition = function(f, s)
	local height = getIdealFrameHeight()
	FrameLock.SideEffectRestoreSize(s, {
		w=WIDTH_FRAME_DEFAULT, h=height, dx=110, dy=150,
	})
	f:SetWidth(s.FrameMeta.W)
	f:SetHeight(s.FrameMeta.H)
	f:SetPoint("TopLeft", s.FrameMeta.X, s.FrameMeta.Y)
end

local createUI = function()
	frame = CreateFrame("Frame", nil, UIParent)
	frame.Bars = {}

	frame:SetFrameStrata("LOW")
	frame:SetBackdrop({
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		edgeSize = 16,
		insets = { left=INSET, right=INSET, top=INSET, bottom=INSET },
	})
	frame:SetBackdropBorderColor(BorderStyle.GetColor())

	setFramePosition(frame, store)
	FrameLock.SideEffectMakeMoveable(frame, store)
	FrameLock.SideEffectMakeResizeable(frame, store, { GripMargin=4 })
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
		and L.Array.Every(frame.Bars, getIsFinished)
		and Quiver_Store.IsLockedFrames
end

local hideFrameDeleteBars = function()
	frame:Hide()
	for _i, v in ipairs(frame.Bars) do
		poolProgressBar.Release(v)
	end
	frame.Bars = {}
end

local handleUpdate = function()
	if getCanHide() then hideFrameDeleteBars() end
	-- Animate Progress Bars
	local now = GetTime()
	for _i, v in ipairs(frame.Bars) do
		local secElapsed = now - v.TimeCastSec
		local secProgress = secElapsed > TRANQ_CD_SEC and TRANQ_CD_SEC or secElapsed
		local percentProgress = secProgress / TRANQ_CD_SEC
		local width = (v:GetWidth() - 2 * BORDER_BAR) * percentProgress
		v.ProgressFrame:SetWidth(width > 1 and width or 1)
		v.FsCdTimer:SetText(string.format("%.1f / %.0f", secProgress, TRANQ_CD_SEC))

		local r, g, b = getColorForeground(percentProgress)
		-- RGB scaling doesn't change brightness equally for all colors,
		-- so we may need to make a separate gradient for bg
		local s = 0.7
		v:SetBackdropColor(r*s, g*s, b*s, 0.8)
		v.ProgressFrame:SetBackdropColor(r, g, b, 0.9)
	end
end

-- ************ Event Handlers ************
local handleMsg = function(_source, msg)
	-- For compatibility with other tranq addons, ignore the message source.
	local nameCaster, timeCastSec = message.Deserialize(msg)
	if nameCaster ~= nil then
		local barVisible = L.Array.Find(frame.Bars, function(bar)
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

--- @type Event[]
local _EVENTS = {
	"CHAT_MSG_ADDON",-- Also works with macros
	"CHAT_MSG_SPELL_SELF_DAMAGE",-- Detect misses
	"SPELL_UPDATE_COOLDOWN",
}
local lastCastStart = 0
local getHasFiredTranq = function()
	local isCast, cdStart = Api.Spell.CheckNewCd(
		TRANQ_CD_SEC, lastCastStart, Quiver.L.Spell["Tranquilizing Shot"])
	lastCastStart = cdStart
	return isCast
end
local handleEvent = function()
	if event == "CHAT_MSG_ADDON" then
		handleMsg(arg1, arg2)
	elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
		if string.find(arg1, Quiver.L.CombatLog.Tranq.Miss)
			or string.find(arg1, Quiver.L.CombatLog.Tranq.Resist)
			or string.find(arg1, Quiver.L.CombatLog.Tranq.Fail)
		then
			Print.Line.Say(store.MsgTranqMiss)
			Print.Line.Raid(store.MsgTranqMiss)
		end
	elseif event == "SPELL_UPDATE_COOLDOWN" then
		if getHasFiredTranq() then
			message.Broadcast()
			if store.TranqChannel == "/Say" then
				Print.Line.Say(store.MsgTranqCast)
			elseif store.TranqChannel == "/Raid" then
				Print.Line.Raid(store.MsgTranqCast)
			-- else don't announce
			end
		end
	end
end

local onEnable = function()
	if frame == nil then frame = createUI() end
	frame:SetScript("OnEvent", handleEvent)
	frame:SetScript("OnUpdate", handleUpdate)
	for _i, v in ipairs(_EVENTS) do frame:RegisterEvent(v) end
	if getCanHide() then hideFrameDeleteBars() else frame:Show() end
end
local onDisable = function()
	frame:Hide()
	for _i, v in ipairs(_EVENTS) do frame:UnregisterEvent(v) end
end

---@type QqModule
return {
	Id = MODULE_ID,
	GetName = function() return Quiver.T["Tranq Shot Announcer"] end,
	GetTooltipText = function() return Quiver.T["Announces in chat when your tranquilizing shot hits or misses a target."] end,
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
		store.MsgTranqMiss = savedVariables.MsgTranqMiss or Quiver.T["*** MISSED Tranq Shot ***"]
		store.MsgTranqCast = store.MsgTranqCast or Quiver.T["Casting Tranq Shot"]
		-- TODO DRY violation -- dropdown must match the module store init
		store.TranqChannel = store.TranqChannel or "/Say"
	end,
	OnSavedVariablesPersist = function() return store end,
}
