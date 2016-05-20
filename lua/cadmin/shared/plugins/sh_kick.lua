local PLUGIN = CAdmin.Plugins.Create ("Kick")
PLUGIN:SetAuthor ("!cake")
PLUGIN:SetDescription ("Provides commands for kicking players.")

function PLUGIN:Initialize ()
	local command = CAdmin.Commands.Create ("kick", "Administration", "Kick")
	command:SetConsoleCommand ("kick")
	command:AddArgument ("Player"):SetPromptText ("Select whom you want to kick:")
	command:AddArgument ("String", "Reason", "N/A"):SetPromptText ("Enter the reason for the kick:")
	command:SetLogString ("%Player% kicked %target% (%arg1%).")
	command:SetExecute (function (ply, targply, reason)
		reason = reason or "N/A"
		reason = ply:Name () .. ": " .. reason
		targply:Kick (reason)
		
		if targply:IsListenServerHost () then
			targply:ConCommand ("disconnect")
		end
	end)
end
