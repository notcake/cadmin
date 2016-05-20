CAdmin.RequireInclude ("sh_datastream")
CAdmin.RequireInclude ("sh_hooks")
CAdmin.RequireInclude ("sh_lua")
CAdmin.RequireInclude ("sh_plugins")

CAdmin.Console = CAdmin.Console or {}
local Console = CAdmin.Console
Console.ChangeCallbacks = {}
Console.CommandBuffer = {}
Console.Commands = {}

local GameConsoleCommandList = nil

function Console.AddChangeCallback (name, func)
	if not Console.ChangeCallbacks [name] then
		Console.ChangeCallbacks [name] = {}
	end
	Console.ChangeCallbacks [name] [func] = true
	cvars.AddChangeCallback (name, func)

	local plugin = CAdmin.Plugins.GetRunningPlugin ()
	if plugin then
		if not plugin.ChangeCallbacks [name] then
			plugin.ChangeCallbacks [name] = {}
		end
		plugin.ChangeCallbacks [name] [func] = true
	end
end

--[[
	Adds a console command.
	Console commands added by plugins are automagically removed.
	Console commands not added by a plugin are removed when CAdmin is unloaded.
]]
function Console.AddCommand (name, func, autocomplete)
	local command = Console.Commands [name]
	if command then
		CAdmin.Debug.PrintStackTrace ()
		Console.RemoveCommand (name)
	end
	command = {}
	Console.Commands [name] = command
	
	command.Func = func
	command.Autocomplete = autocomplete
	command.Permanent = false
	concommand.Add (name, func, autocomplete)

	local plugin = CAdmin.Plugins.GetRunningPlugin ()
	if plugin then
		plugin.ConsoleCommands [name] = true
		command.Plugin = plugin.Name
	end
end

--[[
	Adds a console command.
	Console commands added by this method are never removed.
]]
function Console.AddPermanentCommand (commandName, func, autocomplete)
	Console.AddCommand (commandName, func, autocomplete)
	Console.Commands [commandName].Permanent = true
end

--[[
	Adds a console command on the client only.
]]
function Console.AddClientCommand (commandName, func, autocomplete)
	if not CLIENT then
		return
	end

	Console.AddCommand (commandName, func, autocomplete)
end

--[[
	Same as above, but the command does not get removed.
]]
function Console.AddPermanentClientCommand (commandName, func, autocomplete)
	if not CLIENT then
		return
	end

	Console.AddPermanentCommand (commandName, func, autocomplete)
end

--[[
	Adds a console command on the server, and a command on the client that
	forwards calls to it to the server.
]]
function Console.AddServerCommand (commandName, func, autocomplete)
	if CLIENT then
		Console.AddClientCommand (commandName, function (ply, cmd, args)
			if CAdmin.ServerInitialized then
				Console.ForwardCommand (ply, cmd, args)
			else
				print ("CAdmin is not running on the server!")
			end
		end, autocomplete)
	end
	if SERVER then
		Console.AddCommand (commandName, func, autocomplete)
	end
end

function Console.AddPermanentServerCommand (commandName, func, autocomplete)
	if CLIENT then
		Console.AddClientCommand (commandName, function (ply, cmd, args)
			Console.ForwardCommand (ply, cmd, args)
		end, autocomplete)
	end
	if SERVER then
		Console.AddCommand (commandName, func, autocomplete)
	end
	Console.Commands [commandName].Permanent = true
end

function Console.ForwardCommand (ply, consoleCommand, ...)
	if CLIENT then
		if CAdmin.IsServerRunning () then
			CAdmin.Datastream.SendStream ("CAdmin.Console.ForwardCommand", ply, {consoleCommand, ...})
		end
	else
		concommand.Run (ply, consoleCommand, ...)
	end
end

CAdmin.Datastream.RegisterClientToServerStream ("CAdmin.Console.ForwardCommand", nil, function (ply, commandData)
	if not commandData or not commandData [1] then
		print ("CAdmin.ForwardCommand was sent invalid data.")
	end
	local consoleCommand = CAdmin.Util.PopFront (commandData)
	concommand.Run (ply, consoleCommand, commandData)
end)

function Console.GetCommand (cmd)
	return Console.Commands [cmd]
end

function Console.GetCommandFunction (consoleCommand)
	return GameConsoleCommandList [consoleCommand:lower ()]
end

function Console.GetCommands ()
	return Console.Commands
end

function Console.RemoveChangeCallback (commandName, callbackFunc)
	if not Console.ChangeCallbacks [commandName] then
		return
	end
	Console.ChangeCallbacks [commandName] [callbackFunc] = nil
	local changeCallbacks = cvars.GetConVarCallbacks (commandName)
	if changeCallbacks then
		for k, f in pairs (changeCallbacks) do
			if f == callbackFunc then
				changeCallbacks [k] = nil
				break
			end
		end
	end
end

--[[
	Removes a console command.
]]
function Console.RemoveCommand (commandName)
	if not Console.Commands [commandName] then
		return
	end
	concommand.Remove (commandName)
	if Console.Commands [commandName].Plugin then
		CAdmin.Plugins.GetPlugin (Console.Commands [commandName].Plugin).ConsoleCommands [commandName] = nil
	end
	Console.Commands [commandName] = nil
end

--[[
	Runs a console command.
	Tries to run it instantly if possible, instead of at the end of the frame.
]]
function Console.RunCommand (commandName, ...)
	commandName = commandName:lower ()
	local commandFunc = GameConsoleCommandList [commandName]
	if commandFunc then
		local player = nil
		if CLIENT then
			player = LocalPlayer ()
		end
		commandFunc (player, commandName, {...})
	else
		RunConsoleCommand (commandName, ...)
	end
end

CAdmin.Hooks.Add ("CAdminInitialize", "CAdmin.Console.Initialize", function ()
	local upvalueCount = debug.getinfo (concommand.Add).nups
	for i = 1, upvalueCount do
		local name, value = debug.getupvalue (concommand.Add, i)
		if name == "CommandList" then
			GameConsoleCommandList = value
			break
		end
	end

	if SERVER then
		CAdmin.Lua.HookFunction ("RunConsoleCommand", function (_RunConsoleCommand, commandName, ...)
			local convar = GetConVar (commandName)
			local oldValue = nil
			if convar then
				oldValue = convar:GetString ()
			end
			_RunConsoleCommand (commandName, ...)
			if convar and Console.ChangeCallbacks [commandName] then
				for callbackFunc, _ in pairs (Console.ChangeCallbacks [commandName]) do
					--[[
						RunConsoleCommand only runs the command at the end /  beginning of a tick.
						So the convar's value cannot be used here.
					]]
					callbackFunc (commandName, oldValue, ...)
				end
			end
		end)
	end

	CAdmin.Hooks.Add ("CAdminPluginLoaded", "CAdmin.Console.PluginLoaded", function (pluginList)
		for _, plugin in pairs (pluginList) do
			plugin.ChangeCallbacks = plugin.ChangeCallbacks or {}
			plugin.ConsoleCommands = plugin.ConsoleCommands or {}
		end
	end)

	CAdmin.Hooks.Add ("CAdminPluginUnloaded", "CAdmin.Console.PluginUnloaded", function (pluginList)
		for _, plugin in pairs (pluginList) do
			for convar, callbackTable in pairs (plugin.ChangeCallbacks) do
				for callbackFunc, _ in pairs (callbackTable) do
					Console.RemoveChangeCallback (convar, callbackFunc)
				end
			end
			plugin.ChangeCallbacks = nil
			for consoleCommand, _ in pairs (plugin.ConsoleCommands) do
				Console.RemoveCommand (consoleCommand)
			end
			plugin.ConsoleCommands = nil
		end
	end)
end)

CAdmin.Hooks.Add ("CAdminUninitialize", "CAdmin.Console.Uninitialize", function ()
	for convar, t in pairs (Console.ChangeCallbacks) do
		for f, _ in pairs (t) do
			Console.RemoveChangeCallback (convar, f)
		end
	end
	for consoleCommand, t in pairs (Console.Commands) do
		if not t.Permanent then
			Console.RemoveCommand (consoleCommand)
		end
	end
end)