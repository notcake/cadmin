local PANEL = {}

function PANEL:Init ()
	self.Padding = 2
	self.StretchToFit = false

	self:SetDrawBackground (false)
	self:SetDrawBorder (false)
	self:SetStretchToFit (true)

	self.Image = self:Create ("DImage")
	
	self:SetText ("")
end

function PANEL:Uninit ()
	if self.Image then
		self.Image:Remove ()
		self.Image = nil
	end
end

function PANEL:GetIcon ()
	return self.Image:GetImage ()
end

function PANEL:GetImage ()
	return self.Image:GetImage ()
end

function PANEL:GetPadding ()
	return self.Padding
end

function PANEL:GetStretchToFit ()
	return self.StretchToFit
end

function PANEL:Paint ()
	if not self:GetDisabled () then
		local drawOutline = false
		local c1 = Color (255, 255, 255, 128)
		local c2 = Color (0, 0, 0, 128)
		if self:IsDown () then
			c1 = Color (0, 0, 0, 128)
			c2 = Color (255, 255, 255, 128)
		end
		if self:IsMouseOver () then
			drawOutline = true
			surface.SetDrawColor (c1.r, c1.g, c1.b, 16)
			surface.DrawRect (1, 1, self:GetWide () - 2, self:GetTall () - 2)
		end
		if drawOutline then
			surface.SetDrawColor (c1)
			surface.DrawLine (0, 0, self:GetWide (), 0)
			surface.DrawLine (0, 1, 0, self:GetTall ())
			surface.SetDrawColor (c2)
			surface.DrawLine (1, self:GetTall () - 1, self:GetWide (), self:GetTall () - 1)
			surface.DrawLine (self:GetWide () - 1, 1, self:GetWide () - 1, self:GetTall ())
		end
	end
end

function PANEL:PerformLayout ()
	self.Image:SetPos (self:GetPadding (), self:GetPadding ())
end

function PANEL:SetIcon (icon)
	self.Image:SetImage (icon)
end

function PANEL:SetImage (image)
	self.Image:SetImage (image)
end

function PANEL:SetKeepAspect (keepAspect)
	self.Image:SetKeepAspect (keepAspect)
end

function PANEL:SetOnViewMaterial (matName, backup)
	self.Image:SetOnViewMaterial (matName, backup)
end

function PANEL:SetStretchToFit (strechToFit)
	self.StretchToFit = strechToFit
end

function PANEL:SizeToContents ()
	self.Image:SizeToContents ()
	self:SetSize (self.Image:GetWide () + 2 * self:GetPadding (), self.Image:GetTall () + 2 * self:GetPadding ())
	self.Image:SetPos (self:GetPadding (), self:GetPadding ())
end

function PANEL:UpdateStyle ()
	if self:GetDisabled () then
		self.Image:SetImageColor (Color (200, 200, 200, 150))
	else
		self.Image:SetImageColor (Color (255, 255, 255, 255))
	end
	if self:IsDown () and self:IsMouseOver () and not self:GetDisabled () then
		self.Image:SetPos (self:GetPadding () + 1, self:GetPadding () + 1)
	else
		self.Image:SetPos (self:GetPadding (), self:GetPadding ())
	end
end

CAdmin.GUI.Register ("CToolbarButton", PANEL, "CButton")