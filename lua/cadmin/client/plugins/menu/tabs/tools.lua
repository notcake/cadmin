local TAB = TAB
TAB:SetName ("Tools")
TAB:SetIcon ("gui/silkicons/wrench")
TAB:SetTabPosition (7)
TAB:SetTooltip ("Helpful things.")

function TAB:Init ()
	self:CreateChildPropertySheet ("client/plugins/menu/tabs/tools")
end

function TAB:PerformLayout (...)
	self:LayoutChildPropertySheet (...)
end