local PANEL = {}

function PANEL:Init ()
	self.ShowFrame = true
	
	self.TitleIcon = nil
end

function PANEL:Uninit ()
	if self.TitleIcon then
		self.TitleIcon:Remove ()
		self.TitleIcon = nil
	end
end

function PANEL:PerformLayout (...)
	DFrame.PerformLayout (self, ...)
	if not self.ShowFrame then
		self.lblTitle:SetVisible (false)
		self.btnClose:SetVisible (false)
	end
	if self.TitleIcon then
		self.TitleIcon:SetPos (self:GetPadding (), 3)
		self.lblTitle:SetPos (self.TitleIcon:GetWide () + 2 * self:GetPadding (), 2)
	end
end

function PANEL:RemoveIcon ()
	if self.TitleIcon then
		self.TitleIcon:Remove ()
		self.TitleIcon = nil
	end
end

function PANEL:SetIcon (icon)
	if not icon then
		self:RemoveIcon ()
		return
	end
	if not self.TitleIcon then
		self.TitleIcon = self:Create ("DImage")
		self:InvalidateLayout ()
	end
	self.TitleIcon:SetImage (icon)
	self.TitleIcon:SizeToContents ()
end

function PANEL:Unframe ()
	self.ShowFrame = false
	self.lblTitle:SetVisible (false)
	self.btnClose:SetVisible (false)
end

CAdmin.GUI.Register ("CFrame", PANEL, "DFrame")