CAdmin.RequireInclude ("sh_lua")
CAdmin.RequireInclude ("sh_console")
CAdmin.RequireInclude ("sh_objects")
CAdmin.RequireInclude ("sh_plugins")

CAdmin.Commands = CAdmin.Commands or {}
local Commands = CAdmin.Commands

--[[
	Command execution sources.
]]
CAdmin.Commands.COMMAND_CONSOLE	= 1
CAdmin.Commands.COMMAND_CHAT	= 2
CAdmin.Commands.COMMAND_ID		= 3

--[[
	Command execution locations.
]]
CAdmin.Commands.RUN_SERVER		= 1		-- Command must be run on the server.
CAdmin.Commands.RUN_LOCAL		= 2		-- Command must be run locally.
CAdmin.Commands.RUN_BOTH		= 3		-- Command can be run on either the client or server.

--[[
	TODO: Rewrite
]]
CAdmin.COMMAND_CLIENT = 1		-- Command can always be run (on a client)
CAdmin.COMMAND_SERVER = 2		-- Command is handled by the server, requires priveliges.
CAdmin.COMMAND_SERVER_ONLY = 3	-- Command can only be run from the server console.
CAdmin.COMMAND_SHARED = 4		-- Command can be run anywhere.

--[[
	Command fallback types.
	Higher numbers get precedence.
]]
CAdmin.FALLBACK_DEFAULT = 1		-- Default fallback command type.
CAdmin.FALLBACK_ADMIN = 2		-- Admin fallback commands are run in preference to default fallback commands.

Commands.Categories = {}
Commands.CategoryCounts = {}
Commands.ChatCommands = {}
Commands.ConsoleCommands = {}
Commands.Commands = {}
Commands.FallbackCommands = {}
Commands.FallbackCommandCounts = {}
Commands.Types = {}

--[[
	Returns an autocompletion table
]]
function Commands.Autocomplete (commandSource, arguments)
	local argumentList = CAdmin.Util.ExplodeQuotedString (arguments)
	local autocompletePrefix = ""
	local commandName = CAdmin.Util.PopFront (argumentList)
	if #argumentList == 0 then
		-- Just give a list of available commands which match the given fragment.
		return Commands.AutocompleteCommand (commandName, commandSource)
	end
	local autocompleteList = {}
	local command = Commands.GetCommand (commandName, commandSource)
	if not command then
		return {}
	end
	local argumentsData = command.Arguments
	argumentList = Commands.MergeLastArgument (argumentList, argumentsData)
	
	-- Build the autocomplete prefix.
	autocompletePrefix = commandName .. " "
	for i = 1, #argumentList - 1 do
		argumentList [i] = CAdmin.Util.QuoteConsoleString (argumentList [i])
		autocompletePrefix = autocompletePrefix .. argumentList [i]
		if argumentList [i] ~= "" then
			autocompletePrefix = autocompletePrefix .. " "
		end
	end
	
	local lastArgument = argumentsData [#argumentList]
	local givenLastArgument = argumentList [#argumentList]
	if lastArgument == nil then
		return {}
	end
	
	local playerCanExecute = true
	if lastArgument:CanAutocomplete () then
		autocompleteList = lastArgument:Autocomplete (givenLastArgument)
	elseif Commands.CanAutocompleteType (lastArgument:GetArgumentTypeName ()) then
		autocompleteList = Commands.AutocompleteType (givenLastArgument, lastArgument:GetArgumentTypeName ())
	end
	
	-- Now filter the autocomplete list.
	local ply = CLIENT and LocalPlayer ()
	for k, v in pairs (autocompleteList) do
		argumentList [#argumentList] = v
		if not Commands.CanExecute (ply, commandSource, commandName, unpack (argumentList)) then
			playerCanExecute = false
			autocompleteList [k] = nil
		end
	end
	autocompleteList = CAdmin.Util.ReindexArray (autocompleteList)
	table.sort (autocompleteList)
	CAdmin.Util.QuoteConsoleStrings (autocompleteList)

	--[[
		If the command can be executed, but no suggestions are available, show
		information about the arguments expected.
	]]
	if #autocompleteList == 0 and playerCanExecute then
		local str = lastArgument:GetName () or lastArgument:GetArgumentTypeName ()
		if str then
			if lastArgument:IsOptional () then
				autocompleteList = {"[" .. str .. "]"}
			else
				autocompleteList = {"<" .. str .. ">"}
			end
		end
	end
	return CAdmin.Util.PrependString (autocompleteList, autocompletePrefix)
end

--[[
	Autocompletes a command name.
]]
function Commands.AutocompleteCommand (commandName, commandSource)
	local searchList = Commands.Commands
	if commandSource == Commands.COMMAND_CONSOLE then
		searchList = Commands.ConsoleCommands
	elseif commandSource == Commands.COMMAND_CHAT then
		searchList = Commands.ChatCommands
	end
	
	local ply = (CLIENT and LocalPlayer ()) or CAdmin.Players.GetConsole ()
	local autocompleteCommands = {}
	commandName = commandName:lower ()
	local commandNameLength = commandName:len ()
	for k, _ in pairs (searchList) do
		if k:sub (1, commandNameLength) == commandName then
			if CAdmin.Commands.CanExecute (ply, commandSource, k) or CAdmin.Commands.CanExecute (ply, commandSource, k, "*") then
				autocompleteCommands [#autocompleteCommands + 1] = k
			end
		end
	end
	table.sort (autocompleteCommands)
	return autocompleteCommands
end

function Commands.AutocompleteType (argument, typeName)
	local typeInfo = Commands.GetType (typeName)
	if not typeInfo then
		return nil
	end
	return typeInfo:Autocomplete (argument)
end

--[[
	Returns whether a type can be autocompleted.
]]
function Commands.CanAutocompleteType (typeName)
	local typeInfo = Commands.GetType (typeName)
	if not typeInfo then
		return false
	end
	return typeInfo:CanAutocomplete ()
end

--[[
	Returns whether a player can execute a command.
	If no arguments are specified, it checks the players priveliges.
	First argument can be in table form, eg. Commands.CanExecute ("plugin_load_sv", {"Menu", "Bans", "Countdowns"})
	If arguments are given, it checks whether running the command is logically possible.
	Eg. "plugin_load_sv" can be called only with at least one unloaded plugin.
]]
function Commands.CanExecute (ply, commandSource, commandName, ...)
	if not commandName then
		CAdmin.Debug.PrintStackTrace ()
		return false, "No command specified."
	end
	commandName = commandName:lower ()
	local command = Commands.GetCommand (commandName, commandSource)
	
	-- Command not found, bail.
	if not command then
		return false, "Unable to find command \"" .. commandName .. "\"."
	end

	-- Called by console.
	if not ply or not ply:IsValid () then
		ply = CAdmin.Players.GetConsole ()
	end

	-- Command needs to be run by an in-game player, bail.
	if CAdmin.Players.IsConsole (ply) and command:IsClientRequired () then
		return false, "This command can only be run in-game."
	end

	-- Toggle commands.
	local isToggleCommand = command:IsToggleCommand ()
	local toggleArgument = nil
	if isToggleCommand then
		if commandSource == CAdmin.Commands.COMMAND_CONSOLE and commandName == command:GetConsoleCommand () or
			commandSource == CAdmin.Commands.COMMAND_CHAT and commandName == command:GetChatCommand () then
			toggleArgument = true
		else
			toggleArgument = false
		end
	end
	
	local fallbackCommands = Commands.GetFallbackCommands (command:GetCommandID ())
	
	-- Now start processing the arguments
	local argumentList = {...}
	local originalArgumentCount = #argumentList
	CAdmin.Util.RemoveEmptyTables (argumentList)
	local errorMessage = Commands.ConvertArguments (ply, command, argumentList)
	if errorMessage then
		return false, errorMessage
	end
	
	-- Merge the last string argument.
	Commands.MergeLastArgument (argumentList, command:GetArguments ())
	
	-- Insert the invisible toggle argument into the argument list.
	local noArguments = false
	if isToggleCommand then
		if #argumentList == 0 then
			noArguments = true
			argumentList [command:GetArgumentCount () + 1] = toggleArgument
		else
			argumentList [#argumentList + 1] = toggleArgument
		end
	end
	
	-- Separate the first argument.
	local firstArgument = CAdmin.Util.PopFront (argumentList)
	if firstArgument == nil then
		noArguments = true
		-- No first argument.
		if command:GetArgument (1) then
			-- Use the default optional value.
			firstArgument = command:GetArgument (1):GetDefaultValue () or Commands.ConvertArgument (ply, "", command:GetArgument (1):GetArgumentTypeName ()) or 0
		else
			-- Use any value, the argument shouldn't be looked at anyway.
			firstArgument = 0
		end
	end
	local enoughArguments = false
	if #argumentList >= command:GetMinimumArgumentCount () then
		enoughArguments = true
	end

	if Commands.GetArgumentTypeName (firstArgument) ~= "Table" then
		firstArgument = {firstArgument}
	end
	for _, argument in ipairs (firstArgument) do
		local invalidToggle = false
		if not command:IsAuthenticationRequired () then
			if noArguments then
				return true
			else
				if isToggleCommand then
					if toggleArgument == command.GetToggleState (argument, unpack (argumentList)) then
						invalidToggle = true
						if toggleArgument then
							errorMessage = errorMessage or "Command is already toggled on."
						else
							errorMessage = errorMessage or "Command is already toggled off."
						end
					end
				end
				local canExecute, failureReason = command.CanExecute (ply, argument, unpack (argumentList))
				if not invalidToggle and canExecute then
					return true
				end
				errorMessage = errorMessage or failureReason
			end
		else
			-- Authentication required.
			if CAdmin.IsServerRunning () and
				CAdmin.Priveliges.IsPlayerAuthorized (ply, commandName) then
				if noArguments then
					return true
				else
					if isToggleCommand then
						if toggleArgument == command.GetToggleState (argument, unpack (argumentList)) then
							invalidToggle = true
							if toggleArgument then
								errorMessage = errorMessage or "Command is already toggled on."
							else
								errorMessage = errorMessage or "Command is already toggled off."
							end
						end
					end
					if not invalidToggle and command.CanExecute (ply, argument, unpack (argumentList)) then
						return true
					end
				end
			else
				-- Authentication failed. Check if there are fallback commands.
				if fallbackCommands then
					for _, fallbackCommand in pairs (fallbackCommands) do
						invalidToggle = false
						if noArguments then
							if fallbackCommand.CanExecute (ply) then
								return true
							end
						else
							if isToggleCommand then
								local toggleState = command.GetToggleState (argument, unpack (argumentList))
								if fallbackCommand:IsToggleStateOveridden () then
									toggleState = toggleState or fallbackCommand.GetToggleState (argument, unpack (argumentList))
								end
								if toggleArgument == toggleState then
									invalidToggle = true
									if toggleArgument then
										errorMessage = errorMessage or "Command is already toggled on."
									else
										errorMessage = errorMessage or "Command is already toggled off."
									end
								end
							end
							if not invalidToggle and fallbackCommand.CanExecute (ply, argument, unpack (argumentList)) then
								return true
							end
						end
					end
				end
			end
		end
	end
	return false, errorMessage
end

--[[
	Convert an argument to the given type.
	May return nil, a single value or a table of values.
]]
function Commands.ConvertArgument (callingPly, argument, destTypeName, argumentDescription, usedForLog)
	if Commands.GetArgumentTypeName (argument) ~= "Table" then
		argument = {argument}
	end
	local errorMessage = nil
	local newArgument = {}
	local canConvert = false
	local destType = Commands.GetType (destTypeName)
	for _, v in ipairs (argument) do
		local srcTypeName = Commands.GetArgumentTypeName (v)
		local srcType = Commands.GetType (srcTypeName)
		if not srcType then
			CAdmin.Debug.PrintTable (v)
			errorMessage = errorMessage or "Failed to get type class for " .. tostring (srcTypeName) .. " (" .. tostring (v) .. ")."
		else
			if srcTypeName ~= destTypeName and not srcType:IsBaseType (destTypeName) then
				--[[
					Types are not the same, destination type is not a base type of source type.
					Conversion needed.
				]]
				local converted, failureReason = nil
				converted, failureReason = destType:Convert (callingPly, srcTypeName, v, usedForLog)
				errorMessage = errorMessage or failureReason
				
				if Commands.GetArgumentTypeName (converted) ~= "Table" then
					converted = {converted}
				end
				for _, v in ipairs (converted) do
					newArgument [#newArgument + 1] = v
				end
			else
				newArgument [#newArgument + 1] = v
			end
		end
	end
	if argumentDescription then
		local valid, reason = true, nil
		for k, v in ipairs (newArgument) do
			valid, reason = argumentDescription:Validate (callingPly, v)
			if not valid then
				errorMessage = errorMessage or reason
				newArgument [k] = nil
			end
		end
		CAdmin.Util.ReindexArray (newArgument)
	end
	if #newArgument == 0 then
		-- Table is empty
		return nil, errorMessage
	elseif #newArgument == 1 then
		-- Table has one item
		newArgument = newArgument [1]
	end
	return newArgument
end

--[[
	Converts an argument list to the required types.
]]
function Commands.ConvertArguments (callingPly, command, argumentList, usedForLog)
	local argumentCount = #argumentList
	local argumentDescriptions = command:GetArguments ()
	local errorMessage = nil
	local currentError = nil
	for i = 1, argumentCount do
		if argumentDescriptions [i] then
			argumentList [i], currentError = Commands.ConvertArgument (callingPly, argumentList [i], argumentDescriptions [i]:GetArgumentTypeName (), argumentDescriptions [i], usedForLog)
			errorMessage = errorMessage or currentError
		end
	end
	CAdmin.Util.RemoveEmptyTables (argumentList)
	return errorMessage
end

--[[
	Creates a command.
]]
function Commands.Create (commandID, commandCategory, displayName, toggle)
	commandCategory = commandCategory or "Miscellaneous"
	commandID = commandID:lower ()
	if Commands.Commands [commandID] then
		return Commands.Commands [commandID]
	end
	local command = CAdmin.Objects.Create ("Command", toggle)
		:SetDisplayName (displayName)
		:SetCategory (commandCategory)
		:SetCommandID (commandID)

	Commands.Categories [commandCategory] = Commands.Categories [commandCategory] or {}
	Commands.Categories [commandCategory] [commandID] = command
	Commands.CategoryCounts [commandCategory] = (Commands.CategoryCounts [commandCategory] or 0) + 1
	Commands.Commands [commandID] = command

	local commandPlugin = CAdmin.Plugins.GetRunningPlugin ()
	if commandPlugin then
		commandPlugin.Commands [commandID] = command
		command.Plugin = commandPlugin:GetName ()
	end
	CAdmin.Hooks.QueueBusyCall ("CAdminCommandsChanged")
	return command
end

--[[
	Creates a fallback command.
	The command ID must match the real command's ID.
]]
function Commands.CreateFallback (commandID, fallbackID)
	commandID = commandID:lower ()
	Commands.FallbackCommands [commandID] = Commands.FallbackCommands [commandID] or {}
	if Commands.FallbackCommands [commandID] [name] then
		return Commands.FallbackCommands [commandID] [name]
	end
	local fallbackCommand = CAdmin.Objects.Create ("Fallback Command")
	fallbackCommand:SetCommandID (commandID)
	fallbackCommand:SetDisplayName (fallbackID)

	Commands.FallbackCommands [commandID] [fallbackID] = fallbackCommand
	Commands.FallbackCommandCounts [commandID] = (Commands.FallbackCommandCounts [commandID] or 0) + 1

	local fallbackPlugin = CAdmin.Plugins.GetRunningPlugin ()
	if fallbackPlugin then
		fallbackPlugin.FallbackCommands [commandID] = fallbackPlugin.FallbackCommands [commandID] or {}
		fallbackPlugin.FallbackCommands [commandID] [fallbackID] = fallbackCommand
		fallbackPlugin.FallbackCommandCounts [commandID] = (fallbackPlugin.FallbackCommandCounts [commandID] or 0) + 1
		fallbackCommand.Plugin = fallbackPlugin:GetName ()
	end
	CAdmin.Hooks.QueueBusyCall ("CAdminCommandsChanged")
	return fallbackCommand
end

-- Removes a command
function Commands.Destroy (commandID)
	local command = Commands.Commands [commandID]
	if not command then
		return
	end
	if command:GetConsoleCommand () then
		Commands.ConsoleCommands [command:GetConsoleCommand ()] = nil
	end
	if command:GetReverseConsoleCommand () then
		Commands.ConsoleCommands [command:GetReverseConsoleCommand ()] = nil
	end
	if command:GetChatCommand () then
		Commands.ChatCommands [command:GetChatCommand ()] = nil
	end
	if command:GetReverseChatCommand () then
		Commands.ChatCommands [command:GetReverseChatCommand ()] = nil
	end

	local commandCategory = command:GetCategory ()
	if commandCategory then
		Commands.Categories [commandCategory] [commandID] = nil
		Commands.CategoryCounts [commandCategory] = Commands.CategoryCounts [commandCategory] - 1
		if Commands.CategoryCounts [commandCategory] == 0 then
			Commands.Categories [commandCategory] = nil
			Commands.CategoryCounts [commandCategory] = nil
		end
	end

	command:__uninit ()
	if command.Plugin then
		CAdmin.Plugins.GetPlugin (command.Plugin).Commands [commandID] = nil
		command.Plugin = nil
	end
	
	Commands.Commands [commandID] = nil
	CAdmin.Hooks.QueueBusyCall ("CAdminCommandsChanged")
end

-- Removes a fallback command
function Commands.DestroyFallback (commandID, fallbackID)
	if not Commands.FallbackCommands [commandID] then
		return
	end
	local fallbackCommand = Commands.FallbackCommands [commandID] [fallbackID]
	if not fallbackCommand then
		return
	end

	fallbackCommand:__uninit ()
	if fallbackCommand.Plugin then
		local commandPlugin = CAdmin.Plugins.GetPlugin (fallbackCommand.Plugin)
		commandPlugin.FallbackCommands [commandID] [fallbackID] = nil
		commandPlugin.FallbackCommandCounts [commandID] = commandPlugin.FallbackCommandCounts [commandID] - 1
		if commandPlugin.FallbackCommandCounts [commandID] == 0 then
			commandPlugin.FallbackCommands [commandID] = nil
			commandPlugin.FallbackCommandCounts [commandID] = nil
		end
		fallbackCommand.Plugin = nil
	end
	
	Commands.FallbackCommands [commandID] [fallbackID] = nil
	Commands.FallbackCommandCounts [commandID] = Commands.FallbackCommandCounts [commandID] - 1
	if Commands.FallbackCommandCounts [commandID] == 0 then
		Commands.FallbackCommands [commandID] = nil
		Commands.FallbackCommandCounts [commandID] = nil
	end
	
	CAdmin.Hooks.QueueBusyCall ("CAdminCommandsChanged")
end

--[[
	Runs a command.
]]
function Commands.Execute (ply, commandSource, commandName, ...)
	CAdmin.Profiler.EnterFunction ("CAdmin.Commands.Execute", commandName)
	if not commandName then
		CAdmin.Debug.PrintStackTrace ()
		CAdmin.Messages.TsayPlayer (ply, "No command specified.")
		CAdmin.Profiler.ExitFunction ("CAdmin.Commands.Execute", commandName)
		return
	end
	commandName = commandName:lower ()
	local command = Commands.GetCommand (commandName, commandSource)
	
	-- Command not found, bail.
	if not command then
		CAdmin.Messages.TsayPlayer (ply, "Command \"" .. commandName .. "\" not found.")
		CAdmin.Profiler.ExitFunction ("CAdmin.Commands.Execute", commandName)
		return
	end

	-- Called by console.
	if not ply or not ply:IsValid () then
		ply = CAdmin.Players.GetConsole ()
	end

	-- Command needs to be run by an in-game player, bail.
	if CAdmin.Players.IsConsole (ply) and command:IsClientRequired () then
		CAdmin.Messages.TsayPlayer (ply, "This command requires an in-game presence to run.")
		CAdmin.Profiler.ExitFunction ("CAdmin.Commands.Execute", commandName)
		return
	end

	-- Toggle commands
	local isToggleCommand = command:IsToggleCommand ()
	local consoleCommand = command:GetConsoleCommand ()
	local toggleArgument = nil
	if isToggleCommand then
		if commandSource == CAdmin.Commands.COMMAND_CONSOLE and commandName == command:GetConsoleCommand () or
			commandSource == CAdmin.Commands.COMMAND_CHAT and commandName == command:GetChatCommand () then
			toggleArgument = true
		else
			toggleArgument = false
			consoleCommand = command:GetReverseConsoleCommand ()
		end
	end

	local fallbackCommands = Commands.GetFallbackCommands (command:GetCommandID ())
	
	-- Now start processing the arguments
	local argumentList = {...}
	local originalArgumentCount = #argumentList
	CAdmin.Util.RemoveEmptyTables (argumentList)
	local oldArgumentList = table.Copy (argumentList)
	
	--[[
		Stick in optional arguments for toggle commands.
		Do this before argument conversion because
		optional arguments may default to "^" or suchlike.
	]]
	if isToggleCommand then
		for k, v in pairs (command:GetArguments ()) do
			if argumentList [k] == nil then
				argumentList [k] = v:GetDefaultValue ()
			end
		end
	end
	
	-- Process the arguments.
	local errorMessage = Commands.ConvertArguments (ply, command, argumentList)
	if errorMessage then
		CAdmin.Messages.TsayPlayer (ply, errorMessage)
		CAdmin.Profiler.ExitFunction ("CAdmin.Commands.Execute", commandName)
		return
	end
	
	-- Merge the last string argument.
	Commands.MergeLastArgument (argumentList, command:GetArguments ())
	
	-- Preliminary test.
	if not Commands.CanExecute (ply, commandSource, commandName) and not Commands.CanExecute (ply, commandSource, commandName, "*") then
		CAdmin.Messages.TsayPlayer (ply, "You don't have access to this command, " .. ply:Name () .. ".")
		CAdmin.Profiler.ExitFunction ("CAdmin.Commands.Execute", commandName)
		return
	end
	
	-- Not enough arguments, bail.
	if #argumentList < command:GetMinimumArgumentCount () then
		CAdmin.Messages.TsayPlayer (ply, "Not enough valid parameters for command \"" .. commandName .. "\".")
		CAdmin.Profiler.ExitFunction ("CAdmin.Commands.Execute", commandName)
		return
	end
	
	-- Insert the invisible toggle argument into the argument list.
	if isToggleCommand then
		argumentList [#argumentList + 1] = toggleArgument
	end
	
	-- Separate the first argument.
	local firstArgument = CAdmin.Util.PopFront (argumentList)
	if firstArgument == nil then
		-- No first argument.
		if command:GetArgument (1) then
			-- Use the default optional value.
			firstArgument = command:GetArgument (1):GetDefaultValue () or Commands.ConvertArgument (ply, "", command:GetArgument (1):GetArgumentTypeName ()) or 0
		else
			-- Use any value, the argument shouldn't be looked at anyway.
			firstArgument = 0
		end
	end
	if Commands.GetArgumentTypeName (firstArgument) ~= "Table" then
		firstArgument = {firstArgument}
	end
	
	-- Below this point, the client _should_ have access rights to run the command.
	
	local shouldRunServerside = false
	-- Check if the command should be forwarded to the server.
	if CAdmin.IsServerRunning () and
		CAdmin.Priveliges.IsPlayerAuthorized (ply, consoleCommand, firstArgument, unpack (argumentList)) and
		command:IsRunServerside () then
		shouldRunServerside = true
	end
	if CLIENT then
		if shouldRunServerside then
			-- Prepare to forward the command.
			-- Convert all arguments back to strings.
			CAdmin.Util.PushFront (argumentList, firstArgument)
			for k, v in ipairs (argumentList) do
				local argumentDescription = command:GetArgument (k)
				if argumentDescription then
					local srcType = argumentDescription:GetArgumentTypeName ()
					if srcType ~= destType then
						local converted, failureReason = Commands.ConvertArgument (ply, v, "String")
						if converted then
							argumentList [k] = converted
						else
							CAdmin.Messages.TsayPlayer (ply, failureReason)
							CAdmin.Profiler.ExitFunction ("CAdmin.Commands.Execute", commandName)
							return
						end
					end
				end
			end
			CAdmin.Console.ForwardCommand (LocalPlayer (), "cadmin", consoleCommand, unpack (argumentList))
			CAdmin.Profiler.ExitFunction ("CAdmin.Commands.Execute", commandName)
			return
		end
	end
	
	-- Run the command locally.
	local logString = command:GetLogString ()
	if isToggleCommand and not toggleArgument then
		logString = command:GetReverseLogString () or logString
	end

	local usedTargets = {}
	local usedCommands = {}
	CAdmin.Settings.IncreaseSession ("CAdmin.Busy")
	for _, argument in pairs (firstArgument) do
		local canExecute, reason = Commands.CanExecute (ply, commandSource, commandName, argument, unpack (argumentList))
		if not canExecute then
			errorMessage = errorMessage or reason
		else
			usedTargets [#usedTargets + 1] = argument
			if CLIENT then
				if not command:IsAuthenticationRequired () then
					-- Can run the command, since it does not require access rights.
					command.Execute (ply, argument, unpack (argumentList))
					usedCommands [tostring (command)] = command
				elseif fallbackCommands then
					-- Otherwise, use fallback commands.
					local done = false
					for k, v in pairs (fallbackCommands) do
						if v:GetFallbackType () == CAdmin.FALLBACK_ADMIN and v.CanExecute (ply, argument, unpack (argumentList)) then
							v.Execute (ply, argument, unpack (argumentList))
							usedCommands [tostring (v)] = v
							local newLogString = v:GetLogString ()
							if isToggleCommand and not toggleArgument then
								newLogString = v:GetReverseLogString () or newLogString
							end
							logString = newLongString or logString
							if v:ShouldSuppressLog () then
								logString = nil
							end
							done = true
							break
						end
					end
					for k, v in pairs (fallbackCommands) do
						if done then
							break
						end
						if v:GetFallbackType () == CAdmin.FALLBACK_DEFAULT and v.CanExecute (ply, argument, unpack (argumentList)) then
							v.Execute (ply, argument, unpack (argumentList))
							usedCommands [tostring (v)] = v
							local newLogString = v:GetLogString ()
							if isToggleCommand and not toggleArgument then
								newLogString = v:GetReverseLogString () or newLogString
							end
							logString = newLogString or logString
							if v:ShouldSuppressLog () then
								logString = nil
							end
							done = true
							break
						end
					end
				end
			elseif SERVER then
				-- Already authenticated, no more checks.
				command.Execute (ply, argument, unpack (argumentList))
				usedCommands [tostring (command)] = command
			end
		end
	end
	CAdmin.Settings.DecreaseSession ("CAdmin.Busy")
	for _, v in pairs (usedCommands) do
		v:PostExecute (ply, firstArgument, unpack (argumentList))
	end
	if #usedTargets == 0 then
		CAdmin.Messages.TsayPlayer (ply, errorMessage)
		CAdmin.Profiler.ExitFunction ("CAdmin.Commands.Execute", commandName)
		return
	end
	if isToggleCommand then
		CAdmin.RPC.FireEvent ("CAdminCommandToggleStatesChanged")
	end
	
	-- Logging
	-- Pad optional arguments for logging.
	for k, v in ipairs (command.Arguments) do
		if v.Optional ~= nil and k > 1 and argumentList [k - 1] == nil then
			if type (v.Optional) == "function" then
				argumentList [k - 1] = v.Optional ()
			else
				argumentList [k - 1] = v.Optional
			end
		end
	end
	if command:GetArgumentCount () == 0 then
		usedTargets = {}
	end
	CAdmin.Messages.LogCommand ({Player = ply, Targets = usedTargets, LogString = logString, AffectedCount = #usedTargets, Arguments = argumentList})
	CAdmin.Profiler.ExitFunction ("CAdmin.Commands.Execute", commandName)
end

local function SortCommandFunction (a, b)
	return a:GetCommandID () < b:GetCommandID ()
end

--[[
	Finds all commands by the first argument type.
]]
function Commands.FindByArgument (typeName)
	local found = {}
	for _, command in pairs (Commands.Commands) do
		if command:OperatesOnType (typeName) then
			found [#found + 1] = command
		end
	end
	table.sort (found, SortCommandFunction)
	return found
end

function Commands.FixArgumentSpaces (arguments)
	local newargs = {}
	local mergenext = false
	local str = nil
	for k, v in ipairs (arguments) do
		if type (v) == "string" then
			local merge = false
			if mergenext then
				merge = true
				mergenext =  false
			end
			if not merge and v:len () == 1 and v:byte () > 127 then
				mergenext = true
			end
			if merge and type (newargs [#newargs]) ~= "string" then
				merge = false
			end
			if merge then
				newargs [#newargs] = newargs [#newargs] .. v
				merge = false
			else
				table.insert (newargs, v)
			end
		else
			table.insert (newargs, v)
		end
	end
	return newargs
end

--[[
	Returns the argument type.
]]
local argumentTypeNames = {
	["boolean"] = "Boolean",
	["number"] = "Number",
	["string"] = "String",
	["table"] = "Table"
}
function Commands.GetArgumentTypeName (argument)
	local argumentTypeName = type (argument)
	if argumentTypeName == "table" then
		if argument.GetType then
			argumentTypeName = argument:GetType () or argumentTypeName
		else
			return "Table"
		end
	end
	return argumentTypeNames [argumentTypeName] or argumentTypeName
end

function Commands.GetChatCommand (chatCommand)
	if not chatCommand then
		return nil
	end
	return Commands.ChatCommands [chatCommand:lower ()]
end

--[[
	Returns a command with the given command ID.
]]
function Commands.GetCommand (commandName, commandSource)
	if not commandName then
		return nil
	end
	commandName = commandName:lower ()
	commandSource = commandSource or CAdmin.Commands.COMMAND_ID
	if commandSource == CAdmin.Commands.COMMAND_CONSOLE then
		return Commands.ConsoleCommands [commandName]
	elseif commandSource == CAdmin.Commands.COMMAND_CHAT then
		return Commands.ChatCommands [commandName]
	end
	return Commands.Commands [commandName]
end

--[[
	Returns the full list of commands.
]]
function Commands.GetCommands ()
	return Commands.Commands
end

--[[
	Returns a command with the given console command.
]]
function Commands.GetConsoleCommand (consoleCommand)
	if not consoleCommand then
		return nil
	end
	return Commands.ConsoleCommands [consoleCommand:lower ()]
end

--[[
	Returns the full list of console commands.
]]
function Commands.GetConsoleCommands ()
	return Commands.ConsoleCommands
end

--[[
	Returns the full list of fallback commands.
]]
function Commands.GetFallbackCommands (commandName)
	if commandName then
		return Commands.FallbackCommands [commandName]
	end
	return nil
end

function Commands.GetType (argumentType)
	return Commands.Types [argumentType]
end

function Commands.GetTypes ()
	return Commands.Types
end

function Commands.IsCommandToggleOn (ply, commandSource, commandName, ...)
	if not commandName then
		CAdmin.Debug.PrintStackTrace ()
		return false, "No command specified."
	end
	commandName = commandName:lower ()
	local command = Commands.GetCommand (commandName, commandSource)
	
	-- Command not found, bail.
	if not command then
		return false, "Unable to find command \"" .. commandName .. "\"."
	end

	-- Called by console.
	if not ply or not ply:IsValid () then
		ply = CAdmin.Players.GetConsole ()
	end

	-- Command needs to be run by an in-game player, bail.
	if CAdmin.Players.IsConsole (ply) and command:IsClientRequired () then
		return false, "This command can only be run in-game."
	end

	-- Toggle commands.
	local isToggleCommand = command:IsToggleCommand ()
	local toggleArgument = nil
	if isToggleCommand then
		if commandSource == CAdmin.Commands.COMMAND_CONSOLE and commandName == command:GetConsoleCommand () or
			commandSource == CAdmin.Commands.COMMAND_CHAT and commandName == command:GetChatCommand () then
			toggleArgument = true
		else
			toggleArgument = false
		end
	else
		return false, "This command is not a toggle command."
	end
	
	local fallbackCommands = Commands.GetFallbackCommands (command:GetCommandID ())
	
	-- Now start processing the arguments
	local argumentList = {...}
	local originalArgumentCount = #argumentList
	CAdmin.Util.RemoveEmptyTables (argumentList)
	local errorMessage = Commands.ConvertArguments (ply, command, argumentList)
	if errorMessage then
		-- Failed to convert all arguments.
		return false, errorMessage
	end
	
	-- Merge the last string argument.
	Commands.MergeLastArgument (argumentList, command:GetArguments ())
		
	-- Not enough arguments given.
	if #argumentList == 0 and #command:GetArgumentCount () >= 1 then
		return false
	end
	
	if command:IsAuthenticationRequired () and CAdmin.Priveliges.IsPlayerAuthorized (ply, command:GetConsoleCommand () or command.CommandName) then
		return command.GetToggleState (unpack (argumentList))
	else
		-- Fallback
		local realToggleState = command.GetToggleState (unpack (argumentList))
		local toggleState = false
		if fallbackCommands then
			for _, fallbackCommand in pairs (fallbackCommands) do
				toggleState = realToggleState
				if fallbackCommand.GetToggleState then
					toggleState = fallbackCommand.GetToggleState (unpack (argumentList))
				end
				if toggleState then
					return true
				end
			end
		end
		return realToggleState
	end
end

--[[
	Converts all string arguments to lowercase.
]]
function Commands.LowercaseArguments (argumentList)
	for k, v in ipairs (argumentList) do
		if Commands.GetArgumentTypeName (v) == "String" then
			argumentList [k] = v:lower ()
		end
	end
	return argumentList
end

--[[
	If the last argument takes a string, and there are excess arguments,
	this merges the excess arguments into the string.
]]
function Commands.MergeLastArgument (argumentList, argumentDescriptions)
	if #argumentList > #argumentDescriptions then
		if #argumentDescriptions > 0 and argumentDescriptions [#argumentDescriptions]:GetArgumentTypeName () == "String" then
			local baseString = argumentList [#argumentDescriptions]
			local argumentCount = #argumentList
			for i = #argumentDescriptions + 1, argumentCount do
				baseString = baseString .. " " .. argumentList [i]
				argumentList [i] = nil
			end
			argumentList [#argumentDescriptions] = baseString
		end
	end
	return argumentList
end

function Commands.ParseChatCommand (chatText)
	local firstCharacter = chatText:sub (1, 1)
	if firstCharacter ~= "!" and
	   firstCharacter ~= "/" and
	   firstCharacter ~= "#" then
		return nil, nil
	end
	chatText = chatText:sub (2)
	local commandArguments = CAdmin.Util.ExplodeQuotedString (chatText)
	return firstCharacter, commandArguments
end

function Commands.RegisterType (typeName, baseType)
	local type = Commands.Types [typeName]
	if type then
		print ("Tried to reregister type " .. typeName .. ".")
		CAdmin.Debug.PrintStackTrace ()
		type:SetBaseType (baseType)
		CAdmin.Profiler.ExitFunction ()
		return type
	end
	type = CAdmin.Objects.Create ("Type", typeName, baseType)
	Commands.Types [typeName] = type
	return type
end

function Commands.TranslateChatCommand (chatCommand)
	chatCommand = chatCommand:lower ()

	local command = Commands.ChatCommands [chatCommand]
	if not command then
		return nil, nil
	end
	
	if command:IsToggleCommand () then
		if command:GetChatCommand () == chatCommand then
			return command:GetCommandID (), true
		elseif command:GetReverseChatCommand () == chatCommand then
			return command:GetCommandID (), false
		end
	end
	return command:GetCommandID (), nil
end

function Commands.TranslateConsoleCommand (consoleCommand)
	consoleCommand = consoleCommand:lower ()

	local command = Commands.ConsoleCommands [consoleCommand]
	if not command then
		return nil, nil
	end
	
	if command:IsToggleCommand () then
		if command:GetConsoleCommand () == consoleCommand then
			return command:GetCommandID (), true
		elseif command:GetReverseConsoleCommand () == consoleCommand then
			return command:GetCommandID (), false
		end
	end
	return command:GetCommandID (), nil
end

CAdmin.Lua.IncludeFolder ("shared/includes/types")

local function RegisterCAdminCommand ()
	CAdmin.Console.AddCommand ("cadmin", function (ply, _, args)
		if ply and not ply:IsValid () then
			ply = nil
		end
		local commandName = CAdmin.Util.PopFront (args)
		args = Commands.FixArgumentSpaces (args)
		if not commandName then
			CAdmin.Messages.TsayPlayer (ply or CAdmin.Players.GetConsole (), "No command specified.")
			return
		end
		Commands.Execute (ply, CAdmin.Commands.COMMAND_CONSOLE, commandName, unpack (args))
	end, function (cmd, args)
		return CAdmin.Util.PrependString (Commands.Autocomplete (CAdmin.Commands.COMMAND_CONSOLE, args), cmd .. " ")
	end)
end

CAdmin.Hooks.Add ("CAdminInitialize", "CAdmin.Commands.Initialize", function ()
	CAdmin.Hooks.Add ("CAdminPluginLoaded", "CAdmin.Commands.PluginLoaded", function (pluginList)
		for _, plugin in pairs (pluginList) do
			plugin.Commands = {}
			plugin.FallbackCommands = {}
			plugin.FallbackCommandCounts = {}
		end
	end)

	CAdmin.Hooks.Add ("CAdminPluginUnloaded", "CAdmin.Commands.PluginUnloaded", function (pluginList)
		for _, plugin in pairs (pluginList) do
			for commandID, _ in pairs (plugin.Commands) do
				Commands.Destroy (commandID)
			end
			for commandID, fallbackTable in pairs (plugin.FallbackCommands) do
				for fallbackName, _ in pairs (fallbackTable) do
					Commands.DestroyFallback (commandID, fallbackName)
				end
			end
			plugin.Commands = nil
			plugin.FallbackCommands = nil
			plugin.FallbackCommandCounts = nil
		end
	end)

	if CLIENT then
		RegisterCAdminCommand ()
	elseif SERVER then
		if isDedicatedServer () then
			RegisterCAdminCommand ()
		else
			if CAdmin.Players.GetPlayerCount () == 0 then
				CAdmin.Hooks.Add ("CAdminPlayerConnected", "CAdmin.Commands.RegisterConsoleCommand", function ()
					RegisterCAdminCommand ()
					CAdmin.Hooks.Remove ("CAdminPlayerConnected", "CAdmin.Commands.RegisterConsoleCommand")
				end)
			else
				RegisterCAdminCommand ()
			end
		end
	end
end)

CAdmin.Hooks.Add ("CAdminUninitialize", "CAdmin.Commands.Uninitialize", function ()
	for k, _ in pairs (Commands.Commands) do
		Commands.Destroy (k)
	end
	for k, t in pairs (Commands.FallbackCommands) do
		for _, v in pairs (t) do
			Commands.DestroyFallback (k, v)
		end
	end
end)