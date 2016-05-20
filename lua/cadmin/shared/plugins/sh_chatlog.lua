local PLUGIN = CAdmin.Plugins.Create ("Chat Logging")
PLUGIN:SetAuthor ("!cake")
PLUGIN:SetDescription ("Logs chat.")

function PLUGIN:Initialize ()
	CAdmin.Chat.AddSayHook (function (ply, text, teamchat, playerisdead)
		if not ply or not ply:IsValid () then
			ply = CAdmin.Players.GetConsole ()
		end
		local wholetext = ""
		if playerisdead then
			wholetext = wholetext .. "*DEAD* "
		end
		if teamchat then
			wholetext = wholetext .. "(TEAM) "
		end
		wholetext = wholetext .. ply:Name () .. ": " .. text
		CAdmin.Messages.LogString (wholetext, false, true)
	end)
end
