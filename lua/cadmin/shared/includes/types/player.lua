local TYPE = CAdmin.Commands.RegisterType ("Player", "Entity")
TYPE:SetCompleter ("CAdmin.PlayerCompleter")

TYPE:SetAutocomplete (function (playerName)
	local playerList = {}
	local addedPlayers = {}
	local lowerName = playerName:lower ()
	if lowerName == "*" then
		lowerName = ""
	end
	if lowerName == "^" then
		return {LocalPlayer ():Name ()}
	end
	for _, v in pairs (CAdmin.Players.GetPlayers ()) do
		if v:Name ():lower ():find (lowerName, 1, true) then
			playerList [#playerList + 1] = v:Name ()
			addedPlayers [v:Name ()] = true
		end
	end
	for _, v in pairs (CAdmin.Players.GetPlayerData ()) do
		if v.OriginalName:lower ():find (lowerName, 1, true) then
			if not addedPlayers [v.OriginalName] then
				playerList [#playerList + 1] = v.OriginalName
				addedPlayers [v.OriginalName] = true
			end
		end
	end
	return playerList
end)

TYPE:SetSerializer (function (callingPly, ply, usedForLog)
	if ply == callingPly and usedForLog then
		return "themself"
	end
	return ply:Name ()
end)

TYPE:RegisterConverter ("String", function (ply, playerName, usedForlog)
	local playerList = {}
	local playerBySteamID = CAdmin.Players.GetPlayerBySteamID (playerName)
	if playerBySteamID then
		playerList [#playerList + 1] = playerBySteamID
	end
	
	-- If there is an exact match, use it.
	if CAdmin.Players.GetPlayerByName (playerName) then
		return CAdmin.Players.GetPlayerByName (playerName)
	end
	
	local lowerName = playerName:lower ()
	local selectAll = false
	if lowerName == "*" then
		selectAll = true
	elseif lowerName == "^" then
		if ply then
			playerList [#playerList + 1] = ply
		end
	end
	for _, v in pairs (CAdmin.Players.GetPlayers ()) do
		if selectAll or v:Name ():lower ():find (lowerName, 1, true) then
			playerList [#playerList + 1] = v
		end
	end
	
	-- Final pass to remove duplicates.
	local players = {}
	local addedPlayers = {}
	for _, v in pairs (playerList) do
		if not addedPlayers [v] then
			addedPlayers [v] = true
			players [#players + 1] = v
		end
	end
	playerList = nil
	if #players == 0 then
		return nil
	elseif #players == 1 then
		return players [1]
	end
	return players
end)