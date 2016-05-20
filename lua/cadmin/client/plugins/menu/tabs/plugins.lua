local TAB = TAB
TAB:SetName ("Plugins")
TAB:SetIcon ("gui/silkicons/plugin")
TAB:SetTabPosition (4)
TAB:SetTooltip ("Manage plugins.")

function TAB:Init ()
	self:SetCommandArgumentType ("Plugin")
	self:CreateListViewLayout ()
	self.ItemList:AddColumn ("Name")
	self.ItemList:AddColumn ("Type")
	self.ItemList:AddColumn ("Loaded?")
	self.ItemList:AddColumn ("Author")
	self.ItemList:AddColumn ("Description")
	self.ItemList:SetObjectConverter (function (line)
		return CAdmin.Plugins.GetPlugin (line:GetText (1))
	end)

	self:PopulateItems ()
end

function TAB:PerformLayout (firstLayout)
	if firstLayout then
		self.ItemList:GetColumn (1):SetWidth (self:GetWide () * 0.15)
		self.ItemList:GetColumn (2):SetWidth (64)
		self.ItemList:GetColumn (3):SetWidth (64)
		self.ItemList:GetColumn (5):SetWidth (self:GetWide () * 0.3)
	end
	self:PerformListViewLayout ()
end

function TAB:PopulateItems ()
	self.ItemList:Clear ()

	for pluginName, plugin in pairs (CAdmin.Plugins.Plugins) do
		local line = self.ItemList:AddLine (pluginName, plugin:GetPluginType (), plugin:GetLoadedDescription (), plugin:GetAuthor (), plugin:GetDescription ())
	end
end

function TAB:UpdateItems ()
	for _, line in pairs (self.ItemList.Lines) do
		local plugin = CAdmin.Plugins.GetPlugin (line:GetText (1))
		if plugin then
			line:SetValue (3, plugin:GetLoadedDescription ())
		else
			CAdmin.Debug.PrintStackTrace ()
			ErrorNoHalt ("WAT: " .. line:GetText (1))
		end
	end
end

CAdmin.Hooks.Add ("CAdminPluginPostLoaded", "CAdmin.Menu.Plugins.Update", function ()
	TAB:UpdateItems ()
	TAB:UpdateCommands ()
end)

CAdmin.Hooks.Add ("CAdminPluginRegistered", "CAdmin.Menu.Plugins", function (pluginName, plugin)
	TAB.ItemList:AddLine (pluginName, plugin:GetPluginType (), plugin:GetLoadedDescription (), plugin:GetAuthor (), plugin:GetDescription ())
end)

CAdmin.Hooks.Add ("CAdminServerPluginLoaded", "CAdmin.Menu.Plugins.Update", function ()
	TAB:UpdateItems ()
	TAB:UpdateCommands ()
end)

CAdmin.Hooks.Add ("CAdminServerPluginUnloaded", "CAdmin.Menu.Plugins.Update", function ()
	TAB:UpdateItems ()
	TAB:UpdateCommands ()
end)

CAdmin.Hooks.Add ("CAdminPluginUnloaded", "CAdmin.Menu.Plugins.Update", function ()
	TAB:UpdateItems ()
	TAB:UpdateCommands ()
end)