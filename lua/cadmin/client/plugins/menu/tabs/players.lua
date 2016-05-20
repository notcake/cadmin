local TAB = TAB
TAB:SetName ("Players")
TAB:SetIcon ("gui/silkicons/user")
TAB:SetTabPosition (1)
TAB:SetTooltip ("View the player list.")

function TAB:Init ()
	self:SetCommandArgumentType ("Player")
	self:CreateListViewLayout ()
	self.ItemList:AddColumn ("Name")
	self.ItemList:AddColumn ("Group")
	self.ItemList:AddColumn ("Steam ID")
	self.ItemList:AddColumn ("IP Address")
	self.ItemList:SetObjectConverter ("Player")

	self:PopulateItems ()

	CAdmin.Hooks.Add ("CAdminPlayerGroupChanged", "CAdmin.Menu.Players.UpdateRank", function ()
		self:PopulateItems ()
	end)

	CAdmin.Hooks.Add ("CAdminGroupDataChanged", "CAdmin.Menu.Players.UpdateRank", function ()
		self:PopulateItems ()
	end)
end

function TAB:PopulateItems ()
	self.ItemList:Clear ()

	local line = nil
	for _, ply in pairs (CAdmin.Players.GetPlayers ()) do
		line = self.ItemList:AddLine (ply:Name (), CAdmin.Priveliges.GetPlayerGroupName (ply), ply:SteamID (), CAdmin.Players.GetIPAddress (ply))
		line.Player = ply
		line.UniqueID = CAdmin.Players.GetUniqueID (ply)
		line:SetIcon (CAdmin.Priveliges.GetPlayerGroupIcon (ply))
	end
end

CAdmin.Hooks.Add ("CAdminReceiveIP", "CAdmin.Menu.Players.UpdateIPs", function (playerList)
	for _, line in pairs (TAB.ItemList.Lines) do
		line:SetValue (4, CAdmin.Players.GetIPAddress (line.Player))
	end
end)

CAdmin.Hooks.Add ("CAdminPlayerConnected", "CAdmin.Menu.Players", function (steamID, uniqueID, playerName, ply)
	local line = TAB.ItemList:AddLine (playerName, CAdmin.Priveliges.GetPlayerGroupName (ply), steamID, CAdmin.Players.GetIPAddress (ply))
	line.Player = ply
	line.UniqueID = uniqueID
	line:SetIcon (CAdmin.Priveliges.GetPlayerGroupIcon (ply))
	TAB:UpdateCommands ()
end)

CAdmin.Hooks.Add ("CAdminPlayerDisconnected", "CAdmin.Menu.Players", function (steamID, uniqueID, playerName)
	for k, line in pairs (TAB.ItemList.Lines) do
		if line.UniqueID == uniqueID then
			line:Remove ()
		end
	end
	
	TAB:UpdateCommands ()
end)

CAdmin.Hooks.Add ("CAdminPlayerNameChanged", "CAdmin.Menu.Players", function (steamID, uniqueID, ply, originalName, oldName, newName)
	for _, line in pairs (TAB.ItemList.Lines) do
		if line.UniqueID == uniqueID then
			line:SetValue (1, newName)
		end
	end
end)