local PANEL = {}

function PANEL:Init ()
	self.Button:Remove ()
	self.Button = self:Create ("CCheckBox")
	function self.Button.OnChange (button, value)
		self:OnChange (val)
	end
end

function PANEL:IsChecked ()
	return self.Button:IsChecked ()
end

function PANEL:SetCheckedValue (checkedValue)
	self.Button:SetCheckedValue (checkedValue)
end

function PANEL:SetConVar (convarName)
	self.Button:SetConVar (convarName)
end

function PANEL:SetUncheckedValue (uncheckedValue)
	self.Button:SetUncheckedValue (uncheckedValue)
end

function PANEL:SetValue (val)
	self.Button:SetValue (val)
end

CAdmin.GUI.Register ("CCheckBoxLabel", PANEL, "DCheckBoxLabel")