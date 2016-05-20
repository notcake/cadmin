local Priveliges = CAdmin.Priveliges

CAdmin.Datastream.RegisterServerToClientStream ("CAdmin.Priveliges.PlayerData", function (ply, playerList, sendOnline, sendOffline, sendGroup, sendPriveliges)
	if not sendPriveliges and not sendGroup then
		return {}, {}
	end
	if type (playerList) == "Player" then
		playerList = {playerList}
	end
	local playerData = {}
	local shouldSend = false
	local playerEntity = nil
	local playerPriveligeData = nil
	local steamID = nil
	for _, ply in ipairs (playerList) do
		shouldSend = true
		steamID = nil
		playerEntity = nil
		if type (ply) == "string" then
			if sendOffline then
				steamID = ply
			else
				shouldSend = false
			end
		else
			if sendOnline then
				playerEntity = ply
				steamID = ply:SteamID ()
			else
				shouldSend = false
			end
		end
		playerPriveligeData = Priveliges.Players [steamID]
		if shouldSend then
			playerEntry = {
				SteamID = steamID,
				Player = playerEntity,
				Group = nil,
				Allow = nil
			}
			playerData [#playerData + 1] = playerEntry
			if sendGroup then
				playerEntry.Group = playerPriveligeData and playerPriveligeData.Group or Priveliges.GetDefaultGroup ()
			end
			if sendPriveliges then
				playerEntry.Allow = playerPriveligeData and playerPriveligeData.Allow or {}
			end
			if playerEntity then
				playerEntry.SteamID = nil
			end
		end
	end
	return ply, playerData
end, function (ply, playerData)
	local steamID = nil
	for _, playerEntry in ipairs (playerData) do
		steamID = playerEntry.SteamID or playerEntry.Player:SteamID ()
		
		if playerEntry.Group then
			Priveliges.SetPlayerGroup (playerEntry.Player or steamID, playerEntry.Group)
		end
		if playerEntry.Allow then
			Priveliges.SetPlayerPriveliges (playerEntry.Player or steamID, playerEntry.Allow)
		end
	end
end)