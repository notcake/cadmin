local PANEL = {}

function PANEL:Init ()
	self.Text = self:Create ("DTextEntry")
	self.Text:SetEditable (true)
end

function PANEL:DoLayout ()
	if self:GetArgumentInfo ():HasFlag ("Multiline") then
		self.Text:SetEnterAllowed (true)
		self.Text:SetMultiline (true)
		self.Text:SetVerticalScrollbarEnabled (true)
	end
end

function PANEL:GetArgumentValue ()
	return self.Text:GetValue ()
end

function PANEL:PerformLayout ()
	local padding = self:GetPadding ()
	if self:GetArgumentInfo ():HasFlag ("Multiline") then
		self:SetSize (0.25 * ScrW (), 0.25 * ScrH ())
	else
		self:SetSize (0.25 * ScrW (), self.Text:GetTall () + 2 * padding)
	end
	self.Text:SetPos (padding, padding)
	self.Text:SetSize (self:GetWide () - 2 * padding, self:GetTall () - 2 * padding)
end

function PANEL:SetArgumentValue (text)
	self.Text:SetValue (text)
end

CAdmin.GUI.Register ("CAdmin.StringCompleter", PANEL, "CArgumentCompleter")