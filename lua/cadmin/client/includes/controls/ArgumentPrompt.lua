local PANEL = {}

local function DoneClick (button)
	button.ArgumentPrompt:OnDone ()
end

function PANEL:Init ()
	self.ArgumentCompleter = nil
	self.CommandDispatcher = nil
	self.MissingArgument = nil
	
	self.ConsoleCommand = nil
	self.DisplayName = nil
	self.FilledArguments = nil
	self.ToggleArgument = nil
	
	self.Done = self:Create ("DButton")
	self.Done.ArgumentPrompt = self
	self.Done.DoClick = DoneClick
	self.Done:SetTall (20)
	self.Done:SetText ("Done")
	
	self.Desc = nil
end

function PANEL:Uninit ()
	self.CommandDispatcher = nil
	self.FilledArguments = nil
	self.MissingArgument = nil
end

function PANEL:CreateCompleter (completerClass)
	if self.ArgumentCompleter then
		self.ArgumentCompleter:Remove ()
		self.ArgumentCompleter = nil
	end
	self.ArgumentCompleter = self:Create (completerClass)
	self.ArgumentCompleter:SetArgumentPrompt (self)
	self.ArgumentCompleter:SetArgumentInfo (self.MissingArgument)
	self.ArgumentCompleter:DoLayout ()
	
	if self.MissingArgument:GetLastValue () then
		self.ArgumentCompleter:SetArgumentValue (self.MissingArgument:GetLastValue ())
	end
	
	local description = self.MissingArgument:GetPromptText ()
	if not self.ToggleArgument then
		description = self.MissingArgument:GetReversePromptText ()
	end
	if description then
		self.Desc = self:Create ("DLabel")
		self.Desc:SetText (description)
	end
	
	self:MakePopup ()
	self:Center ()
	self:SetTitle (self.ArgumentCompleter:GetTitle ())
end

function PANEL:GetConsoleCommand ()
	return self.ConsoleCommand
end

function PANEL:GetDispatcher ()
	return self.CommandDispatcher
end

function PANEL:GetDisplayName ()
	return self.DisplayName
end

function PANEL:GetMissingArgument ()
	return self.MissingArgument
end

function PANEL:OnDone ()
	local argument = self.ArgumentCompleter:GetArgumentValue ()
	self.MissingArgument:SetLastValue (argument)
	self.CommandDispatcher:AddArgument (self.MissingArgument:GetArgumentTypeName (), argument)
	self.CommandDispatcher:DispatchCommand ()
	self:Remove ()
end

function PANEL:PerformLayout ()
	local padding = self:GetPadding ()

	local contentWidth = 0
	local contentHeight = 0
	local contentCount = 0
	if self.Desc then
		self.Desc:SetPos (padding, 24 + contentCount * padding + padding)
		self.Desc:SetWide (self:GetWide () - 2 * padding)
		contentHeight = contentHeight + self.Desc:GetTall ()
		contentCount = 1
	end
	
	if self.ArgumentCompleter then
		self.ArgumentCompleter:PerformLayout (true)
		self.ArgumentCompleter:SetPos (padding, 24 + contentHeight + contentCount * padding + padding)
		contentWidth = self.ArgumentCompleter:GetWide ()
		contentHeight = contentHeight + self.ArgumentCompleter:GetTall ()
		contentCount = contentCount + 1
	end
	
	self.Done:SetPos (self:GetWide () - padding - self.Done:GetWide (), 24 + contentHeight + contentCount * padding + padding)
	contentHeight = contentHeight + self.Done:GetTall ()
	contentCount = contentCount + 1
	
	contentCount = contentCount - 1
	self:SetSize (contentWidth + 2 * padding, 24 + contentHeight + contentCount * padding + 2 * padding)
end

function PANEL:SetArguments (filledArguments)
	self.FilledArguments = filledArguments
	return self
end

function PANEL:SetConsoleCommand (consoleCommand)
	self.ConsoleCommand = consoleCommand
	local command = CAdmin.Commands.GetConsoleCommand (consoleCommand)
	self:SetDisplayName (command:GetDisplayName ())
	
	if command:IsToggleCommand () and command:GetConsoleCommand () ~= consoleCommand then
		self:SetDisplayName (command:GetReverseDisplayName ())
	end
	return self
end

function PANEL:SetDispatcher (commandDispatcher)
	self.CommandDispatcher = commandDispatcher
	return self
end

function PANEL:SetDisplayName (displayName)
	self.DisplayName = displayName
	return self
end

function PANEL:SetMissingArgument (missingArgumentData)
	self.MissingArgument = missingArgumentData
	return self
end

function PANEL:SetToggleArgument (toggleArgument)
	self.ToggleArgument = toggleArgument
	return self
end

CAdmin.GUI.Register ("CArgumentPrompt", PANEL, "CFrame")