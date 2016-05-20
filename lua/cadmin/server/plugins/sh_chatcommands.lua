local PLUGIN = CAdmin.Plugins.Create ("Chat Commands")
PLUGIN:SetAuthor ("!cake")
PLUGIN:SetDescription ("Enables commands to be executed via chat.")

function PLUGIN:Initialize ()
	CAdmin.Chat.AddSayHook ("CAdmin.Chat.ChatCommands", function (ply, chatText, teamChat, playerIsDead)
		local _, chatCommand = CAdmin.Commands.ParseChatCommand (chatText)
		if chatCommand and CAdmin.Commands.GetChatCommand (chatCommand [1]) then
			CAdmin.Commands.Execute (ply, CAdmin.Commands.COMMAND_CHAT, unpack (chatCommand))
			return true
		end
	end)
end
