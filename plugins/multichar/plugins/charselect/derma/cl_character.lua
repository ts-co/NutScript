local PANEL = {}

local WHITE = Color(255, 255, 255, 150)
local SELECTED = Color(255, 255, 255, 230)

PANEL.WHITE = WHITE
PANEL.SELECTED = SELECTED
PANEL.HOVERED = Color(255, 255, 255, 50)
PANEL.ANIM_SPEED = 0.1
PANEL.FADE_SPEED = 0.5

-- Called when the tabs for the character menu should be created.
function PANEL:createTabs()
	local load, create

	-- Only show the load tab if playable characters exist.
	if (nut.characters and #nut.characters > 0) then
		load = self:addTab("continue", self.createCharacterSelection)
	end

	-- Only show the create tab if the local player can create characters.
	if (hook.Run("CanPlayerCreateCharacter", LocalPlayer()) ~= false) then
		create = self:addTab("create", self.createCharacterCreation)
	end

	-- By default, select the continue tab, or the create tab.
	if (IsValid(load)) then
		load:setSelected()
	elseif (IsValid(create)) then
		create:setSelected()
	end

	-- If the player has a character (i.e. opened this menu from F1 menu), then
	-- don't add a disconnect button. Just add a close button.
	if (LocalPlayer():getChar()) then
		self:addTab("return", function()
			if (IsValid(self) and LocalPlayer():getChar()) then
				self:fadeOut()
			end
		end, true)
		return
	end

	-- Otherwise, add a disconnect button.
	self:addTab("leave", function()
		vgui.Create("nutCharacterConfirm")
			:setTitle(L("disconnect"):upper().."?")
			:setMessage(L("You will disconnect from the server."):upper())
			:onConfirm(function() LocalPlayer():ConCommand("disconnect") end)
	end, true)
end

function PANEL:createTitle()
	self.title = self:Add("DLabel")
	self.title:Dock(TOP)
	self.title:DockMargin(64, 48, 0, 0)
	self.title:SetContentAlignment(1)
	self.title:SetTall(96)
	self.title:SetFont("nutTitle2Font")
	self.title:SetText(L(SCHEMA and SCHEMA.name or "Unknown"):upper())
	self.title:SetTextColor(WHITE)

	self.desc = self:Add("DLabel")
	self.desc:Dock(TOP)
	self.desc:DockMargin(64, 0, 0, 0)
	self.desc:SetTall(32)
	self.desc:SetContentAlignment(7)
	self.desc:SetText(L(SCHEMA and SCHEMA.desc or ""):upper())
	self.desc:SetFont("nutTitle3Font")
	self.desc:SetTextColor(WHITE)
end

function PANEL:addTab(name, callback, justClick)
	local button = self.tabs:Add("nutCharacterTabButton")
	button:setText(L(name):upper())

	if (justClick) then
		if (isfunction(callback)) then
			button.DoClick = function(button) callback(self) end
		end
		return
	end

	button.DoClick = function(button)
		button:setSelected(true)
	end
	if (isfunction(callback)) then
		button:onSelected(function()
			callback(self)
		end)
	end

	return button
end

function PANEL:createCharacterSelection()
	self.content:Clear()
	self.content:InvalidateLayout(true)
	self.content:Add("nutCharacterSelection")
end

function PANEL:createCharacterCreation()
	self.content:Clear()
	self.content:InvalidateLayout(true)
	self.content:Add("nutCharacterCreation")
end

function PANEL:fadeOut()
	self:AlphaTo(0, self.ANIM_SPEED, 0, function()
		self:Remove()
	end)
end

function PANEL:Init()
	if (IsValid(nut.gui.loading)) then
		nut.gui.loading:Remove()
	end

	if (IsValid(nut.gui.character)) then
		nut.gui.character:Remove()
	end
	nut.gui.character = self

	self:ParentToHUD()
	self:Dock(FILL)
	self:MakePopup()
	self:SetAlpha(0)
	self:AlphaTo(255, self.ANIM_SPEED * 2)

	self:createTitle()

	self.tabs = self:Add("DPanel")
	self.tabs:Dock(TOP)
	self.tabs:DockMargin(64, 32, 64, 0)
	self.tabs:SetTall(48)
	self.tabs:SetDrawBackground(false)
	
	self.content = self:Add("DPanel")
	self.content:Dock(FILL)
	self.content:DockMargin(64, 0, 64, 64)
	self.content:SetDrawBackground(false)

	self:createTabs()
end

function PANEL:setFadeToBlack(fade)
	local d = deferred.new()
	if (fade) then
		if (IsValid(self.fade)) then
			self.fade:Remove()
		end
		local fade = vgui.Create("DPanel")
		fade:SetSize(ScrW(), ScrH())
		fade:SetSkin("Default")
		fade:SetBackgroundColor(color_black)
		fade:SetAlpha(0)
		fade:AlphaTo(255, self.FADE_SPEED, 0, function() d:resolve() end)
		fade:SetZPos(999)
		self.fade = fade
	elseif (IsValid(self.fade)) then
		local fadePanel = self.fade
		fadePanel:AlphaTo(0, self.FADE_SPEED, 0, function()
			fadePanel:Remove()
			d:resolve()
		end)
	end
	return d
end

function PANEL:Paint(w, h)
	nut.util.drawBlur(self)
end

function PANEL:hoverSound()
	LocalPlayer():EmitSound("buttons/button15.wav", 30, 250)
end

function PANEL:clickSound()
	LocalPlayer():EmitSound("buttons/button14.wav", 30, 255)
end

function PANEL:warningSound()
	LocalPlayer():EmitSound("friends/friend_join.wav", 30, 255)
end

vgui.Register("nutCharacter", PANEL, "EditablePanel")

if (IsValid(nut.gui.character)) then
	vgui.Create("nutCharacter")
end
