--[[
	Provides functions for managing player access rights.
	
	Files:
		data/cadmin/groups.txt
		data/cadmin/users.txt
		
	Datastreams:
		CAdmin.Priveliges.GroupData:
			Sends an array of tables in the form:
			{
				Group	- group ID.
				
				[Optional]
				Allow	- group priveliges.
				Base	- base group ID.
				Console	- whether the server console is considered to be in this group.
				Default	- whether players are assigned to this group by default.
				Icon	- group icon.
				Name	- group name.
				Removed	- whether the group was removed.
			}
			
		CAdmin.Priveliges.GroupPriveligeData:	-- For changes in group priveliges
			Sends a table of the form:
			{
				[GroupID]	= {
					Added	= {					-- Optional
						[PriveligeName] = true
					}
					Removed	= {					-- Optional
						[PriveligeName] = true
					}
				}
			}
			
		CAdmin.Priveliges.PlayerData:
			Sends an array of tables in the form:
			{
				SteamID	- steam ID.
				Player	- player entity.
				
				[Optional]
				Group	- player group.
				Allow	- player-specific priveliges.
			}
			Either SteamID or Player will be present, depending on whether the player is online.
			The player entity is sent to accomodate bots.	
			
		CAdmin.Priveliges.PlayerPriveligeData:	-- For changes in player priveliges
			Sends a table of the form:
			{
				[SteamID] = {
					Player	- player entity.		-- Not present for offline players
					Name	- player name.
				
					Added	= {
						[PriveligeName] = true
					}
					Removed	= {
						[PriveligeName] = true
					}
				}
			}
	Hooks:
		CAdminGroupAdded (groupList):
			Called when new groups are registered.
			groupList is an array of group IDs.
		CAdminGroupDataChanged (groupList):
			Called when a group's name, icon or base group is changed.
		CAdminGroupPriveligesChanged (groupID):
			Called when a group's rights changes.
		CAdminGroupRemoved (groupList):
			Called when groups are removed.
			groupList is an array of group IDs.
		CAdminLocalPlayerPriveligesChanged:
			Called on the client when the local player's priveliges have changed.
		CAdminPlayerGroupChanged (playerList):
			Called when player groups change.
			playerList is an array of tables of the form:
			{
				SteamID			- steam ID.
				Name			- player name.
				Player			- player entity.
				LastGroup		- last group ID.
				CurrentGroup	- current group ID.
			}
			If players are offline, Player will be nil.
		CAdminPlayerPriveligesChanged (steamID, playerName, playerEntity):
			Called when player priveliges change.
			steamID is the player's steam ID.
			playerName is the player's display name.
			playerEntity is the player's in-game entity (if present).
			If the player is offline, playerEntity will be nil.
]]
CAdmin.RequireInclude ("sh_hooks")

CAdmin.Priveliges = CAdmin.Priveliges or {}
local Priveliges = CAdmin.Priveliges
Priveliges.DefaultGroup = nil
Priveliges.ConsoleGroup = nil
Priveliges.Groups = {}
Priveliges.Players = {}
Priveliges.Unsaved = false

if SERVER then
	Priveliges.NetworkBuffer = {}
end
local NetworkBuffer = Priveliges.NetworkBuffer
if SERVER then
	NetworkBuffer.GroupPriveligeData = {}
	NetworkBuffer.PlayerPriveligeData = {}
end

local function UpdatePlayerName (ply, steamid)
	if not ply then
		return
	end
	local entry = Priveliges.Players [steamid]
	if entry and entry.Name ~= ply:Name () then
		Priveliges.Unsaved = true
		entry.Name = ply:Name ()
	end
end

function Priveliges.CullPlayerList ()
	for steamID, playerEntry in pairs (Priveliges.Players) do
		local canRemove = true
		if playerEntry.Group and playerEntry.Group ~= Priveliges.GetDefaultGroup () then
			canRemove = false
		end
		if playerEntry.Allow and not CAdmin.Util.IsTableEmpty (playerEntry.Allow) then
			canRemove = false
		end
		if canRemove then
			Priveliges.Players [steamID] = nil
		end
	end
end

function Priveliges.AddGroupPrivelige (groupID, priveligeName)
	groupID = groupID:lower ()
	local group = Priveliges.Groups [groupID]
	if not group then
		return
	end
	if group.Allow [priveligeName] then
		return
	end
	Priveliges.Unsaved = true
	group.Allow [priveligeName] = true
	
	-- Network changes
	if SERVER then
		local groupEntry = NetworkBuffer.GroupPriveligeData [groupID]
		if not groupEntrys then
			groupEntry = {
				Added = {}
			}
			NetworkBuffer.GroupPriveligeData [groupID] = groupEntry
		end
		if not groupEntry.Added then
			groupEntry.Added = {}
		end
		groupEntry.Added [priveligeName] = true
		if groupEntry.Removed then
			groupEntry.Removed [priveligeName] = nil
		end
	end
	
	CAdmin.Hooks.QueueCall ("CAdminGroupPriveligesChanged", groupID)
end

function Priveliges.CreateGroup (groupID, groupName, baseGroupID)
	groupID = groupID:lower ()
	if not baseGroupID or not Priveliges.Groups [baseGroupID] then
		baseGroupID = Priveliges.DefaultGroup
	end
	if Priveliges.Groups [groupID] then
		return
	end
	Priveliges.Groups [groupID] = CAdmin.Objects.Create ("Group", groupID, groupName, baseGroupID)
	CAdmin.Hooks.Call ("CAdminGroupAdded", {groupID})
	if SERVER then
		CAdmin.Datastream.SendStream ("CAdmin.Priveliges.GroupData", CAdmin.Players.GetCAdminPlayers (), groupID, true, false)
	end
end

function Priveliges.FixupPriveligeList (priveligeList)
	if not priveligeList then
		return nil
	end
	local fixedPriveligeList = {}
	for priveligeName, priveligeParameters in pairs (priveligeList) do
		if tonumber (priveligeName) then
			fixedPriveligeList [priveligeParameters:lower ()] = true
		else
			fixedPriveligeList [priveligeName:lower ()] = priveligeParameters:lower ()
		end
		priveligeList [priveligeName] = nil
	end

	for priveligeName, priveligeParameters in pairs (fixedPriveligeList) do
		local parts = string.Explode (" ", priveligeName)
		local startMergeOffset = 2
		if parts [1] == "ulx" and parts [2] then
			parts [1] = parts [1] .. " " .. parts [2]
			startMergeOffset = 3
		end
		if parts [startMergeOffset] then
			for i = startMergeOffset, #parts do
				if i > startMergeOffset then
					parts [startMergeOffset] = parts [startMergeOffset] .. " " .. parts [i]
					parts [i] = nil
				end
			end
		else
			parts [startMergeOffset] = true
		end
		if priveligeParameters == true then
			priveligeList [parts [1]] = parts [startMergeOffset]
		else
			if parts [startMergeOffset] == true then
				priveligeList [parts [1]] = priveligeParameters
			else
				priveligeList [parts [1]] = parts [startMergeOffset] .. " " .. priveligeParameters
			end
		end
	end
	fixedPriveligeList = nil
	return priveligeList
end

function Priveliges.GetBaseGroup (groupID)
	local groupInfo = Priveliges.GetGroup (groupID)
	if groupInfo then
		return groupInfo.Base
	end
	return nil
end

function Priveliges.GetConsoleGroup ()
	return Priveliges.ConsoleGroup
end

function Priveliges.GetDefaultGroup ()
	local group = nil
	if not CAdmin.IsServerRunning () and CAdmin.Fallbacks.FallbackExists ("CAdmin.Priveliges.GetDefaultGroup") then
		if CAdmin.Fallbacks.GetFallbackCallCount ("CAdmin.Priveliges.GetDefaultGroup") == 0 then
			group = CAdmin.Fallbacks.Call ("CAdmin.Priveliges.GetDefaultGroup", 1)
			if group then
				Priveliges.DefaultGroup = group
				return group
			end
		end
	end
	if not group then
		group = Priveliges.DefaultGroup
	end
	return group or "user"
end

function Priveliges.GetGroup (group)
	return Priveliges.GetGroups () [group]
end

function Priveliges.GetGroupIcon (groupID)
	local icon = "icon16/user.png"
	if groupID == "admin" or groupID == "superadmin" then
		icon = "icon16/shield.png"
	end
	
	while groupID do
		local groupInfo = Priveliges.GetGroup (groupID)
		if groupInfo and groupInfo.Icon then
			return groupInfo.Icon
		end
		groupID = groupInfo and groupInfo.Base
	end
	
	return icon
end

function Priveliges.GetGroupList ()
	local groups = Priveliges.GetGroups ()
	local groupList = {}
	for groupID, _ in pairs (groups) do
		groupList [#groupList + 1] = groupID
	end
	return groupList
end

function Priveliges.GetGroupName (groupID)
	local groupInfo = Priveliges.GetGroup (groupID)
	if groupInfo and groupInfo.Name then
		return groupInfo.Name
	end
	return groupID
end

function Priveliges.GetGroupPriveliges (groupID)
	local groupInfo = Priveliges.GetGroup (groupID)
	if groupInfo and groupInfo.Allow then
		return groupInfo.Allow
	end
	return {}
end

function Priveliges.GetGroups ()
	local groups = nil
	if not CAdmin.IsServerRunning () and CAdmin.Fallbacks.FallbackExists ("CAdmin.Priveliges.GetGroups") then
		if CAdmin.Fallbacks.GetFallbackCallCount ("CAdmin.Priveliges.GetGroups") == 0 then
			groups = CAdmin.Fallbacks.Call ("CAdmin.Priveliges.GetGroups", 1)
			if groups then
				for groupID, group in pairs (groups) do
					Priveliges.Groups [groupID] = group
					group.Allow = Priveliges.FixupPriveligeList (group.Allow)
				end
			end
		end
	end
	if not groups then
		groups = Priveliges.Groups
	end
	return groups
end

function Priveliges.GetGroupUserGroup (groupID)
	while groupID do
		local groupInfo = Priveliges.GetGroup (groupID)
		if groupInfo and groupInfo.UserGroup then
			return groupInfo.UserGroup
		end
		groupID = groupInfo and groupInfo.Base
	end
	if groupID == "admin" then
		return "admin"
	elseif groupID == "superadmin" then
		return "superadmin"
	end
	return "guest"
end

function Priveliges.GetPlayerGroup (ply)
	local steamID = ply:SteamID ()
	if CLIENT then
		if Priveliges.Players ["STEAM_0:0:0"] then
			steamID = "STEAM_0:0:0"
		end
	end
	if CAdmin.IsServerRunning () then
		if SERVER then
			if ply:IsListenServerHost () and
				not Priveliges.Players [steamID] then
				Priveliges.SetPlayerGroup (ply, Priveliges.ConsoleGroup)
			end
		end
		if Priveliges.Players [steamID] then
			return Priveliges.Players [steamID].Group
		end
	else
		if Priveliges.Players [steamID] and Priveliges.Players [steamID].Group then
			return Priveliges.Players [steamID].Group
		end
		if CAdmin.Fallbacks.FallbackExists ("CAdmin.Priveliges.GetPlayerGroup") then
			local group = CAdmin.Fallbacks.Call ("CAdmin.Priveliges.GetPlayerGroup", 1, ply)
			if group then
				if group ~= Priveliges.GetDefaultGroup () then
					Priveliges.SetPlayerGroup (ply, group)
				end
				return group
			end
		end
	end
	if ply:IsUserGroup ("admin") then
		return "admin"
	elseif ply:IsUserGroup ("superadmin") then
		return "superadmin"
	end
	return Priveliges.GetDefaultGroup ()
end

function Priveliges.GetPlayerGroupIcon (ply)
	local groupIcon = Priveliges.GetGroupIcon (Priveliges.GetPlayerGroup (ply))
	if groupIcon then
		return groupIcon
	end
	if ply:IsAdmin () then
		return "icon16/shield.png"
	end
	return "icon16/user.png"
end

function Priveliges.GetPlayerGroupName (ply)
	local groupID = Priveliges.GetPlayerGroup (ply)
	return Priveliges.GetGroupName (groupID)
end

function Priveliges.GetPlayerPriveliges (ply)
	if Priveliges.Players [ply:SteamID ()] then
		return Priveliges.Players [ply:SteamID ()].Allow
	end
	return {}
end

function Priveliges.IsPlayerAuthorized (ply, privelige, ...)
	if not ply then
		CAdmin.Debug.PrintStackTrace ()
		return false, "CAdmin: IsPlayerAuthorized called with an invalid player."
	end
	if not ply:IsValid () then
		if CAdmin.Players.IsConsole (ply) then
			return true
		end
		CAdmin.Debug.PrintStackTrace ()
		return false, "CAdmin: IsPlayerAuthorized called with an invalid player."
	end
	if not privelige then
		CAdmin.Debug.PrintStackTrace ()
		return false, "No privelige specified."
	end
	privelige = privelige:lower ()
	local plyAllow = Priveliges.GetPlayerPriveliges (ply)
	if plyAllow and Priveliges.IsPriveligePresent (plyAllow, privelige, ...) then
		return true
	end
	local group = Priveliges.GetPlayerGroup (ply)
	while group do
		if Priveliges.IsPriveligePresent (Priveliges.GetGroupPriveliges (group), privelige, ...) then
			return true
		end
		group = Priveliges.GetBaseGroup (group)
	end
	return false
end

--[[
	Checks if a privelige is present in a list.
]]
function Priveliges.IsPriveligePresent (list, privelige, ...)
	if not list then
		print ("IsPriveligePresent called with a nil table!")
		CAdmin.Debug.PrintStackTrace ()
		return false
	end
	if list [privelige] then
		return true
	end
	return false
end

function Priveliges.Load ()
	if CLIENT then
		return
	end
	if file.Exists ("cadmin/groups.txt") then
		local addedGroups = {}
		local groupList = util.KeyValuesToTable ("\"Groups\" {\r\n" .. file.Read ("cadmin/groups.txt") .. "}\r\n")
		for groupID, groupData in pairs (groupList) do
			groupID = groupID:lower ()
			addedGroups [#addedGroups + 1] = groupID
			local groupEntry = {
				Allow = groupData.allow,
				Base = groupData.base,
				Console = tobool (groupData.console),
				Default = tobool (groupData.default),
				Icon = groupData.icon,
				Name = groupData.name or groupID,
				UserGroup = groupData.usergroup
			}
			Priveliges.Groups [groupID] = groupEntry
			if groupEntry.Base then
				groupEntry.Base = groupEntry.Base:lower ()
			end
			if groupEntry.Console then
				Priveliges.ConsoleGroup = groupID
			end
			if groupEntry.Default then
				Priveliges.DefaultGroup = groupID
			end
			groupEntry.Allow = Priveliges.FixupPriveligeList (groupEntry.Allow)
		end
		if #addedGroups > 0 then
			CAdmin.Hooks.Call ("CAdminGroupAdded", addedGroups)
		end
	end

	if file.Exists ("cadmin/users.txt") then
		local addedPlayers = {}
		local playerList = util.KeyValuesToTable ("\"Users\" {\r\n" .. file.Read ("cadmin/users.txt") .. "}\r\n")
		for steamID, playerData in pairs (playerList) do
			local playerEntry = {
				Allow = playerData.allow,
				Group = playerData.group,
				Name = playerData.name
			}
			addedPlayers [#addedPlayers + 1] = {
				SteamID = steamID,
				Name = playerData.name,
				LastGroup = Priveliges.GetDefaultGroup (),
				CurrentGroup = playerData.group
			}
			Priveliges.Players [steamID:upper ()] = playerEntry
			if playerEntry.Group then
				playerEntry.Group = playerEntry.Group:lower ()
			end
			playerEntry.Allow = Priveliges.FixupPriveligeList (playerEntry.Allow)
		end
		if #addedPlayers > 0 then
			CAdmin.Hooks.Call ("CAdminPlayerGroupChanged", addedPlayers)
		end
	end
end

function Priveliges.RemoveGroup (groupList)
	if type (groupList) == "string" then
		groupList = {groupList}
	end
	local removedGroups = {}
	for _, groupID in ipairs (groupList) do
		if Priveliges.Groups [groupID] then
			removedGroups [#removedGroups + 1] = groupID
			local baseGroupID = Priveliges.Groups [groupID].Base
			Priveliges.Groups [groupID] = nil
			if CLIENT and Priveliges.GetPlayerGroup (LocalPlayer ()) == groupID then
				Priveliges.SetPlayerGroup (LocalPlayer (), baseGroupID)
			end
		end
	end
	if #removedGroups > 0 then
		CAdmin.Hooks.Call ("CAdminGroupRemoved", removedGroups)
	end
	if SERVER then
		CAdmin.Datastream.SendStream ("CAdmin.Priveliges.GroupData", CAdmin.Players.GetCAdminPlayers (), removedGroups)
	end
end

function Priveliges.RemoveGroupPrivelige (groupID, priveligeName)
	groupID = groupID:lower ()
	local group = Priveliges.Groups [groupID]
	if not group then
		return
	end
	if not group.Allow [priveligeName] then
		return
	end
	Priveliges.Unsaved = true
	group.Allow [priveligeName] = nil
	
	-- Network changes
	if SERVER then
		local groupEntry = NetworkBuffer.GroupPriveligeData [groupID]
		if not groupEntrys then
			groupEntry = {
				Added = {}
			}
			NetworkBuffer.GroupPriveligeData [groupID] = groupEntry
		end
		if not groupEntry.Removed then
			groupEntry.Removed = {}
		end
		groupEntry.Removed [priveligeName] = true
		if groupEntry.Added then
			groupEntry.Added [priveligeName] = nil
		end
	end
	
	CAdmin.Hooks.QueueCall ("CAdminGroupPriveligesChanged", groupID)
end

function Priveliges.SetConsoleGroup (groupID)
	Priveliges.ConsoleGroup = groupID
end

function Priveliges.SetDefaultGroup (groupID)
	Priveliges.DefaultGroup = groupID
end

function Priveliges.SetGroupName (groupID, groupName)
	if Priveliges.Groups [groupID].Name ~= groupName then
		Priveliges.Groups [groupID].Name = groupName
		CAdmin.Hooks.Call ("CAdminGroupDataChanged", {groupID})
		if SERVER then
			CAdmin.Datastream.SendStream ("CAdmin.Priveliges.GroupData", CAdmin.Players.GetCAdminPlayers (), groupID, true, false)
		end
	end
end

function Priveliges.SetPlayerGroup (ply, groupID)
	local steamID = nil
	local playerEntity = nil
	if type (ply) == "Player" then
		steamID = ply:SteamID ()
		playerEntity = ply
	elseif type (ply) == "string" then
		steamID = ply
	end
	if not steamID then
		return
	end
	local playerEntry = Priveliges.Players [steamID]
	if not playerEntry then
		playerEntry = {}
		Priveliges.Players [steamID] = playerEntry
	end
	UpdatePlayerName (playerEntity, steamID)
	if playerEntry.Group ~= groupID then
		local oldGroupID = playerEntry.Group
		playerEntry.Group = groupID
		CAdmin.Hooks.Call ("CAdminPlayerGroupChanged", {
			{
				SteamID = steamID,
				Name = playerEntry.Name,
				Player = playerEntity,
				LastGroup = oldGroupID,
				CurrentGroup = groupID
			}
		})
		if SERVER then
			CAdmin.Datastream.SendStream ("CAdmin.Priveliges.PlayerData", CAdmin.Players.GetPlayers (), ply, true, false, true, false)
		end
		if CLIENT and playerEntity == LocalPlayer () then
			CAdmin.Hooks.Call ("CAdminLocalPlayerPriveligesChanged")
		end
		Priveliges.Unsaved = true
	end
end

function Priveliges.SetPlayerPriveliges (steamID, priveligeList)
	local steamID = nil
	local playerEntity = nil
	if type (ply) == "Player" then
		steamID = ply:SteamID ()
		playerEntity = ply
	elseif type (ply) == "string" then
		steamID = ply
	end
	if not steamID then
		return
	end
	local playerEntry = Priveliges.Players [steamID]
	if not playerEntry then
		playerEntry = {}
		Priveliges.Players [steamID] = playerEntry
	end
	UpdatePlayerName (playerEntity, steamID)
	local oldPriveligesBlank = CAdmin.Util.IsTableEmpty (playerEntry.Allow)
	local newPriveligesBlank = CAdmin.Util.IsTableEmpty (priveligeList)
	playerEntry.Allow = priveligeList
	if not oldPriveligesBlank or not newPriveligesBlank then
		CAdmin.Hooks.Call ("CAdminPlayerPriveligesChanged", steamID, playerEntry.Name, playerEntity)
		if CLIENT then
			if playerEntity == LocalPlayer () then
				CAdmin.Hooks.Call ("CAdminLocalPlayerPriveligesChanged")
			end
		end
		if SERVER then
			CAdmin.Datastream.SendStream ("CAdmin.Priveliges.PlayerData", CAdmin.Players.GetPlayers (), steamID, true, true, false, true)
		end
		Priveliges.Unsaved = true
	end
end

function Priveliges.Save (skipGroups, skipPlayers)
	Priveliges.CullPlayerList ()
	local pathPrefix = "cadmin/"
	if CLIENT then
		pathPrefix = "cadmin/exported_"
	end
	if not skipGroups then
		local groupString = ""
		for groupID, group in pairs (Priveliges.Groups) do
			groupString = groupString .. "\"" .. groupID:lower () .. "\"\n{\n"
			groupString = groupString .. "\t\"allow\"\n\t{\n"
			local priveligeCount = 1
			for priveligeName, priveligeParameters in pairs (group.Allow) do
				priveligeName = priveligeName:lower ()
				if priveligeParameters ~= true then
					priveligeName = priveligeName .. " " .. priveligeParameters
				end
				groupString = groupString .. "\t\t\"" .. tostring (priveligeCount) .. "\"\t\"" .. priveligeName .. "\"\n"
				priveligeCount = priveligeCount + 1
			end
			groupString = groupString .. "\t}\n"
			if group.Base then
				groupString = groupString .. "\t\"base\"\t\"" .. group.Base .. "\"\n"
			end
			if group.Console then
				groupString = groupString .. "\t\"console\"\t\"1\"\n"
			end
			if group.Default then
				groupString = groupString .. "\t\"default\"\t\"1\"\n"
			end
			if group.Icon then
				groupString = groupString .. "\t\"icon\"\t\"" .. group.Icon .. "\"\n"
			end
			if group.Name then
				groupString = groupString .. "\t\"name\"\t\"" .. group.Name .. "\"\n"
			end
			if group.UserGroup then
				groupString = groupString .. "\t\"usergroup\"\t\"" .. group.UserGroup .. "\"\n"
			end
			groupString = groupString .. "}\n\n"
		end
		file.Write (pathPrefix .. "groups.txt", groupString)
	end
	if not skipPlayers then
		local playerString = ""
		for steamID, playerEntry in pairs (Priveliges.Players) do
			if steamID ~= "STEAM_0:0:0" then
				playerString = playerString .. "\"" .. steamID .. "\"\n{\n"
				playerString = playerString .. "\t\"allow\"\n\t{\n"
				local priveligeCount = 1
				for priveligeName, priveligeParameters in pairs (playerEntry.Allow or {}) do
					priveligeName = priveligeName:lower ()
					if priveligeParameters ~= true then
						priveligeName = priveligeName .. " " .. priveligeParameters
					end
					playerString = playerString .. "\t\t\"" .. tostring (priveligeCount) .. "\"\t\"" .. priveligeName .. "\"\n"
					priveligeCount = priveligeCount + 1
				end
				playerString = playerString .. "\t}\n"
				if playerEntry.Name then
					playerString = playerString .. "\t\"name\"\t\"" .. playerEntry.Name .. "\"\n"
				end
				if playerEntry.Group then
					playerString = playerString .. "\t\"group\"\t\"" .. playerEntry.Group:lower () .. "\"\n"
				end
				playerString = playerString .. "}\n\n"
			end
		end
		file.Write (pathPrefix .. "users.txt", playerString)
	end
	Priveliges.Unsaved = false
	return pathPrefix .. "groups.txt", pathPrefix .. "users.txt"
end

CAdmin.Hooks.Add ("CAdminInitialize", "CAdmin.Priveliges.Initialize", function ()
	Priveliges.Load ()

	if SERVER then
		CAdmin.Hooks.Add ("CAdminPlayerConnected", "CAdmin.Priveliges.PlayerConnected", function (steamID, uniqueID, playerName, ply)
			UpdatePlayerName (ply, steamID)
			ply:SetUserGroup (Priveliges.GetGroupUserGroup (Priveliges.GetPlayerGroup (ply)))
		end)
		CAdmin.Hooks.Add ("CAdminPlayerNameChanged", "CAdmin.Priveliges.PlayerNameChanged", function (steamID, uniqueID, ply, playerName)
			UpdatePlayerName (ply, steamID)
		end)
		CAdmin.Hooks.Add ("CAdminPlayerCAdminInitialized", "CAdmin.Priveliges.PlayerCAdminInitialized", function (steamID, uniqueID, playerName, ply)
			CAdmin.Datastream.SendStream ("CAdmin.Priveliges.GroupData", ply, nil, true, true)
			CAdmin.Datastream.SendStream ("CAdmin.Priveliges.PlayerData", ply, CAdmin.Players.GetPlayers (), true, false, true, true)
		end)
		CAdmin.Hooks.Add ("Tick", "CAdmin.Priveliges.SendPriveligeDelta", function ()
			if not CAdmin.Util.IsTableEmpty (NetworkBuffer.GroupPriveligeData) then
				CAdmin.Datastream.SendStream ("CAdmin.Priveliges.GroupPriveligeData", CAdmin.Players.GetPlayers ())
			end
			if not CAdmin.Util.IsTableEmpty (NetworkBuffer.PlayerPriveligeData) then
				CAdmin.Datastream.SendStream ("CAdmin.Priveliges.PlayerPriveligeData", CAdmin.Players.GetPlayers ())
			end
		end)
	end
end)

if SERVER then
	CAdmin.Hooks.Add ("CAdminUninitialize", "CAdmin.Priveliges.Uninitialize", function ()
		if Priveliges.Unsaved then
			Priveliges.Save ()
		end
	end)
end

CAdmin.Hooks.Add ("CAdminServerUninitialized", "CAdmin.Priveliges.ServerUninitialized", function ()
	table.Empty (Priveliges.Players)
	Priveliges.RemoveGroup (Priveliges.GetGroupList ())
	CAdmin.Hooks.Call ("CAdminPriveligesChanged")
end)