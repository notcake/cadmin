local PLUGIN = CAdmin.Plugins.Create ("Ban")
PLUGIN:SetAuthor ("!cake")
PLUGIN:SetDescription ("Provides commands for managing bans.")

function PLUGIN:Initialize ()
	local command = CAdmin.Commands.Create ("ban", "Administration", "Ban")
		:SetConsoleCommand ("ban")
		:SetLogString ("%Player% banned %target% for %arg1% minutes (%arg2%).")
	command:AddArgument ("Player")
		:SetPromptText ("Choose whom you want to ban:")
	command:AddArgument ("Number", "ban time", "0", function (time)
		return {
			"0",
			"10",
			"15",
			"30",
			"60",
			"1440",
			"10080"
		}
	end)
		:SetParameter ("Allow Permanent", true)
		:SetPromptText ("Enter the ban time:")
	command:AddArgument ("String", "reason", "N/A", function (reason)
			return {
				string.format ("%c%c%c_%c%c%c", 224, 178, 160, 224, 178, 160),
				"Deathmatching",
				"General nuisance",
				"Inappropriate language",
				"Lagging server",
				"Prop spam"
			}
		end)
		:SetPromptText ("Enter the reason for the ban:")
	command:SetExecute (function (ply, targply, banTime, reason)
		banTime = banTime or 0
		reason = reason or "N/A"
		reason = ply:Name () .. ": " .. reason
		if targply:SteamID () == "BOT" then
			targply:Kick ("Banned by " .. reason)
		else
			targply:Ban (banTime, reason)
		end
	end)
end
