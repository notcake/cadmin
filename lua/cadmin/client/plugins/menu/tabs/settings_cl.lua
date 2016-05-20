local TAB = TAB
TAB:SetName ("Client Settings")
TAB:SetIcon ("gui/silkicons/wrench")
TAB:SetTabPosition (6)
TAB:SetTooltip ("Client settings.")

function TAB:Init ()
	self:CreateChildPropertySheet ("client/plugins/menu/tabs/settings_cl")
end

function TAB:PerformLayout ()
	self:LayoutChildPropertySheet ()
end