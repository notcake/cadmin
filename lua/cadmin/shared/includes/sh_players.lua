--[[
	Provides functions for managing player information.
	
	Files:
		data/cadmin/players.txt
		
	Datastreams:
		CAdmin.Players.BasePlayerData:
			Sends an array of tables in the form:
			{
				Player			- player entity.
				IP				- IP address.
				OriginalName	- Original player name.
			}
			
		CAdmin.Players.PlayerData:
			Sends an array of tables in the form:
			{
				Player		- player entity.
				Session		- true for session, false for permanent.
				Data		- table of key-value pairs.
			}
	
	Hooks:
		CAdminPlayerCAdminInitialized (steamID, uniqueID, playerName, ply):
			Called when a player loads CAdmin.
		CAdminPlayerCAdminUninitialized (steamID, uniqueID, playerName, ply):
			Called when a player unloads CAdmin.
		CAdminPlayerConnected (steamID, uniqueID, playerName, ply):
			Called when a new player entity is put into the server.
		CAdminPlayerDisconnected (steamID, uniqueID, playerName):
			Called when a player entity is removed from the server.
		CAdminPlayerNameChanged (steamID, uniqueID, ply, originalName, oldName, newName):
			Called when a player changes their name.
		CAdminReceiveIP (playerList):
			Called on the client when player IPs are received.
			playerList is an array of player entities.
]]
CAdmin.RequireInclude ("sh_datastream")
CAdmin.RequireInclude ("sh_hooks")
CAdmin.Players = CAdmin.Players or {}
local Players = CAdmin.Players
Players.Players = {}
Players.SteamIDs = {}				-- SteamIDs to player entities.
Players.CAdminPlayers = {}
Players.CAdminPlayersOutdated = false
Players.PlayerCount = 0
Players.SessionData = Players.SessionData or {}

--[[
	This is a virtual player representing the console.
]]
Players.Console = {}
local Console = Players.Console
Console.__index = Console
Console.__type = "Player"
Console.CAdminIsConsole = true

function Console:IsBot ()
	return false
end

function Console:IsValid ()
	return false
end

function Console:Name ()
	return "(Console)"
end

function Console:SteamID ()
	return "CONSOLE"
end

function Console:PrintMessage (type, msg)
	if !msg then
		print ("WARNING: PrintMessage called with a nil message.")
		CAdmin.Debug.PrintStackTrace ()
		return
	end
	print (msg)
end

function Console:UniqueID ()
	return "CONSOLE"
end

local function AddPlayer (ply)
	if not Players.IsSteamIDValid (ply:SteamID ()) then
		return
	end
	
	local playerEntry = {
		SteamID = ply:SteamID (),
		UniqueID = Players.GetUniqueID (ply),
		IP = "",
		Name = ply:Name (),
		Entity = ply,
		IsBot = Players.IsBot (ply),
		
		CAdminLoaded = false,
		OriginalName = ply:Name (),
		NameChangeCount = 0
	}
	Players.Players [Players.GetUniqueID (ply)] = playerEntry
	if SERVER then
		if playerEntry.IsBot then
			playerEntry.IP = "BOT"
		else
			playerEntry.IP = ply:IPAddress ()
			if playerEntry.IP == "loopback" then
				playerEntry.IP = "127.0.0.1"
			end
		end
	end
	if not playerEntry.IsBot then
		Players.SteamIDs [playerEntry.SteamID] = ply
	end
	Players.PlayerCount = Players.PlayerCount + 1
end

local function RemovePlayer (ply)
	if type (ply) == "Player" then
		ply = Players.GetUniqueID (ply)
	end
	if Players.Players [ply] then
		Players.SteamIDs [Players.Players [ply].SteamID] = nil
		Players.Players [ply] = nil
		Players.PlayerCount = Players.PlayerCount - 1
		Players.CAdminPlayersOutdated = true
	end
end

--[[
	Returns players who have CAdmin loaded.
]]
function Players.GetCAdminPlayers ()
	if Players.CAdminPlayersOutdated then
		Players.CAdminPlayers = {}
		for _, playerInfo in pairs (Players.Players) do
			if playerInfo.CAdminLoaded and playerInfo.Entity:IsValid () then
				Players.CAdminPlayers [#Players.CAdminPlayers + 1] = playerInfo.Entity
			end
		end
		Players.CAdminPlayersOutdated = false
	end
	return Players.CAdminPlayers
end

--[[
	Returns a virtual player representing the console.
]]
function Players.GetConsole ()
	return Console
end

function Players.GetIPAddress (ply)
	if not ply then
		print ("CAdmin: Players.GetIPAddress called with a nil player.")
		CAdmin.Debug.PrintStackTrace ()
		return
	end
	local playerInfo = Players.GetPlayerInfo (ply)
	if playerInfo then
		return playerInfo.IP
	end
	if SERVER then
		return ply:IPAddress ()
	end
	return ""
end

--[[
	Returns a player's original name.
	May not be 100% accurate.
]]
function Players.GetOriginalName (ply)
	local playerInfo = Players.GetPlayerInfo (ply)
	return playerInfo.OriginalName
end

--[[
	Returns a player by full name.
	Case sensitive.
]]
function Players.GetPlayerByName (name)
	for _, playerInfo in pairs (Players.Players) do
		if playerInfo.OriginalName == name then
			return playerInfo.Entity
		end
	end
	for _, ply in ipairs (Players.GetPlayers ()) do
		if ply:Name () == name then
			return ply
		end
	end
	return nil
end

--[[
	Returns a player by steam id.
]]
function Players.GetPlayerBySteamID (steamID)
	if Players.SteamIDs [steamID] then
		return Players.SteamIDs [steamid]
	end
	return nil
end

--[[
	Returns a player by user id.
]]
function Players.GetPlayerByUserID (userid)
	for k, v in ipairs (Players.GetPlayers ()) do
		if v:UserID () == userid then
			return v
		end
	end
	return
end

--[[
	Returns the number of players in the server.
]]
function Players.GetPlayerCount ()
	return Players.PlayerCount
end

--[[
	Returns the data of all non-bot players.
]]
function Players.GetPlayerData ()
	return Players.Players
end

--[[
	Returns a player's data entry.
]]
function Players.GetPlayerInfo (ply)
	if not ply then
		print ("GetPlayerInfo called with a nil player.")
		CAdmin.Debug.PrintStackTrace ()
		return
	end
	local uniqueID = ply
	if type (ply) ~= "string" then
		if not ply:IsValid () or not ply.Name then
			print ("CAdmin: GetPlayerInfo called with an invalid player.")
			CAdmin.Debug.PrintStackTrace ()
			return
		end
		uniqueID = Players.GetUniqueID (ply)
	end
	return Players.Players [uniqueID]
end

--[[
	Returns a list of all players.
]]
function Players.GetPlayers ()
	return player.GetAll ()
end

function Players.GetSessionData (ply, key)
	local sessionData = Players.SessionData [Players.GetUniqueID (ply)]
	if not sessionData then
		return nil
	end
	return sessionData [key]
end

--[[
	Returns a player's UniqueID.
	ULib breaks this clientside when the server is not running ULib.
]]
function Players.GetUniqueID (ply)
	-- CAdminUniqueID should be the only key we store in the player entity's table.
	local uniqueID = ply.CAdminUniqueID
	if not uniqueID and Players.IsBot (ply) then
		uniqueID = util.CRC (ply:Name ())
	end
	if not uniqueID then
		uniqueID = ply.UniqueID and ply:UniqueID ()
	end
	if not uniqueID or uniqueID == "" then
		local steamID = (ply.SteamID and not SinglePlayer ()) and ply:SteamID () or "STEAM_0:0:0"
		uniqueID = util.CRC ("gm_" .. steamID .. "_gm")
	end
	ply.CAdminUniqueID = uniqueID
	return uniqueID
end

--[[
	Returns a player by full name.
	If multiple matches are found, it fails.
]]
function Players.GetUniquePlayerByName (name)
	local player = nil
	for _, playerInfo in pairs (Players.Players) do
		if playerInfo.OriginalName == name then
			if player then
				return nil
			end
			player = playerInfo.Entity
		end
	end
	for _, ply in ipairs (Players.GetPlayers ()) do
		if ply:Name () == name then
			if player then
				return nil
			end
			player = ply
		end
	end
	return player
end

function Players.IsBot (ply)
	if not ply or not ply:IsValid () then return false end
	if ply.IsBot and ply:IsBot () then
		return true
	end
	if not ply.SteamID then
		CAdmin.Debug.PrintStackTrace ()
		Msg ("CAdmin.Players.IsBot : _R.Player.SteamID is not yet present.\n")
		return false
	end
	-- Player.IsBot seems to fail clientside.
	if CLIENT and ply:SteamID () == "NULL" then
		return true
	end
	if SERVER and ply:SteamID () == "BOT" then
		return true
	end
	return false
end

--[[
	Checks if the given player is the virtual player representing the console.
]]
function Players.IsConsole (ply)
	if not ply then
		print ("CAdmin: Players.IsConsole called with a nil value.")
		CAdmin.Debug.PrintStackTrace ()
		return false
	end
	return ply.CAdminIsConsole or false
end

function Players.IsRunningCAdmin (ply)
	local playerInfo = Players.GetPlayerInfo (ply)
	if playerInfo and playerInfo.CAdminLoaded then
		return true
	end
	return false
end

function Players.IsSteamIDValid (steamID)
	return steamID ~= ""
end

--[[
	PlayerCAdminLoaded and PlayerCAdminUnloaded are called from
	the core server file.
]]
function Players.PlayerCAdminLoaded (ply)
	if not ply or not ply:IsValid () then
		return
	end
	
	local uniqueID = Players.GetUniqueID (ply)
	local playerInfo = Players.GetPlayerInfo (uniqueID)
	-- In case the player has not been added yet because of a missing steam ID or name.
	if not playerInfo then
		CAdmin.Timers.RunNextTick (PlayerCAdminLoaded, ply)
		return
	end
	if not playerInfo.CAdminLoaded then
		playerInfo.CAdminLoaded = true
		Players.CAdminPlayers [#Players.CAdminPlayers + 1] = ply
		CAdmin.Hooks.Call ("CAdminPlayerCAdminInitialized", ply:SteamID (), uniqueID, ply:Name (), ply)
	end
end

function Players.PlayerCAdminUnloaded (ply)
	local uniqueID = Players.GetUniqueID (ply)
	local playerInfo = Players.GetPlayerInfo (uniqueID)
	if playerInfo and playerInfo.CAdminLoaded then
		playerInfo.CAdminLoaded = false
		Players.CAdminPlayersOutdated = true
		CAdmin.Hooks.Call ("CAdminPlayerCAdminUninitialized", ply:SteamID (), uniqueID, ply:Name (), ply)
	end
end

function Players.SetSessionData (ply, key, value, shouldNetwork)
	local uniqueID = Players.GetUniqueID (ply)
	Players.SessionData [uniqueID] = Players.SessionData [uniqueID] or {}
	shouldNetwork = shouldNetwork and Players.SessionData [uniqueID] [key] ~= value
	Players.SessionData [uniqueID] [key] = value
	
	if SERVER and shouldNetwork then
		CAdmin.Datastream.SendStream ("CAdmin.Players.PlayerData", Players.GetCAdminPlayers (), ply, key)
	end
end

CAdmin.Datastream.RegisterServerToClientStream ("CAdmin.Players.BasePlayerData", function (ply, players, sendIPs)
	local basePlayerData = {}
	if type (players) == "Player" then
		players = {players}
	end
	if type (ply) == "Player" then
		ply = {ply}
	end
	if sendIPs then
		local newRecipients = {}
		for _, ply in ipairs (ply) do
			if CAdmin.Priveliges.IsPlayerAuthorized (ply, "viewip") then
				newRecipients [#newRecipients + 1] = ply
			end
		end
		ply = newRecipients
	end
	
	local playerInfo = nil
	for _, ply in ipairs (players) do
		local playerEntry = {}
		playerInfo = Players.GetPlayerInfo (ply)
		basePlayerData [#basePlayerData + 1] = playerEntry
		playerEntry.Player = ply
		if sendIPs then
			playerEntry.IP = playerInfo.IP
		else
			playerEntry.OriginalName = playerInfo.OriginalName
		end
	end
	return ply, basePlayerData
end, function (ply, basePlayerData)
	local playerInfo = nil
	local receivedIPPlayers = {}
	for _, playerEntry in ipairs (basePlayerData) do
		playerInfo = Players.GetPlayerInfo (playerEntry.Player)
		if playerEntry.IP then
			playerInfo.IP = playerEntry.IP
			receivedIPPlayers [#receivedIPPlayers + 1] = playerEntry.Player
		end
		playerInfo.OriginalName = playerEntry.OriginalName or playerInfo.OriginalName
	end
	if #receivedIPPlayers > 0 then
		CAdmin.Hooks.Call ("CAdminReceiveIP", receivedIPPlayers)
	end
end)

CAdmin.Datastream.RegisterServerToClientStream ("CAdmin.Players.PlayerData", function (ply, player, key)
	if type (player) == "Player" then
		player = {player}
	end
	local playerData = {}
	for _, ply in ipairs (player) do
		local playerEntry = {}
		playerData [#playerData + 1] = playerEntry
		playerEntry.Player = ply
		local value = Players.SessionData [Players.GetUniqueID (ply)] [key]
		if value ~= nil then
			playerEntry.Session = true
		end
		playerEntry.Data = {
			[key] = value
		}
	end
	return ply, playerData
end, function (ply, playerData)
	for _, playerEntry in ipairs (playerData) do
		if playerEntry.Session then
			for k, v in pairs (playerEntry.Data) do
				Players.SetSessionData (playerEntry.Player, k, v)
			end
		else
			for k, v in pairs (playerEntry.Data) do
				Players.SetPermanentData (playerEntry.Player, k, v)
			end
		end
	end
end)

CAdmin.Hooks.Add ("CAdminInitialize", "CAdmin.Players.Initialize", function ()
	for _, ply in ipairs (Players.GetPlayers ()) do
		AddPlayer (ply)
	end

	if SERVER then
		CAdmin.Hooks.Add ("CAdminPlayerConnected", "CAdmin.Players.PlayerConnected", function (steamID, uniqueID, playerName, ply)
			CAdmin.SendServerState (ply)
			CAdmin.Datastream.SendStream ("CAdmin.Players.BasePlayerData", Players.GetCAdminPlayers (), ply)
			CAdmin.Datastream.SendStream ("CAdmin.Players.BasePlayerData", Players.GetCAdminPlayers (), ply, true)
		end)

		CAdmin.Hooks.Add ("CAdminPlayerCAdminInitialized", "CAdmin.Players.PlayerCAdminInitialized", function (steamID, uniqueID, playerName, ply)
			CAdmin.Datastream.SendStream ("CAdmin.Players.BasePlayerData", ply, Players.GetPlayers ())
			CAdmin.Datastream.SendStream ("CAdmin.Players.BasePlayerData", ply, Players.GetPlayers (), true)
		end)
	end
		
	CAdmin.Hooks.Add ("CAdminPlayerDisconnected", "CAdmin.Players.PlayerDisconnected", function (steamID, uniqueID, playerName)
		Players.SessionData [uniqueID] = nil
	end)

	CAdmin.Hooks.Add ("CAdminPlayerNameChanged", "CAdmin.Players.PlayerNameChanged", function (steamID, uniqueID, ply, originalName, oldName, newName)
		if oldName == "unconnected" or oldName == "" then
			return
		end
		CAdmin.Messages.LogCommand (
			{
				LogString = "(%arg3% \"%arg4%\") Renamed themself from %arg1% to %arg2%.",
				Player = ply,
				Arguments = {
					oldName,
					newName,
					steamID,
					originalName
				}
			}
		)
	end)

	CAdmin.Hooks.Add ("Think", "CAdmin.Players.Think", function ()
		local uniqueID = nil
		for _, ply in ipairs (Players.GetPlayers ()) do
			uniqueID = Players.GetUniqueID (ply)
			local playerInfo = Players.GetPlayerInfo (uniqueID)
			if playerInfo then
				if playerInfo.Name ~= ply:Name () then
					playerInfo.NameChangeCount = playerInfo.NameChangeCount + 1
					CAdmin.Hooks.Call ("CAdminPlayerNameChanged", ply:SteamID (), uniqueID, ply, playerInfo.OriginalName, playerInfo.Name, ply:Name ())
					playerInfo.Name = ply:Name ()
				end
			else
				-- Sometimes the steamid is not available immediately.
				if Players.IsSteamIDValid (ply:SteamID ()) then
					AddPlayer (ply)
					CAdmin.Hooks.Call ("CAdminPlayerConnected", ply:SteamID (), uniqueID, ply:Name (), ply)
				end
			end
		end
		for uniqueID, playerInfo in pairs (Players.Players) do
			if not playerInfo.Entity:IsValid () then
				RemovePlayer (uniqueID)
				CAdmin.Hooks.Call ("CAdminPlayerDisconnected", playerInfo.SteamID, uniqueID, playerInfo.Name)
			end
		end
	end)
end)