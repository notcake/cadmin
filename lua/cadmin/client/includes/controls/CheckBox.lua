local PANEL = {}

function PANEL:Init ()
	self.CheckState = 0
	
	self.CheckedValue = 1
	self.UncheckedValue = 0
	self.ConsoleCommand = nil
end

function PANEL:IsChecked ()
	if self.CheckState > 0 then
		return true
	end
	return false
end

function PANEL:Paint ()
	local w, h = self:GetSize ()
	if self:GetDisabled () then
		surface.SetDrawColor (172, 172, 172, 255)
	else
		surface.SetDrawColor (255, 255, 255, 255)
	end
	surface.DrawRect (1, 1, w - 2, h - 2)
	if self:GetDisabled () then
		surface.SetDrawColor (64, 64, 64, 255)
	else
		surface.SetDrawColor (30, 30, 30, 255)
	end
	surface.DrawRect (1, 0, w - 2, 1)
	surface.DrawRect (1, h - 1, w - 2, 1)
	surface.DrawRect (0, 1, 1, h - 2)
	surface.DrawRect (w - 1, 1, 1, h - 2)
	surface.DrawRect (1, 1, 1, 1)
	surface.DrawRect (w - 2, 1, 1, 1)
	surface.DrawRect (1, h-2, 1, 1)
	surface.DrawRect (w - 2, h - 2, 1, 1)
	return false
end

function PANEL:SetCheckedValue (checkedValue)
	self.CheckedValue = checkedValue
end

function PANEL:SetConVar (convarName)
	self.m_strConVar = convarName
end

function PANEL:SetUncheckedValue (uncheckedValue)
	self.UncheckedValue = uncheckedValue
end

function PANEL:SetValue (val)
	val = tobool (val)
	self:SetChecked (val)
	if not val then
		self:SetType ("none")
	else
		self:SetType ("tick")
	end
	self.m_bValue = val
	self:OnChange (val)

	if val then
		val = tostring (self.CheckedValue)
	else
		val = tostring (self.UncheckedValue)
	end   
	self:ConVarChanged (val)
end

CAdmin.GUI.Register ("CCheckBox", PANEL, "DCheckBox")