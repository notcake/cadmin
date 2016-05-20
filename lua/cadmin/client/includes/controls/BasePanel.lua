local PANEL = {}

function PANEL:Init ()
	self.Padding = 5
end

function PANEL:Create (panelType, parent, targetname)
	if not parent then
		parent = self
	end
	return CAdmin.GUI.Create (panelType, parent, targetName)
end

function PANEL:GetPadding ()
	return self.Padding
end

function PANEL:SetPadding (padding)
	self.Padding = padding
end

function PANEL:SetPercentageHeight (percent)
	self:SetTall ((self:GetParent ():GetTall () - 2 * self:GetParent ():GetPadding ()) * percent / 100)
end

function PANEL:SetPercentageWidth (percent)
	self:SetWide ((self:GetParent ():GetWide () - 2 * self:GetParent ():GetPadding ()) * percent / 100)
end

CAdmin.GUI.Register ("CBasePanel", PANEL, "DPanel")