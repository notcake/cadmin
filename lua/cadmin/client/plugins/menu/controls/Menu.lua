local PANEL = {}

function PANEL:Init ()
	self:Unframe ()

	self.Padding = 5
	
	self:SetSize (ScrW () * 0.6, ScrH () * 0.6)
	self:SetDeleteOnClose (false)
	self:SetDraggable (false)
	self:SetSizable (true)

	self.PropertySheet = self:Create ("DPropertySheet")
	self.PropertySheet:SetTabClass ("Menu Tab")
	self.PropertySheet:SetPos (self.Padding, 24 + self.Padding)
	self.PropertySheet:SetSize (self:GetWide () - 2 * self.Padding, self:GetTall () - 24 - 2 * self.Padding)

	self.OldSetVisible = self.SetVisible
	function self:SetVisible (vis)
		self:OldSetVisible (vis)
		if vis then
			self:SetPos ((ScrW () - self:GetWide ()) / 2, (ScrH () - self:GetTall ()) / 2)
			gui.EnableScreenClicker (true)
		else
			self.Plugin.MenuVisible = false
			gui.EnableScreenClicker (false)
		end
	end
	self:SetVisible (false)
end

function PANEL:GetPropertySheet ()
	return self.PropertySheet
end

function PANEL:Paint ()
end

CAdmin.GUI.Register ("CAdmin.Menu", PANEL, "CFrame")