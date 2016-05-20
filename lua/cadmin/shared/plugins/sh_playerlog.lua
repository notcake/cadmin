local PLUGIN = CAdmin.Plugins.Create ("Player Event Logging")
PLUGIN:SetAuthor ("!cake")
PLUGIN:SetDescription ("Logs connections and deaths.")

function PLUGIN:Initialize ()
	local players = CAdmin.Players.GetPlayers ()
	local playerLogString = tostring (#players) .. " players in server:"
	for _, ply in ipairs (CAdmin.Players.GetPlayers ()) do
		playerLogString = playerLogString .. "\n\t(" .. ply:SteamID () .. ") " .. ply:Name ()
	end
	CAdmin.Messages.LogString (playerLogString, false, true)

	-- Connection and disconnection
	CAdmin.Hooks.Add ("CAdminPlayerConnected", "CAdmin.PlayerLog", function (steamID, uniqueID, playerName, ply)
		CAdmin.Messages.LogString ("(" .. steamID .. ") " .. playerName .. " has joined the game.", false, true)
	end)

	CAdmin.Hooks.Add ("CAdminPlayerDisconnected", "CAdmin.PlayerLog", function (steamID, uniqueID, playerName)
		CAdmin.Messages.LogString ("(" .. steamID .. ") " .. playerName .. " has left the game.", false, true)
	end)
	
	-- Deaths
	CAdmin.Hooks.Add ("CAdminPlayerDeath", "CAdmin.PlayerLog", function (victim, attacker, inflictorName, attackerName)
		if victim == attacker then
			if inflictorName then
				CAdmin.Messages.LogString (victim:Name () .. " killed themself with " .. inflictorName .. ".", false, true)
			else
				CAdmin.Messages.LogString (victim:Name () .. " committed suicide.", false, true)
			end
			return
		end
		CAdmin.Messages.LogString (victim:Name () .. " was killed by " .. attackerName, false, true)
	end)
end
