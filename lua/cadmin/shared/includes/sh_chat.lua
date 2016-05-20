CAdmin.RequireInclude ("sh_hooks")

CAdmin.Chat = CAdmin.Chat or {}
CAdmin.Chat.ChatText = ""
CAdmin.Chat.ChatTextChangeHooks = {}
CAdmin.Chat.CompletionHooks = {}
CAdmin.Chat.SayHooks = {}

CAdmin.Chat.CHAT_NONE = 0
CAdmin.Chat.CHAT_PUBLIC = 1
CAdmin.Chat.CHAT_TEAM = 2
CAdmin.Chat.Mode = CAdmin.Chat.CHAT_NONE

--[[
	Adds a functions to be run when the player types something into the chat box.
]]
function CAdmin.Chat.AddChatTextChangeHook (name, func)
	if type (name) == "function" then
		func = name
		name = util.CRC (tostring (func))
	end

	local runningPlugin = CAdmin.Plugins.GetRunningPlugin ()
	CAdmin.Chat.ChatTextChangeHooks [name] = {
		Function = func,
		Plugin = runningPlugin
	}
	if runningPlugin then
		runningPlugin.ChatTextChangeHooks [name] = true
	end
end

function CAdmin.Chat.AddCompletionHook (name, completionFunc)
	if type (name) == "function" then
		completionFunc = name
		name = util.CRC (tostring (completionFunc))
	end
	
	local runningPlugin = CAdmin.Plugins.GetRunningPlugin ()
	CAdmin.Chat.CompletionHooks [name] = {
		Function = completionFunc,
		Plugin = runningPlugin
	}
	if runningPlugin then
		runningPlugin.CompletionHooks [name] = true
	end
end

--[[
	Adds a functions to be run when someone says something.
	Say hooks should return 2 arguments:
		1. Boolean indicating whether the chat should be blocked. Nil is interpreted as false.
		2. String with which to override the chat. This should be nil if the text is to be left alone.
	These return values are only used on the server.
]]
function CAdmin.Chat.AddSayHook (name, func)
	if type (name) == "function" then
		func = name
		name = util.CRC (tostring (func))
	end

	local runningPlugin = CAdmin.Plugins.GetRunningPlugin ()
	CAdmin.Chat.SayHooks [name] = {
		Function = func,
		Plugin = runningPlugin
	}
	if runningPlugin then
		runningPlugin.SayHooks [name] = true
	end
end

function CAdmin.Chat.GetInputMode ()
	return CAdmin.Chat.Mode
end

function CAdmin.Chat.RemoveChatTextChangeHook (name)
	CAdmin.Chat.ChatTextChangeHooks [name] = nil
end

function CAdmin.Chat.RemoveCompletionHook (name)
	CAdmin.Chat.CompletionHooks [name] = nil
end

function CAdmin.Chat.RemoveSayHook (name)
	CAdmin.Chat.SayHooks [name] = nil
end

--[[
	Called when a player says something on both the client and server.
]]
local function OnPlayerChat (ply, chatText, teamChat, playerIsDead)
	local hideChat = false
	local newChatText = nil
	for _, hookInfo in pairs (CAdmin.Chat.SayHooks) do
		local suppressChat, overrideChatText = hookInfo.Function (ply, chatText, teamChat, playerIsDead)
		if suppressChat then
			hideChat = true
		end
		if overrideChatText and overrideChatText ~= chatText then
			newChatText = chatText
		end
	end
	if hideChat then
		newChatText = ""
	end
	return newChatText
end

if CLIENT then
	CAdmin.Hooks.Add ("StartChat", "CAdmin.Chat.StartChat", function (teamChat)
		if teamChat then
			CAdmin.Chat.Mode = CAdmin.Chat.CHAT_TEAM
		else
			CAdmin.Chat.Mode = CAdmin.Chat.CHAT_PUBLIC
		end
		CAdmin.Chat.ChatText = ""
	end)

	CAdmin.Hooks.Add ("FinishChat", "CAdmin.Chat.FinishChat", function ()
		if CLIENT and not CAdmin:IsServerRunning () then
			if not input.IsKeyDown (KEY_ESCAPE) and
			   input.IsKeyDown (KEY_ENTER) then
				local _, chatCommand = CAdmin.Commands.ParseChatCommand (CAdmin.Chat.ChatText)
				if chatCommand and CAdmin.Commands.GetChatCommand (chatCommand [1]) then
					CAdmin.Commands.Execute (LocalPlayer (), CAdmin.Commands.COMMAND_CHAT, unpack (chatCommand))
				end
			end
		end
		CAdmin.Chat.ChatText = ""
		CAdmin.Chat.Mode = CAdmin.Chat.CHAT_NONE
	end)
	
	CAdmin.Hooks.Add ("ChatTextChanged", "CAdmin.Chat.ChatTextChanged", function (chatText)
		local ply = LocalPlayer ()
		CAdmin.Chat.ChatText = chatText
		for _, hookInfo in pairs (CAdmin.Chat.ChatTextChangeHooks) do
			hookInfo.Function (chatText)
		end
	end)
	
	CAdmin.Hooks.Add ("OnChatTab", "CAdmin.Chat.OnChatTab", function ()
		for _, hookInfo in pairs (CAdmin.Chat.CompletionHooks) do
			local completionText = hookInfo.Function (CAdmin.Chat.ChatText)
			if completionText then
				return completionText
			end
		end
	end)

	CAdmin.Hooks.Add ("OnPlayerChat", "CAdmin.Chat.Hooks", function (ply, chatText, teamChat, playerIsDead)
		OnPlayerChat (ply, chatText, teamChat, playerIsDead)
	end)
else
	CAdmin.Hooks.Add ("PlayerSay", "CAdmin.Chat.Hooks", OnPlayerChat)
end

CAdmin.Hooks.Add ("CAdminInitialize", "CAdmin.Chat.Initialize", function ()
	CAdmin.Hooks.Add ("CAdminPluginLoaded", "CAdmin.Chat.PluginLoaded", function (pluginList)
		for _, plugin in pairs (pluginList) do
			plugin.ChatTextChangeHooks = {}
			plugin.CompletionHooks = {}
			plugin.SayHooks = {}
		end
	end)

	CAdmin.Hooks.Add ("CAdminPluginUnloaded", "CAdmin.Chat.PluginUnloaded", function (pluginList)
		for _, plugin in pairs (pluginList) do			
			for k, _ in pairs (plugin.ChatTextChangeHooks) do
				CAdmin.Chat.RemoveChatTextChangeHook (k)
			end
			plugin.ChatTextChangeHooks = nil

			for k, _ in pairs (plugin.CompletionHooks) do
				CAdmin.Chat.RemoveCompletionHook (k)
			end
			plugin.CompletionHooks = nil

			for k, _ in pairs (plugin.SayHooks) do
				CAdmin.Chat.RemoveSayHook (k)
			end
			plugin.SayHooks = nil
		end
	end)
end)