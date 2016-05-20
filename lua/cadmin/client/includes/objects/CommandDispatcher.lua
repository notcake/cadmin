local OBJ = CAdmin.Objects.Register ("Command Dispatcher")

function OBJ:__init (consoleCommand)
	self.FilledArguments = {}
	self.ProvidedArguments = {}
	
	self.ConsoleCommand = consoleCommand
	self.Command = CAdmin.Commands.GetConsoleCommand (consoleCommand)
	self.ArgumentsNeeded = self.Command:GetArguments ()
	self.ToggleArgument = true
	if self.Command:GetConsoleCommand () ~= consoleCommand then
		self.ToggleArgument = false
	end
	
	self.ExecuteCallback = nil
	self.ExecuteCallbackData = nil
end

function OBJ:__uninit ()
	self.Command = nil
	self.ArgumentsNeeded = nil
	
	self.FilledArguments = nil
	self.ProvidedArguments = nil
	self.ExecuteCallback = nil
	self.ExecuteCallbackData = nil
end

function OBJ:AddArgument (argumentTypeName, argument)
	self.ProvidedArguments [argumentTypeName] = self.ProvidedArguments [argumentTypeName] or {}
	local argumentsOfType = self.ProvidedArguments [argumentTypeName]
	argumentsOfType [#argumentsOfType + 1] = argument
	
	for k, _ in ipairs (self.ArgumentsNeeded) do
		if not self.FilledArguments [k] and self.ArgumentsNeeded [k]:GetArgumentTypeName () == argumentTypeName then
			self.FilledArguments [k] = argument
			break
		end
	end
end

function OBJ:GetConsoleCommand ()
	return self.ConsoleCommand
end

function OBJ:DispatchCommand ()
	for k, v in ipairs (self.ArgumentsNeeded) do
		if not self.FilledArguments [k] then
			self:RequestArgument (k)
			return
		end
	end
	CAdmin.Commands.Execute (LocalPlayer (), CAdmin.Commands.COMMAND_CONSOLE, self.ConsoleCommand, unpack (self.FilledArguments))
	if self.ExecuteCallback then
		self.ExecuteCallback (self.ExecuteCallbackData, self.ConsoleCommand)
	end
end

function OBJ:RequestArgument (argumentID)
	local argumentData = self.ArgumentsNeeded [argumentID]
	local argumentPrompt = CAdmin.GUI.Create ("CArgumentPrompt")
	argumentPrompt:SetDispatcher (self)
	argumentPrompt:SetConsoleCommand (self.ConsoleCommand)
	argumentPrompt:SetToggleArgument (self.ToggleArgument)
	argumentPrompt:SetArguments (self.FilledArguments)
	argumentPrompt:SetMissingArgument (argumentData)
	argumentPrompt:CreateCompleter (argumentData:GetArgumentType ():GetCompleter ())
end

function OBJ:SetConsoleCommand (consoleCommand)
	self.ConsoleCommand = consoleCommand
	self.Command = CAdmin.Commands.GetConsoleCommand (consoleCommand)
	self.ArgumentsNeeded = self.Command:GetArguments ()
end

function OBJ:SetExecuteCallback (executeCallbackFunc, callbackData)
	self.ExecuteCallback = executeCallbackFunc
	self.ExecuteCallbackData = callbackData
end