local PANEL = {}

function PANEL:Init ()
	self.Depressed = false
	self.Disabled = false
	self.Hovered = false
	self.BackgroundColor = Color (255, 255, 255, 0)
	self.BackgroundColorHover = Color (255, 255, 255, 20)
	
	self:UpdateStyle ()
end

function PANEL:ApplySchemeSettings ()
	derma.SkinHook ("Scheme", "Button", self)
	self:UpdateStyle ()
end

function PANEL:GetBackgroundColor ()
	return self.BackgroundColor
end

function PANEL:GetHoverBackgroundColor ()
	return self.BackgroundColorHover
end

function PANEL:GetDisabled ()
	return self.Disabled
end

function PANEL:IsDown ()
	return self.Depressed
end

function PANEL:IsMouseOver ()
	return self.Hovered
end

function PANEL:OnCursorEntered ()
	self.Hovered = true
	self:UpdateStyle ()
end

function PANEL:OnCursorExited ()
	self.Hovered = false
	self:UpdateStyle ()
end

function PANEL:OnLeftClick ()
end

function PANEL:OnMousePressed (mcode)
	if self.Disabled then
		return
	end
        self:MouseCapture (true)
	self.Depressed = true
	self:UpdateStyle ()
end
	
function PANEL:OnMouseReleased (mcode)
	if not self:GetDisabled () then
		self:MouseCapture (false)
		if not self:IsDown () then
			return
		end
		self.Depressed = false
		self:UpdateStyle ()
		if not self.Hovered then
			return
		end
		if mcode == MOUSE_RIGHT then
			PCallError (self.DoRightClick, self)
			self:OnRightClick ()
		end
		if mcode == MOUSE_LEFT then
			PCallError (self.DoClick, self)
			self:OnLeftClick ()
		end
	end
end

function PANEL:OnRightClick ()
end

function PANEL:PerformLayout ()
	self:UpdateStyle ()
end

function PANEL:SetBackgroundColor (color)
	self.BackgroundColor = color
end

function PANEL:SetHoverBackgroundColor (color)
	self.BackgroundColorHover = color
end

function PANEL:SetDisabled (disabled)
	self.Disabled = disabled
	self:UpdateStyle ()
end

function PANEL:UpdateStyle ()
	if self:GetDisabled () then
		self:SetTextColor (Color (192, 192, 192, 255))
	else
		self:SetTextColor (Color (255, 255, 255, 255))
	end
end

CAdmin.GUI.Register ("CButton", PANEL, "DButton")