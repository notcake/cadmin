local TAB = TAB
TAB:SetName ("Wiremod")
TAB:SetIcon ("gui/silkicons/wrench.vmt")
TAB:SetTabPosition (1)
TAB:SetTooltip ("Wiremod Settings.")

function TAB:Init ()
	self.DisplayHologramOwners = self:Create ("DCheckBoxLabel")
	self.DisplayHologramOwners:SetText ("Show hologram owners")
	self.DisplayHologramOwners:SetTextColor (Color (64, 64, 64, 255))
	self.DisplayHologramOwners:SetConVar ("wire_holograms_display_owners")
end

function TAB:PerformLayout ()
	self.DisplayHologramOwners:SetPos (self:GetPadding (), self:GetPadding ())
	self.DisplayHologramOwners:SetPercentageWidth (100)
end