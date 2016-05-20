--[[
	Derived from ToolPanel
]]
local PANEL = {}

function PANEL:Init ()
	self.Categories = {}
	self.Commands = {}
	
	self.CommandArgumentsList = nil
	self.CommandArgumentType = nil
	self.CommandCallback = nil

	self:EnableVerticalScrollbar (true)
	self:SetSpacing (1)
	self:SetPadding (1)
end

function PANEL:AddCategory (categoryName)
	if self.Categories [categoryName] then
		return
	end

	local categoryContainer = self:Create ("DCollapsibleCategory")
	categoryContainer:SetWide (self:GetWide ())
	categoryContainer:SetLabel (categoryName)
	categoryContainer.Header:SetTall (24)
	
	-- For sorting.
	categoryContainer.CategoryName = categoryName
	self:AddItem (categoryContainer)

	local categoryCommandList = self:Create ("CPanelList", categoryContainer)
	categoryCommandList:SetAutoSize (true)
	categoryCommandList:SetDrawBackground (false)
	categoryCommandList:SetSpacing (0)
	categoryCommandList:SetPadding (0)
	categoryCommandList:SetWide (categoryContainer:GetWide ())
	categoryContainer:SetContents (categoryCommandList)

	local category = {
		CategoryID = #self.Items,
		CommandCount = 0,
		Commands = {},
		Container = categoryContainer,
		PanelList = categoryCommandList
	}
	self.Categories [categoryName] = category
end

local function CommandButtonClick (button)
	local commandInfo = button.CommandInfo
	if commandInfo then
		commandInfo.ToggleState = button:IsChecked ()
		if commandInfo.Function then
			commandInfo.Function (button.CommandList, commandInfo.CommandID, commandInfo.ToggleState)
		else
			local commandList = button.CommandList
			if commandList.CommandCallback then
				commandList:CommandCallback (commandInfo.CommandID, commandInfo.ToggleState)
			end
		end
	end
end

function PANEL:AddCommand (commandID, categoryName, text, callbackFunction, isToggle)
	if not self.Categories [categoryName] then
		self:AddCategory (categoryName)
	end
	local commandInfo = self.Commands [commandID]
	if not commandInfo then	
		local button = self:Create ("CCommandButton")
		button:SetText (text)
		button:SetWide (self.Categories [categoryName].PanelList:GetWide ())
		button:SetShowCheckbox (isToggle)
		button.CommandID = commandID
		button.CommandList = self
		button:SetCallback (CommandButtonClick)
		
		commandInfo = {
			Button = button,
			Category = categoryName,
			CommandID = commandID,
			Function = callbackFunction,
			Text = text
		}
		self.Commands [commandID] = commandInfo		
		button.CommandInfo = commandInfo

		self.Categories [categoryName].Commands [commandID] = commandInfo
		self.Categories [categoryName].PanelList:AddItem (button)
		self:InvalidateLayout ()
		self.Categories [categoryName].CommandCount = self.Categories [categoryName].CommandCount + 1
		if self.Categories [categoryName].CommandCount % 2 == 1 then
			button:SetBackgroundColor (Color (255, 255, 255, 10))
		end
	end
	self.Commands [commandID].Enabled = true
	self.Commands [commandID].Toggle = isToggle
	self.Commands [commandID].ToggleState = false
	return self.Commands [commandID]
end

function PANEL:Clear (delete)
	for _, v in pairs (self.Commands) do
		v.Function = nil
		v.Button = nil
	end
	self.Commands = {}
	for _, v in pairs (self.Categories) do
		v.Commands = nil
		v.PanelList = nil
	end
	self.Categories = {}
	
	for k, panel in pairs (self.Items) do
		if panel and panel:IsValid () then
			panel:SetParent (panel)
			panel:SetVisible (false)
			panel:Remove ()
		end
	end
	self.Items = {}
end

function PANEL:EnableCommand (commandID, enabled)
	if not self.Commands [commandID] then
		return
	end
	self.Commands [commandID].Button:SetDisabled (not enabled)
	self.Commands [commandID].Enabled = enabled
end

local function ExecuteCallback (commandList, consoleCommand)
	commandList:PopulateCommands ()
end

function PANEL:ExecuteCommand (commandID, toggleArgument)
	if self.CommandCallback then
		self:CommandCallback (commandID, toggleArgument)
	else
		local argumentList = self.CommandArgumentsList or {{}}
		local command = CAdmin.Commands.GetCommand (commandID)
		local commandInfo = self.Commands [commandID]
		local commandName = commandID
		if commandInfo then
			commandName = command:GetConsoleCommand ()
			if command:IsToggleCommand () then
				if not toggleArgument then
					commandName = command:GetReverseConsoleCommand ()
				end
			end
		end
		local commandDispatcher = CAdmin.Objects.Create ("Command Dispatcher", commandName)
		commandDispatcher:AddArgument (self.CommandArgumentType, argumentList [1])
		commandDispatcher:SetExecuteCallback (ExecuteCallback, self)
		commandDispatcher:DispatchCommand ()
		commandDispatcher = nil
	end
end

function PANEL:GetCategory (categoryName)
	return self.Categories [categoryName]
end

function PANEL:GetCategories ()
	return self.Categories
end

function PANEL:GetCommand (commandID)
	return self.Commands [commandID]
end

function PANEL:GetCommandArgumentsList ()
	return self.CommandArgumentsList
end

function PANEL:GetCommandArgumentType ()
	return self.CommandArgumentType
end

function PANEL:GetCommandCallback ()
	return self.CommandCallback
end

function PANEL:GetCommands ()
	return self.Commands
end

function PANEL:GetCommandToggleState (commandID)
	return self.Commands [commandID].ToggleState
end

function PANEL:PerformLayoutLeft ()
	local padding = self:GetParent ():GetPadding ()

	local w = self:GetParent ():GetWide () * 0.2 - 1.5 * padding
	if w > 228 then
		w = 228
	end
	self:SetSize (w, self:GetParent ():GetTall () - 2 * padding)
	self:SetPos (padding, padding)
end

function PANEL:PerformLayoutRight ()
	local padding = self:GetParent ():GetPadding ()

	local w = self:GetParent ():GetWide () * 0.2 - 1.5 * padding
	if w > 228 then
		w = 228
	end
	self:SetSize (w, self:GetParent ():GetTall () - 2 * padding)
	self:SetPos (self:GetParent ():GetWide () - padding - self:GetWide (), padding)
end

function PANEL:PopulateCommands ()
	local commands = CAdmin.Commands.FindByArgument (self.CommandArgumentType)
	local commandList = {}
	local categoryList = {}
	for _, v in pairs (commands) do
		categoryList [v:GetCategory ()] = true
		commandList [v:GetCommandID ()] = true
		self:AddCommand (v:GetCommandID (), v:GetCategory (), v:GetDisplayName (), self.ExecuteCommand, v:IsToggleCommand ())
	end
	for k, _ in pairs (self.Categories) do
		if not categoryList [k] then
			self:RemoveCategory (k)
		end
	end
	categoryList = nil
	
	for k, _ in pairs (self.Commands) do
		if not commandList [k] then
			self:RemoveCommand (k)
		end
	end
	
	self:SortCommands ()
	self:UpdateCommandStates ()
end

function PANEL:RemoveCategory (categoryName)
	local category = self.Categories [categoryName]
	if not category then
		return
	end
	
	for k, _ in pairs (category.Commands) do
		self:RemoveCommand (k)
	end
	
	self:RemoveItem (category.Container)
	category.Container:Remove ()
	category.Container = nil
	category.PanelList = nil
	
	category = nil
	self.Categories [categoryName] = nil
end

function PANEL:RemoveCommand (commandID)
	local command = self.Commands [commandID]
	if not command then
		return
	end
	
	self:InvalidateLayout ()
	self.Categories [command.Category].PanelList:RemoveItem (command.Button)
	command.Button:Remove ()
	command.Button = nil
	
	self.Categories [command.Category].Commands [commandID] = nil
	self.Categories [command.Category].CommandCount = self.Categories [command.Category].CommandCount - 1
	
	self.Commands [commandID] = nil
	command = nil
end

function PANEL:SetCommandArgumentsList (argumentList)
	self.CommandArgumentsList = argumentList
end

function PANEL:SetCommandArgumentType (argumentType)
	self.CommandArgumentType = argumentType
end

function PANEL:SetCommandCallback (callbackFunc)
	self.CommandCallback = callbackFunc
end

function PANEL:SetCommandText (commandID, displayText)
	self.Commands [commandID].Button:SetText (displayText)
	self.Commands [commandID].Text = displayText
end

function PANEL:SetCommandToggleState (commandID, state)
	self.Commands [commandID].ToggleState = state
	self.Commands [commandID].Button:SetChecked (state)
end

local function MenuRunCommand (consoleCommand, commandList)
	local argumentList = commandList.CommandArgumentsList or {{}}
	
	if #argumentList [1] == 0 then
		return
	end
	
	local command = CAdmin.Commands.GetConsoleCommand (consoleCommand)
	local commandID = command:GetCommandID ()
	local toggleArgument = true
	if consoleCommand ~= command:GetConsoleCommand () then
		toggleArgument = false
	end
	commandList:ExecuteCommand (commandID, toggleArgument)
end

function PANEL:ShowCommandMenu ()
	local commandMenu = CAdmin.GUI.CreateMenu ()
	
	local argumentList = self.CommandArgumentsList or {{}}
	local categoriesAdded = {}
	local categoryList = {}
	
	local firstCategory = true
	
	for k, t in pairs (self.Categories) do
		categoryList [#categoryList + 1] = k
	end
	table.sort (categoryList)
	for k, categoryName in pairs (categoryList) do
		categoryList [k] = self.Categories [categoryName]
	end
	for k, category in pairs (categoryList) do
		local firstCommand = true
		local commandList = {}
		for commandID, _ in pairs (category.Commands) do
			commandList [#commandList + 1] = commandID
		end
		table.sort (commandList)
		for _, commandID in pairs (commandList) do
			local commandInfo = self.Commands [commandID]
			local command = CAdmin.Commands.GetCommand (commandID)
			if commandInfo.Enabled then
				if firstCommand and not firstCategory then
					commandMenu:AddSpacer ()
				end
				firstCommand = false
				firstCategory = false
				
				local canToggleOn = not command:IsToggleCommand ()
				local canToggleOff = false
				if command:IsToggleCommand () then
					for _, firstArgument in ipairs (argumentList [1]) do
						if CAdmin.Commands.IsCommandToggleOn (LocalPlayer (), CAdmin.Commands.COMMAND_CONSOLE, command:GetConsoleCommand (), firstArgument) then
							canToggleOff = true
						else
							canToggleOn = true
						end
						if canToggleOn and canToggleOff then
							break
						end
					end
				end
				if canToggleOn then
					commandMenu:AddOption (command:GetDisplayName (), MenuRunCommand, command:GetConsoleCommand (), self)
				end
				if canToggleOff then
					commandMenu:AddOption (command:GetReverseDisplayName (), MenuRunCommand, command:GetReverseConsoleCommand (), self)
				end
			end
		end
	end
	if commandMenu:GetItemCount () == 0 then
		commandMenu:Remove ()
	else
		commandMenu:Open ()
	end
end

function PANEL:SortCommands ()
	self:SortByMember ("CategoryName")
	for _, v in pairs (self.Categories) do
		v.PanelList:SortByMember ("CommandID")
		local alt = false
		for _, v in ipairs (v.PanelList:GetItems ()) do
			alt = not alt
			if alt then
				v:SetBackgroundColor (Color (255, 255, 255, 10))
			else
				v:SetBackgroundColor (Color (255, 255, 255, 0))
			end
		end
	end
end

function PANEL:UpdateCommandStates ()
	local arguments = self.CommandArgumentsList or {}
	local argumentCount = #arguments
	local firstArgumentCount = 0
	if argumentCount > 0 then
		firstArgumentCount = #arguments [1]
	end
	if firstArgumentCount == 0 and argumentCount == 1 then
		argumentCount = 0
		arguments [1] = nil
	end
	for commandID, _ in pairs (self.Commands) do
		local command = CAdmin.Commands.GetCommand (commandID)
		local commandName = command:GetConsoleCommand ()
		if command:IsToggleCommand () then
			local toggleState = true
			if firstArgumentCount == 0 then
				toggleState = false
			end
			if firstArgumentCount > 0 then
				for _, firstArgument in pairs (arguments [1]) do
					if not CAdmin.Commands.IsCommandToggleOn (LocalPlayer (), CAdmin.Commands.COMMAND_CONSOLE, commandName, firstArgument) then
						toggleState = false
					end
				end
			end
			self:SetCommandToggleState (commandID, toggleState)
			if toggleState then
				commandName = command:GetReverseConsoleCommand ()
			end
		end
		self:EnableCommand (commandID, CAdmin.Commands.CanExecute (LocalPlayer (), CAdmin.Commands.COMMAND_CONSOLE, commandName, unpack (arguments)))
	end
end

CAdmin.GUI.Register ("CCommandList", PANEL, "CPanelList")