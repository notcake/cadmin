local Priveliges = CAdmin.Priveliges

CAdmin.Datastream.RegisterServerToClientStream ("CAdmin.Priveliges.GroupData", function (ply, groupList, sendCore, sendPriveliges)
	groupList = groupList or Priveliges.GetGroupList ()
	if type (groupList) == "string" then
		groupList = {groupList}
	end
	local groupData = {}
	local group = nil
	for _, groupID in ipairs (groupList) do
		group = Priveliges.GetGroup (groupID)
		if group then
			local groupEntry = {
				Group = groupID,
				Allow = nil,
				Base = nil,
				Console = nil,
				Default = nil,
				Icon = nil,
				Name = nil
			}
			if sendPriveliges then
				groupEntry.Allow = group.Allow
			end
			if sendCore then
				if group.Console then
					groupEntry.Console = true
				end
				if group.Default then
					groupEntry.Default = true
				end
				if group.Icon then
					groupEntry.Icon = group.Icon
				end
				groupEntry.Base = group.Base
				groupEntry.Name = group.Name
			end
			groupData [#groupData + 1] = groupEntry
		else
			groupData [#groupData + 1] = {
				Group = groupID,
				Removed = true
			}
		end
	end
	return ply, groupData
end, function (ply, groupData)
	local addedGroups = {}
	local changedGroups = {}
	local removedGroups = {}
	for _, groupEntry in ipairs (groupData) do
		if groupEntry.Removed then
			removedGroups [#removedGroups + 1] = groupEntry.Group
		else
			local group = nil
			if not Priveliges.Groups [groupEntry.Group] then
				group = {}
				Priveliges.Groups [groupEntry.Group] = group
				addedGroups [#addedGroups + 1] = groupEntry.Group
			else
				group = Priveliges.Groups [groupEntry.Group]
				changedGroups [#changedGroups + 1] = groupEntry.Group
			end
			if groupEntry.Group == Priveliges.GetPlayerGroup (LocalPlayer ()) then
				CAdmin.Hooks.Call ("CAdminLocalPlayerPriveligesChanged")
			end
			group.Base = groupEntry.Base or group.Base
			group.Console = groupEntry.Console or group.Console or false
			group.Default = groupEntry.Default or group.Default or false
			group.Icon = groupEntry.Icon or group.Icon
			group.Name = groupEntry.Name or group.Name
			
			if groupEntry.Console then
				Priveliges.SetConsoleGroup (groupEntry.Group)
			end
			if groupEntry.Default then
				Priveliges.SetDefaultGroup (groupEntry.Group)
			end
			
			if groupEntry.Allow then
				group.Allow = groupEntry.Allow
				CAdmin.Hooks.Call ("CAdminGroupPriveligesChanged", groupEntry.Group)
			end
		end
	end
	if #addedGroups > 0 then
		CAdmin.Hooks.Call ("CAdminGroupAdded", addedGroups)
	end
	if #changedGroups > 0 then
		CAdmin.Hooks.Call ("CAdminGroupDataChanged", changedGroups)
	end
	Priveliges.RemoveGroup (removedGroups)
end)