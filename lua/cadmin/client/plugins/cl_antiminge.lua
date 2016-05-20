local PLUGIN = CAdmin.Plugins.Create ("Anti Minge")
PLUGIN:SetAuthor ("!cake")
PLUGIN:SetDescription ("Commands to reduce effects of minges.")

local hiddenEntities = {
}
local hiddenEntityColors = {
}

function PLUGIN:Initialize ()
	local command = CAdmin.Commands.Create ("ent_hide", "Entities", "Hide Entity", true)
		:SetConsoleCommand ("ent_hide")
		:SetReverseConsoleCommand ("ent_unhide")
		:SetReverseDisplayName ("Show Entity")
		:SetLogString ("%Player% hid %target%.")
		:SetReverseLogString ("%Player% unhid %target%.")
		:SetAuthenticationRequired (false)
	command:AddArgument ("Entity")
		:SetPromptText ("Select the entities you want to hide:")
		:SetReversePromptText ("Select the entities you want to unhide:")
	command:SetExecute (function (ply, entity, hide)
		if hide then
			hiddenEntities [entity:EntIndex ()] = entity
			hiddenEntityColors [entity:EntIndex ()] = {entity:GetColor ()}
		else
			entity:SetColor (unpack (hiddenEntityColors [entity:EntIndex ()]))
			hiddenEntities [entity:EntIndex ()] = nil
			hiddenEntityColors [entity:EntIndex ()] = nil
		end
	end)
	command:SetGetToggleState (function (entity)
		return hiddenEntities [entity:EntIndex ()] == entity
	end)
	
	CAdmin.Timers.Create ("CAdmin.AntiMinge.HideProps", 1, 0, function ()
		for entityID, entity in pairs (hiddenEntities) do
			if entity:IsValid () then
				entity:SetColor (255, 255, 255, 0)
			else
				hiddenEntities [entityID] = nil
				hiddenEntityColors [entityID] = nil
			end
		end
	end)
end

function PLUGIN:Uninitialize ()
	for entityID, entity in pairs (hiddenEntities) do
		if entity:IsValid () then
			entity:SetColor (unpack (hiddenEntityColors [entityID]))
		end
		hiddenEntities [entityID] = nil
		hiddenEntityColors [entityID] = nil
	end
end