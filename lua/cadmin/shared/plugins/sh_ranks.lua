local PLUGIN = CAdmin.Plugins.Create ("Priveliges")
PLUGIN:SetAuthor ("!cake")
PLUGIN:SetDescription ("Provides commands for modifying user rights.")

function PLUGIN:Initialize ()
	local command = CAdmin.Commands.Create ("group_add", "Groups", "Add Group")
		:SetConsoleCommand ("addgroup")
		:SetLogString ("%Player% created the %arg0% group, which is derived from %arg1%.")
		:SetAssociatedType ("Group")
	command:AddArgument ("String", "group id")
		:SetPromptText ("Enter the ID of the new group:")
	command:AddArgument ("Group", "base group", function ()
		return CAdmin.Priveliges.GetDefaultGroup ()
	end)
		:SetPromptText ("Please select the base group:")
	command:SetExecute (function (ply, groupID, baseGroupID)
		CAdmin.Priveliges.CreateGroup (groupID, groupID, baseGroupID)
	end)
	
	if CLIENT then
		command = CAdmin.Commands.Create ("export_groups", "Groups Data", "Export Groups")
			:SetRunLocation (CAdmin.Commands.RUN_LOCAL)
			:SetAuthenticationRequired (false)
			:SetConsoleCommand ("exportgroups")
			:SetLogString ("%Player% exported the groups list to data/cadmin/exported_groups.txt.")
			:SetAssociatedType ("Group")
		command:SetExecute (function (ply)
			CAdmin.Priveliges.Save (false, true)
		end)
	end

	command = CAdmin.Commands.Create ("group_remove", "Groups", "Remove Group")
		:SetConsoleCommand ("removegroup")
		:SetLogString ("%Player% removed the %arg0% group.")
	command:AddArgument ("Group", "group")
		:SetPromptText ("Select the groups you want to remove:")
	command:SetExecute (function (ply, groupID)
		CAdmin.Priveliges.RemoveGroup (groupID)
	end)
	
	command = CAdmin.Commands.Create ("privelige_group_add", "Groups", "Add Privelige")
		:SetConsoleCommand ("groupallow")
		:SetLogString ("%Player% granted the privelige \"%arg1%\" to the group%s% %target%.")
	command:AddArgument ("Group", "group")
		:SetPromptText ("Select the group whose priveliges you want to change:")
	command:AddArgument ("String", "privelige")
		:SetPromptText ("Enter the privelige you want to grant:")
	command:SetExecute (function (ply, group, privelige)
		CAdmin.Priveliges.AddGroupPrivelige (group, privelige)
	end)

	command = CAdmin.Commands.Create ("privelige_group_remove", "Groups", "Remove Privelige")
		:SetConsoleCommand ("groupdeny")
		:SetLogString ("%Player% revoked the privelige \"%arg1%\" from the group%s% %target%.")
	command:AddArgument ("Group", "group")
		:SetPromptText ("Select the group whose priveliges you want to change:")
	command:AddArgument ("String", "privelige")
		:SetPromptText ("Enter the privelige you want to revoke:")
	command:SetExecute (function (ply, group, privelige)
		CAdmin.Priveliges.RemoveGroupPrivelige (group, privelige)
	end)
	
	command = CAdmin.Commands.Create ("rename_group", "Groups", "Set Group Name")
		:SetConsoleCommand ("renamegroup")
		:SetLogString ("%Player% renamed %target% to %arg1%.")
		:SetAssociatedType ("Group")
	command:AddArgument ("Group", "group")
		:SetPromptText ("Please select the group which you want to rename:")
	command:AddArgument ("String", "string")
		:SetPromptText ("Enter the group's new name:")
	command:SetExecute (function (ply, groupID, groupName)
		CAdmin.Priveliges.SetGroupName (groupID, groupName)
	end)
	
	command = CAdmin.Commands.Create ("set_group", "Groups", "Set Player Group")
		:SetConsoleCommand ("setgroup")
		:SetLogString ("%Player% moved %target% to group %arg1%.")
		:SetAssociatedType ("Group")
	command:AddArgument ("Player", "player")
		:SetPromptText ("Select for whom you want to change groups:")
	command:AddArgument ("Group", "group")
		:SetPromptText ("Please select a group:")
	command:SetExecute (function (ply, targply, groupID)
		CAdmin.Priveliges.SetPlayerGroup (targply, groupID)
	end)
end
