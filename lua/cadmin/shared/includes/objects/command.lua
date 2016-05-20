local OBJ = CAdmin.Objects.Register ("Command")

function OBJ:__init (toggle)
	-- Calls
	self.DisplayName = nil			-- Displayed text: eg. Jail
	self.ReverseDisplayName = nil		-- Displayed text: eg. Unjail
	self.CommandID = nil			-- Internal name, used only for sorting: eg. jail
	self.ConsoleCommand = nil		-- CAdmin console command, used for access lists
	self.ReverseConsoleCommand = nil	-- CAdmin reverse console command, used for access lists
	self.ChatCommand = nil
	self.ReverseChatCommand = nil
	self.Category = nil

	-- Arguments
	self.Arguments = {}
	self.ArgumentCount = 0
	self.MinimumArgumentCount = 0

	self.ToggleCommand = false		-- Does the command take an invisible boolean argument?
	if toggle then
		self.ToggleCommand = true
	end

	-- Access
	self.AuthenticationRequired = true
	self.RequiresClientToRun = false
	self.RunLocation = CAdmin.Commands.RUN_SERVER
	
	--[[
		TODO: Rewrite this.
	]]
	self.AllowConsole = true
	self.ClientCanExecute = false		-- Checked only for COMMAND_SHARED commands.

	self.CommandType = CAdmin.COMMAND_SERVER
	
	-- Logging
	self.LogString = nil
	self.ReverseLogString = nil
end

function OBJ:AddArgument (type, name, optional, autocomplete, ...)
	local argument = CAdmin.Objects.Create ("Argument", type, name, optional, autocomplete, ...)
	self.Arguments [#self.Arguments + 1] = argument
	self.ArgumentCount = self.ArgumentCount + 1

	argument:SetName (name)
	if optional == nil then
		self.MinimumArgumentCount = self.MinimumArgumentCount + 1
	else
		argument:SetOptional (true, optional)
	end
	argument:SetAutocomplete (autocomplete)

	return argument
end

function OBJ:ArgumentTypeMatches (givenArgumentTypeName, argumentID)
	if not type or not self.Arguments [argumentID] then
		return false
	end
	local argumentTypeName = self.Arguments [argumentID]:GetArgumentTypeName ()
	if givenArgumentTypeName == argumentTypeName then
		return true
	end
	if self.Arguments [argumentID]:GetArgumentType ():IsBaseType (givenArgumentTypeName) then
		return true
	end
end

function OBJ:CanClientExecute (ply, ...)
	return self.ClientCanExecute
end

function OBJ:CanExecute (ply, ...)
	return true
end

function OBJ:CanRunLocally ()
	return self.RunLocation == CAdmin.Commands.RUN_LOCAL or self.RunLocation == CAdmin.Commands.RUN_BOTH
end

function OBJ:Execute (ply, ...)
end

function OBJ:GetArgument (argumentID)
	return self.Arguments [argumentID]
end

function OBJ:GetArguments ()
	return self.Arguments
end

function OBJ:GetArgumentCount ()
	return self.ArgumentCount
end

function OBJ:GetAssociatedType ()
	if self.AssociatedType then
		return self.AssociatedType
	end
	if self.ArgumentCount > 0 then
		return self.Arguments [1]:GetArgumentType ()
	end
end

function OBJ:GetCategory ()
	return self.Category
end

function OBJ:GetChatCommand ()
	return self.ChatCommand
end

function OBJ:GetCommandID ()
	return self.CommandID
end

function OBJ:GetCommandType ()
	return self.CommandType
end

function OBJ:GetConsoleCommand ()
	return self.ConsoleCommand
end

function OBJ:GetDisplayName ()
	return self.DisplayName
end

function OBJ:GetLogString ()
	return self.LogString
end

function OBJ:GetMinimumArgumentCount ()
	return self.MinimumArgumentCount
end

function OBJ:GetReverseChatCommand ()
	return self.ReverseChatCommand
end

function OBJ:GetReverseConsoleCommand ()
	return self.ReverseConsoleCommand
end

function OBJ:GetReverseDisplayName ()
	return self.ReverseDisplayName or self.DisplayName
end

function OBJ:GetReverseLogString ()
	return self.ReverseLogString
end

function OBJ:GetRunLocation ()
	return self.RunLocation
end

function OBJ:GetToggleState (arguments)
	return false
end

function OBJ:IsAuthenticationRequired ()
	return self.AuthenticationRequired
end

function OBJ:IsClientRequired ()
	return self.RequiresClientToRun
end

function OBJ:IsConsoleAllowed ()
	return self.AllowConsole
end

function OBJ:IsRunServerside ()
	return self.RunLocation == CAdmin.Commands.RUN_SERVER or self.RunLocation == CAdmin.Commands.RUN_BOTH
end

function OBJ:IsToggleCommand ()
	return self.ToggleCommand
end

function OBJ:OperatesOnType (argumentType)
	if self.Arguments [1] and self.Arguments [1]:GetArgumentTypeName () == argumentType then
		return true
	end
	if self.AssociatedType == argumentType and argumentType then
		return true
	end
	return false
end

function OBJ:PostExecute (...)
	if self.PostExecuteFunc then
		self.PostExecuteFunc (...)
	end
end

function OBJ:SetAllowConsole (allowConsole)
	self.AllowConsole = allowConsole
	return self
end

function OBJ:SetAuthenticationRequired (authenticationRequired)
	self.AuthenticationRequired = authenticationRequired
	if SERVER then
		self.AuthenticationRequired = true
	end
	return self
end

function OBJ:SetAssociatedType (argumentType)
	self.AssociatedType = argumentType
	return self
end

function OBJ:SetCanExecute (canExecuteFunc)
	self.CanExecute = canExecuteFunc
	return self
end

function OBJ:SetCategory (category)
	self.Category = category
	return self
end

function OBJ:SetClientCanExecute (clientCanExecute)
	self.ClientCanExecute = clientCanExecute
	return self
end

function OBJ:SetCommandID (commandID)
	self.CommandID = commandID
	return self
end

function OBJ:SetChatCommand (chatCommand)
	if self.ChatCommand then
		CAdmin.Commands.ChatCommands [self.ChatCommand] = nil
	end
	chatCommand = chatCommand:lower ()
	self.ChatCommand = chatCommand
	CAdmin.Commands.ChatCommands [chatCommand] = self
	return self
end

function OBJ:SetConsoleCommand (consoleCommand)
	if self.ConsoleCommand then
		CAdmin.Commands.ConsoleCommands [self.ConsoleCommand] = nil
	end
	consoleCommand = consoleCommand:lower ()
	self.ConsoleCommand = consoleCommand
	CAdmin.Commands.ConsoleCommands [consoleCommand] = self

	if not self:GetChatCommand () then
		self:SetChatCommand (consoleCommand)
	end
	return self
end

function OBJ:SetDisplayName (displayName)
	self.DisplayName = displayName
	return self
end

function OBJ:SetExecute (executeFunc)
	self.Execute = executeFunc
	return self
end

function OBJ:SetGetToggleState (getToggleStateFunc)
	self.GetToggleState = getToggleStateFunc
	return self
end

function OBJ:SetLastArgumentDisallowMultiple (disallowMultiple)
	self.Arguments [self.ArgumentCount].AllowMultiple = not disallowMultiple
	return self
end

function OBJ:SetLastArgumentDisallowSelf (disallowCallingPlayer)
	self.Arguments [self.ArgumentCount].AllowSelf = not disallowCallingPlayer
	return self
end

function OBJ:SetLogString (logString)
	self.LogString = logString
	return self
end

function OBJ:SetPostExecute (postExecuteFunc)
	self.PostExecuteFunc = postExecuteFunc
	return self
end

function OBJ:SetRequiresClient (requiresClient)
	if requiresClient == nil then
		requiresClient = true
	end
	self.RequiresClientToRun = clientOnly
	return self
end

function OBJ:SetReverseChatCommand (reverseChatCommand)
	if self.ReverseChatCommand then
		CAdmin.Commands.ChatCommands [self.ReverseChatCommand] = nil
	end
	reverseChatCommand = reverseChatCommand:lower ()
	self.ReverseChatCommand = reverseChatCommand
	CAdmin.Commands.ChatCommands [reverseChatCommand] = self
	return self
end

function OBJ:SetReverseConsoleCommand (reverseConsoleCommand)
	if self.ReverseConsoleCommand then
		CAdmin.Commands.ConsoleCommands [self.ReverseConsoleCommand] = nil
	end
	reverseConsoleCommand = reverseConsoleCommand:lower ()
	self.ReverseConsoleCommand = reverseConsoleCommand
	CAdmin.Commands.ConsoleCommands [reverseConsoleCommand] = self

	if not self:GetReverseChatCommand () then
		self:SetReverseChatCommand (reverseConsoleCommand)
	end
	return self
end

function OBJ:SetReverseLogString (logString)
	self.ReverseLogString = logString
	return self
end

function OBJ:SetReverseDisplayName (reverseDisplayName)
	self.ReverseDisplayName = reverseDisplayName
	return self
end

function OBJ:SetRunLocation (runLocation)
	self.RunLocation = runLocation
	return self
end

function OBJ:SetToggleCommand (isToggleCommand)
	self.ToggleCommand = isToggleCommand
	return self
end

function OBJ:SetCommandType (commandType)
	self.CommandType = commandType
	return self
end