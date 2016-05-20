--[[
	Provides functions for managing bans.
	
	Files:
		data/cadmin/bans.txt
		
	Datastreams:
		CAdmin.Bans.UpdateBans:
			Sends an array of tables in the form documented by the CAdminReceiveBan hook below.
	
	Hooks:
		CAdminPlayerBanned (adminSteamID, adminName, adminPlayer, steamID, playerName, bannedPlayer, time):
			Called when a player is added to the banned list.
		CAdminPlayerUnbanned (adminSteamID, adminName, adminPlayer, steamID, playerName):
			Called when a player is removed from the banned list.
		CAdminReceiveBan (banInfo):
			Called when bans are added / removed from the clientside ban list.
			Generally called when the client receives a list of banned players.
			banInfo is an array of tables of the form:
			{
				Banned			- True for ban, false for unban.
				SteamID 		- SteamID of banned player.
				Name			- Player name.
				UnbanTime		- Date on which player will be unbanned. 0 if permanent.
				BannerSteamID	- SteamID of admin or person who initiated voteban.
				BannerName		- Name of admin or person who initiated voteban.
				Reason			- Reason for ban.
			}
]]
CAdmin.Bans = CAdmin.Bans or {}
CAdmin.Bans.Bans = {}
CAdmin.Bans.BanCount = 0

function CAdmin.Bans.GetBanCount ()
	return CAdmin.Bans.BanCount
end