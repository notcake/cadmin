local TAB = TAB
TAB:SetName ("General")
TAB:SetIcon ("gui/silkicons/wrench.vmt")
TAB:SetTabPosition (1)
TAB:SetTooltip ("General Settings.")

function TAB:Init ()
	self.ShowFPS = self:Create ("DCheckBoxLabel")
	self.ShowFPS:SetText ("Show FPS")
	self.ShowFPS:SetTextColor (Color (64, 64, 64, 255))
	self.ShowFPS:SetCheckedValue (2)
	self.ShowFPS:SetConVar ("cl_showfps")
end

function TAB:PerformLayout ()
	self.ShowFPS:SetPos (self:GetPadding (), self:GetPadding ())
	self.ShowFPS:SetPercentageWidth (100)
end