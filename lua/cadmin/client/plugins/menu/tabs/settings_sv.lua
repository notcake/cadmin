local TAB = TAB
TAB:SetName ("Server Settings")
TAB:SetIcon ("gui/silkicons/wrench")
TAB:SetTabPosition (5)
TAB:SetTooltip ("Manage server settings.")

function TAB:Init ()
	self:CreateChildPropertySheet ("client/plugins/menu/tabs/settings_sv")
end

function TAB:PerformLayout ()
	self:LayoutChildPropertySheet ()
end