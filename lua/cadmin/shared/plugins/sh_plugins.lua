local PLUGIN = CAdmin.Plugins.Create ("Plugin Commands")
PLUGIN:SetAuthor ("!cake")
PLUGIN:SetDescription ("Provides plugin management commands.")

function PLUGIN:Initialize ()
	-- a_ is there so that the commands sort in the desired order in the menu.
	local command = CAdmin.Commands.Create ("plugin_a_load", "Plugins", "Load")
		:SetConsoleCommand ("plugin_load")
		:SetAuthenticationRequired (false)
		:SetRunLocation (CAdmin.RUN_LOCAL)
		:SetLogString ("%Player% loaded plugin%s% %target%.")
	command:AddArgument ("Plugin")
		:SetPromptText ("Select the plugins you want to load:")
	command:SetCanExecute (function (ply, plugin)
		return plugin:CanLoad ()
	end)
	command:SetExecute (function (ply, plugin)
		CAdmin.Plugins.LoadPlugins (plugin:GetName ())
	end)
	command:SetPostExecute (function ()
		CAdmin.Hooks.Call ("CAdminPluginStatesChanged")
	end)

	command = CAdmin.Commands.Create ("plugin_a_reload", "Plugins", "Reload")
		:SetConsoleCommand ("plugin_reload")
		:SetAuthenticationRequired (false)
		:SetRunLocation (CAdmin.RUN_LOCAL)
		:SetLogString ("%Player% reloaded plugin%s% %target%.")
	command:AddArgument ("Plugin")
		:SetPromptText ("Select the plugins you want to reload:")
	command:SetCanExecute (function (ply, plugin)
		return true
	end)
	command:SetExecute (function (ply, plugin)
		CAdmin.Plugins.UnloadPlugins (plugin:GetName ())
		CAdmin.Plugins.LoadPlugins (plugin:GetName ())
	end)
	command:SetPostExecute (function ()
		CAdmin.Hooks.Call ("CAdminPluginStatesChanged")
	end)
	
	command = CAdmin.Commands.Create ("plugin_a_unload", "Plugins", "Unload")
		:SetConsoleCommand ("plugin_unload")
		:SetAuthenticationRequired (false)
		:SetRunLocation (CAdmin.RUN_LOCAL)
		:SetLogString ("%Player% unloaded plugin%s% %target%.")
	command:AddArgument ("Plugin")
		:SetPromptText ("Select the plugins you want to unload:")
	command:SetCanExecute (function (ply, plugin)
		return plugin:CanUnload ()
	end)
	command:SetExecute (function (ply, plugin)
		CAdmin.Plugins.UnloadPlugins (plugin:GetName ())
	end)
	command:SetPostExecute (function ()
		CAdmin.Hooks.Call ("CAdminPluginStatesChanged")
	end)
		
	command = CAdmin.Commands.Create ("plugin_sv_load", "Plugins", "Load on Server")
		:SetConsoleCommand ("plugin_load_sv")
		:SetLogString ("%Player% loaded plugin%s% %target%.")
	command:AddArgument ("Plugin")
		:SetPromptText ("Select the plugins you want to load:")
	command:SetCanExecute (function (ply, plugin)
		return plugin:CanServerLoad ()
	end)
	command:SetExecute (function (ply, plugin)
		CAdmin.Plugins.LoadPlugins (plugin:GetName ())
	end)
	
	command = CAdmin.Commands.Create ("plugin_sv_reload", "Plugins", "Reload on Server")
		:SetConsoleCommand ("plugin_reload_sv")
		:SetLogString ("%Player% reloaded plugin%s% %target%.")
	command:AddArgument ("Plugin")
		:SetPromptText ("Select the plugins you want to reload:")
	command:SetCanExecute (function (ply, plugin)
		return true
	end)
	command:SetExecute (function (ply, plugin)
		CAdmin.Plugins.UnloadPlugins (plugin:GetName ())
		CAdmin.Plugins.LoadPlugins (plugin:GetName ())
	end)
	
	command = CAdmin.Commands.Create ("plugin_sv_unload", "Plugins", "Unload on Server")
		:SetConsoleCommand ("plugin_unload_sv")
		:SetLogString ("%Player% unloaded plugin%s% %target%.")
	command:AddArgument ("Plugin")
		:SetPromptText ("Select the plugins you want to unload:")
	command:SetCanExecute (function (ply, plugin)
		return plugin:CanServerUnload ()
	end)
	command:SetExecute (function (ply, plugin)
		CAdmin.Plugins.UnloadPlugins (plugin:GetName ())
	end)
end