local PANEL = {}

function PANEL:Init ()
	self.NumberSlider = self:Create ("DNumSlider")
	self:SetWide (0.25 * ScrW ())
end

function PANEL:DoLayout ()
	self.NumberSlider:SetText (self:GetArgumentInfo ():GetName ())
	local minimum = tonumber (self:GetArgumentInfo ():GetParameter ("Minimum"))
	local maximum = tonumber (self:GetArgumentInfo ():GetParameter ("Maximum"))
	local value = 0
	if minimum then
		self.NumberSlider:SetMin (minimum)
		if value < minimum then
			value = minimum
		end
	end
	if maximum then
		self.NumberSlider:SetMax (maximum)
		if value > maximum then
			value = maximum
		end
	end
	self.NumberSlider:SetValue (value)
end

function PANEL:GetArgumentValue ()
	return self.NumberSlider:GetValue ()
end

function PANEL:PerformLayout ()
	local padding = self:GetPadding ()
	self.NumberSlider:SetPos (padding, padding)
	self.NumberSlider:SetWide (self:GetWide () - 2 * padding)
	
	self:SetSize (self.NumberSlider:GetWide () + 2 * padding, self.NumberSlider:GetTall () + 2 * padding)
end

function PANEL:SetArgumentValue (number)
	self.NumberSlider:SetValue (number)
end

CAdmin.GUI.Register ("CAdmin.NumberCompleter", PANEL, "CArgumentCompleter")