local PANEL = {}

function PANEL:Init ()
	self.PlayerList = self:Create ("DListView")
	self.PlayerList:AddColumn ("Name")
	self.PlayerList:AddColumn ("Group")
	self.PlayerList:AddColumn ("Steam ID")
	self.PlayerList:AddColumn ("IP Address")
	self.PlayerList:SetObjectConverter ("Player")
	
	self:SetSize (0.5 * ScrW (), 0.5 * ScrH ())
end

function PANEL:DoLayout ()
	self:PopulatePlayers ()
end

function PANEL:GetArgumentValue ()
	return self.PlayerList:GetSelectedObjects ()
end

function PANEL:PerformLayout ()
	local padding = self:GetPadding ()
	self.PlayerList:SetPos (padding, padding)
	self.PlayerList:SetSize (self:GetWide () - 2 * padding, self:GetTall () - 2 * padding)
end

function PANEL:PopulatePlayers ()
	self.PlayerList:Clear ()
	
	local line = nil
	for _, v in pairs (player.GetAll ()) do
		line = self.PlayerList:AddLine (v:Name (), CAdmin.Priveliges.GetPlayerGroupName (v), v:SteamID (), CAdmin.Players.GetIPAddress (v))
		line.Player = v
		line.UniqueID = CAdmin.Players.GetUniqueID (v)
		line:SetIcon (CAdmin.Priveliges.GetPlayerGroupIcon (v))
	end
end

function PANEL:SetArgumentValue (playerList)
	local selectedPlayers = {}
	for _, v in pairs (playerList) do
		selectedPlayers [v] = true
	end
	for _, line in pairs (self.PlayerList:GetLines ()) do
		if selectedPlayers [line.Player] then
			self.PlayerList:SelectItem (line)
		end
	end
end

CAdmin.GUI.Register ("CAdmin.PlayerCompleter", PANEL, "CArgumentCompleter")