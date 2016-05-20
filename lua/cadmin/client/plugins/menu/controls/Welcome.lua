local PANEL = {}

function PANEL:Init ()
	self.Padding = 5
	
	self:SetSize (ScrW () * 0.3, ScrH () * 0.2)
	self:Center ()
	self:SetDeleteOnClose (true)
	self:SetDraggable (false)
	self:SetSizable (false)
	self:MakePopup ()
	
	self:SetTitle ("Welcome to CAdmin")
	self:SetIcon ("gui/silkicons/world")
	
	self.OK = self:Create ("DButton")
	self.OK:SetText ("OK")
	self.OK:SetSize (64, 24)
	self.OK:SetPos ((self:GetWide () - self.OK:GetWide ()) / 2, self:GetTall () - self:GetPadding () - self.OK:GetTall ())
	self.OK.DoClick = function (button)
		self:Remove ()
	end
	
	self.Text = self:Create ("DLabel")
	local displayText = "Thank you for using CAdmin."
	if not CAdmin.Settings.Get ("Menu.Bound", false) then
		displayText = displayText .. "\n\nThe CAdmin menu is currently bound to \"0\".\nPlease bind cadmin_toggle or +cadmin to a key.\nThe bind on \"0\" will be removed when you use your new bind."
	end
	displayText = displayText .. "\n\nLogs are stored in data/cadmin/logs and data/cadmin/client_logs."
	self.Text:SetText (displayText)
	self.Text:SetPos (self:GetPadding (), 24 + self:GetPadding ())
	self.Text:SetSize (self:GetWide () - 2 * self:GetPadding (), self:GetTall () - 24 - 2 * self:GetPadding () - self.OK:GetTall ())
end

function PANEL:Uninit ()
	CAdmin.Settings.Set ("Menu.ShownWelcomeMessage", true)
end

CAdmin.GUI.Register ("CAdmin.WelcomeMessage", PANEL, "CFrame")