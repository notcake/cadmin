local Priveliges = CAdmin.Priveliges
local NetworkBuffer = Priveliges.NetworkBuffer

CAdmin.Datastream.RegisterServerToClientStream ("CAdmin.Priveliges.GroupPriveligeData", function (ply)
	local groupPriveligeData = NetworkBuffer.GroupPriveligeData
	NetworkBuffer.GroupPriveligeData = {}
	return ply, groupPriveligeData
end, function (ply, groupList)
	for groupID, groupEntry in pairs (groupList) do
		if groupEntry.Added then
			for priveligeName, _ in pairs (groupEntry.Added) do
				Priveliges.AddGroupPrivelige (groupID, priveligeName)
			end
		end
		if groupEntry.Removed then
			for priveligeName, _ in pairs (groupEntry.Removed) do
				Priveliges.RemoveGroupPrivelige (groupID, priveligeName)
			end
		end
	end
end)