local TYPE = CAdmin.Commands.RegisterType ("Group")
TYPE:SetCompleter ("CAdmin.GroupCompleter")

TYPE:SetAutocomplete (function (groupName)
	groupName = groupName:lower ()
	if groupName == "*" then
		groupName = ""
	end
	local groups = {}
	for groupID, _ in pairs (CAdmin.Priveliges.GetGroups ()) do
		if groupID:lower ():find (groupName, 1, true) or CAdmin.Priveliges.GetGroupName (groupID):lower ():find (groupName, 1, true) then
			table.insert (groups, groupID)
		end
	end
	return groups
end)

TYPE:RegisterConverter ("String", function (ply, groupName)
	if CAdmin.Priveliges.GetGroup (groupName) then
		return groupName
	end
	return nil
end)