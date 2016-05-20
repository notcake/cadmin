--[[
	Derived from ToolMenuButton
]]
local PANEL = {}

function PANEL:Init ()
	self.Checkbox = nil
	self.CheckState = false
	self.CallbackFunction = nil

	self:SetContentAlignment (4)
	self:SetTall (18)
end

function PANEL:IsChecked ()
	return self.CheckState
end

function PANEL:OnLeftClick ()
	if self.Checkbox then
		self.CheckState = not self.CheckState
		self.Checkbox:SetValue (self.CheckState)
	else
		self:CallbackFunction ()
	end
end

function PANEL:SetCallback (callbackFunc)
	self.CallbackFunction = callbackFunc
end

function PANEL:Paint ()
	surface.SetDrawColor (self:GetBackgroundColor ())
	if self:IsMouseOver () and not self:GetDisabled () then
		surface.SetDrawColor (self:GetHoverBackgroundColor ())
	end
	self:DrawFilledRect ()
	return false
end

function PANEL:PerformLayout ()
	if self.Checkbox then
		self.Checkbox:AlignRight (4)
		self.Checkbox:CenterVertical ()
	end
end

function PANEL:SetChecked (checked)
	self.CheckState = checked
	if self.Checkbox then
		self.Checkbox:SetChecked (checked)
		if checked then
			self.Checkbox:SetType ("tick")
		else
			self.Checkbox:SetType ("none")
		end
	end
end

local function OnCheckboxChange (checkbox, newValue)
	checkbox.CommandButton.CheckState = newValue
	checkbox.CommandButton:CallbackFunction ()
end

function PANEL:SetShowCheckbox (checkbox)
	if checkbox and self.Checkbox then
		return
	end
	if not checkbox and not self.Checkbox then
		return
	end
	if checkbox then
		self.Checkbox = self:Create ("CCheckBox")
		self.Checkbox.CommandButton = self
		self.Checkbox:SetChecked (self.CheckState)
		self.Checkbox.OnChange = OnCheckboxChange
		self:SetDisabled (self:GetDisabled ())
	else
		self.Checkbox:Remove ()
		self.Checkbox = nil
	end
end

function PANEL:UpdateStyle ()
	if self.Checkbox then
		self.Checkbox:SetDisabled (self:GetDisabled ())
	end
	if self:IsDown () then
		self:SetTextInset (6)
	else
		self:SetTextInset (5)
	end
end

CAdmin.GUI.Register ("CCommandButton", PANEL, "CButton")