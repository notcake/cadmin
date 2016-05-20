local PLUGIN = CAdmin.Plugins.Create ("Menu")
PLUGIN:SetAuthor ("!cake")
PLUGIN:SetDescription ("A user interface for CAdmin commands.")
PLUGIN:SetDelayLoaded (true)

local MENU = {}

PLUGIN.LAYOUT_LISTVIEW = 1

function PLUGIN:Initialize ()
	self.MenuVisible = false
	self.MenuToggled = false

	CAdmin.Console.AddCommand ("+cadmin", function ()
		self.MenuVisible = true
		self:UpdateMenuVisibility ()
	end)
	CAdmin.Console.AddCommand ("-cadmin", function ()
		self.MenuVisible = false
		self:UpdateMenuVisibility ()
	end)
	CAdmin.Console.AddCommand ("cadmin_toggle", function ()
		self:ToggleMenu ()
	end)

	CAdmin.GUI.RegisterFolder ("client/plugins/menu/controls")
	self.Menu = CAdmin.GUI.Create ("CAdmin.Menu")
	self.Menu.Plugin = self
	self:GetMenu ():GetPropertySheet ():LoadFolder ("client/plugins/menu/tabs")
	self:GetMenu ():GetPropertySheet ():CreateTabs ()
	
	if not CAdmin.Settings.Get ("Menu.ShownWelcomeMessage", false) then
		-- CAdmin.GUI.Create ("CAdmin.WelcomeMessage")
	end
	
	local command = CAdmin.Commands.Create ("test_welcome_message", "Debugging", "Test Welcome Message")
	command:SetAuthenticationRequired (false)
	command:SetConsoleCommand ("test_welcome")
	command:SetCommandType (CAdmin.COMMAND_CLIENT)
	command:AddArgument ("Boolean", "Menu bound", false)
	command:SetExecute (function (ply, menuBound)
		CAdmin.Settings.Set ("Menu.Bound", menuBound)
		CAdmin.GUI.Create ("CAdmin.WelcomeMessage")
	end)
	
	command = CAdmin.Commands.Create ("editor", "Debugging", "Show Code Editor")
	command:SetAuthenticationRequired (false)
	command:SetConsoleCommand ("editor")
	command:SetCommandType (CAdmin.COMMAND_CLIENT)
	command:SetExecute (function (ply)
		CAdmin.GUI.Create ("CAdmin.CodeEditor")
	end)

	if not CAdmin.Settings.Get ("Menu.Bound", false) then
		CAdmin.Hooks.Add ("PlayerBindPress", "CAdmin.Menu.BindPress", function (ply, bind, pressed)
			if pressed then
				if bind == "slot0" then
					self:ToggleMenu ()
				else
					if bind:find ("+cadmin", 1, true) or
					   bind:find ("-cadmin", 1, true) or
					   bind:find ("cadmin_toggle", 1, true) then
						CAdmin.Hooks.Remove ("PlayerBindPress", "CAdmin.Menu.BindPress")
						CAdmin.Settings.Set ("Menu.Bound", true)
					end
				end
			end
		end)
	end
	self:GetMenu ():GetPropertySheet ():PerformLayout (true)
end

function PLUGIN:Uninitialize ()
	if self.Menu then
		if self.Menu:IsVisible () then
			self.Menu:SetVisible (false)
		end
		self.Menu:Remove ()
		self.Menu = nil
	end
end

function PLUGIN:GetMenu ()
	return self.Menu
end

function PLUGIN:ToggleMenu ()
	self.MenuVisible = not self.MenuVisible
	self.MenuToggled = self.MenuVisible
	self:UpdateMenuVisibility ()
end

function PLUGIN:UpdateMenuVisibility ()
	if self.MenuVisible then
		-- Youtube Players break input.
		local failTubePlayers = ents.FindByClass ("youtube_player")
		for _, v in pairs (failTubePlayers) do
			if v.Browser and v.Browser:IsValid () then
				v.Browser:SetMouseInputEnabled (false)
			end
		end
	end
	self.Menu:SetVisible (self.MenuVisible)
end