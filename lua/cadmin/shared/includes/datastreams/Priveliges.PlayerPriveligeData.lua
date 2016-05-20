local Priveliges = CAdmin.Priveliges
local NetworkBuffer = Priveliges.NetworkBuffer

CAdmin.Datastream.RegisterServerToClientStream ("CAdmin.Priveliges.PlayerPriveligeData", function (ply)
	local playerPriveligeData = NetworkBuffer.PlayerPriveligeData
	NetworkBuffer.PlayerPriveligeData = {}
	return ply, playerPriveligeData
end, function (ply, playerList)
	local priveligesChanged = {}
	for steamID, playerEntry in pairs (playerList) do
		if playerEntry.Added then
			for priveligeName, _ in pairs (playerEntry.Added) do
				Priveliges.AddPlayerPrivelige (steamID, priveligeName)
			end
		end
		if playerEntry.Removed then
			for priveligeName, _ in pairs (playerEntry.Removed) do
				Priveliges.RemovePlayerPrivelige (steamID, priveligeName)
			end
		end
		if steamID == LocalPlayer ():SteamID () then
			CAdmin.Hooks.QueueCall ("CAdminLocalPlayerPriveligesChanged")
		end
	end
	CAdmin.Hooks.Call ("CAdminPlayerPriveligesChanged", priveligesChanged)
end)