Quiver_Component_ColorPicker_WrapColor = function(store, name, default)
	local set = function(r, g, b) store[name] = { r, g, b } end
	return {
		Get = function() return unpack(store[name]) end,
		Set = set,
		Reset = function()
			local r, g, b = unpack(default)
			set(r, g, b)
		end,
		R = function() return store[name][1] end,
		G = function() return store[name][2] end,
		B = function() return store[name][3] end,
	}
end

local createColorPicker = function(parent, color)
	local f = CreateFrame("Button", nil, parent)
	f:SetWidth(40)
	f:SetHeight(20)

	f:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 8,
		edgeSize = 8,
		insets = { left=2, right=2, top=2, bottom=2 },
	})
	f:SetBackdropColor(color.R(), color.G(), color.B(), 1)

	f:SetScript("OnClick", function(_self)
		-- colors at time of opening picker
		local ri, gi, bi = color.Get()

		-- Must replace existing callback before changing anything else,
		-- or edits can fire previous callback, contaminating other values.
		ColorPickerFrame.func = function()
			local r, g, b = ColorPickerFrame:GetColorRGB()
			color.Set(r, g, b)
			f:SetBackdropColor(r, g, b, 1)
		end

		ColorPickerFrame.cancelFunc = function()
			color.Set(ri, gi, bi)
			f:SetBackdropColor(ri, gi, bi, 1)
		end

		ColorPickerFrame.hasOpacity = false
		ColorPickerFrame:SetColorRGB(ri, gi, bi)
		ColorPickerFrame:Show()
	end)

	return f
end

Quiver_Component_ColorPicker_WithResetLabel = function(parent, labelText, color)
	local f = CreateFrame("Frame", nil, parent)

	f.Label = f:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	f.Label:SetPoint("Left", f, "Left", 0, 0)
	f.Label:SetText(labelText)

	f.BtnReset = Quiver_Component_Button({
		Parent=f, Size=QUIVER.Size.Icon,
		TooltipText=QUIVER_T.UI.ResetColor,
	})
	f.BtnReset.Texture:QuiverSetTexture(0.75, QUIVER.Icon.Reset)
	f.BtnReset:SetPoint("Right", f, "Right", 0, 0)
	f.BtnReset:SetScript("OnClick", function()
		color.Reset()
		f.Button:SetBackdropColor(color.R(), color.G(), color.B(), 1)
	end)

	local x = 4 + f.BtnReset:GetWidth()
	f.Button = createColorPicker(f, color)
	f.Button:SetPoint("Right", f, "Right", -x, 0)

	f:SetHeight(f.Button:GetHeight())
	f.WidthMinusLabel = 6 + x + f.Button:GetWidth()
	return f
end
