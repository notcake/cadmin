local PANEL = {}

function PANEL:Init ()
	self.SelectedIndex = 0
	self.Data = nil
end

function PANEL:AddChoice (text, data)
	self.Choices [#self.Choices + 1] = {
		Text = text,
		Data = data
	}
	return #self.Choices
end

function PANEL:ChooseOption (text, optionID)
	if self.Menu then
		self.Menu:Remove ()
		self.Menu = nil
	end
	self.SelectedIndex = optionID

	self:SetText (text)
	self.TextEntry:ConVarChanged (text)
	self:OnSelect (optionID, text, self.Choices [optionID].Data)
end

function PANEL:ChooseOptionID (optionID)
	self:ChooseOption (self.Choices [optionID].Text, optionID)
end

function PANEL:GetOptionText (optionID)
	return self.Choices [optionID].Text
end

function PANEL:GetSelectedData ()
	return self.Choices [self.SelectedIndex] and self.Choices [self.SelectedIndex].Data
end

function PANEL:GetSelectedText ()
	return self.Choices [self.SelectedIndex] and self.Choices [self.SelectedIndex].Text
end

local function MenuSelectOption (multiChoicePanel, optionID)
	multiChoicePanel:ChooseOptionID (optionID)
end

function PANEL:OpenMenu (pControlOpener)
	if pControlOpener then
		if pControlOpener == self.TextEntry then
			return
		end
	end

	if #self.Choices == 0 then
		return
	end

	if self.Menu then
		self.Menu:Remove ()
		self.Menu = nil
		return
	end

	self.Menu = CAdmin.GUI.CreateMenu ()
	for optionID, v in pairs (self.Choices) do
		self.Menu:AddOption (v.Text, MenuSelectOption, self, optionID)
	end
	
	local x, y = self:LocalToScreen (0, self:GetTall ())
	
	self.Menu:SetMinimumWidth (self:GetWide ())
	self.Menu:Open (x, y, false, self)
end

CAdmin.GUI.Register ("CMultiChoice", PANEL, "DMultiChoice")