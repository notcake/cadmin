--[[
	Provides functions for managing plugins.
	
	Files:
		data/cadmin/plugins.txt
		
	Datastreams:
		CAdmin.Plugins.PluginState:
			Sends an array of tables in the form:
			{
				Name		- Plugin name.
				Loaded		- Loaded on server.
				
				[Keys only present on server-only plugins]
				Author		- Plugin author.
				Description	- Plugin description.
			}
	
	Hooks:
		CAdminPluginLoaded (pluginList):
			Called when plugins are about to be loaded locally.
			pluginList is a table of plugin names to plugin objects.
		CAdminPluginPostLoaded (pluginList):
			Called when plugins have been loaded locally.
			pluginList is a table of plugin names to plugin objects.
		CAdminPluginRegistered (pluginName, plugin):
			Called when plugins are added to the plugin list.
			pluginName is the plugin's name.
			plugin is the plugin object.
		CAdminPluginUnloaded (pluginList):
			Called when plugins are unloaded locally.
			pluginList is a table of plugin names to plugin objects.
		CAdminServerPluginLoaded (pluginList):
			Called when plugins are loaded on the server.
			pluginList is a table of plugin names to plugin objects.
		CAdminServerPluginUnloaded (pluginList):
			Called when plugins are unloaded on the server.
			pluginList is a table of plugin names to plugin objects.
]]
CAdmin.RequireInclude ("sh_datastream")
CAdmin.RequireInclude ("sh_hooks")
CAdmin.RequireInclude ("sh_lua")
CAdmin.RequireInclude ("sh_settings")

CAdmin.Plugins = CAdmin.Plugins or {}
local Plugins = CAdmin.Plugins
Plugins.Plugins = {}
Plugins.RunningPluginType = nil
Plugins.RunningPlugin = nil

function Plugins.AddPlugin (pluginName)
	local plugin = Plugins.Plugins [pluginName]
	if plugin then
		return plugin
	end
	plugin = CAdmin.Objects.Create ("Plugin", pluginName)
	return plugin
end

--[[
	Creates a plugin with the given name.
	A call to SetRunningPlugin (nil) is needed afterwards.
]]
function Plugins.Create (pluginName)
	local plugin = Plugins.AddPlugin (pluginName)
	plugin:SetPluginType (Plugins.RunningPluginType)

	Plugins.Plugins [pluginName] = plugin
	Plugins.SetRunningPlugin (pluginName)

	CAdmin.Hooks.Call ("CAdminPluginRegistered", pluginName, plugin)
	return plugin
end

--[[
	Returns the plugin with the specified name.
]]
function Plugins.GetPlugin (pluginName)
	return Plugins.Plugins [pluginName]
end

function Plugins.GetPluginNames ()
	local pluginNames = {}
	for pluginName, _ in pairs (Plugins.Plugins) do
		pluginNames [#pluginNames + 1] = pluginName
	end
	return pluginNames
end

--[[
	Returns a list of plugins.
]]
function Plugins.GetPlugins ()
	return Plugins.Plugins
end

--[[
	Returns the plugin which is being initialized.
]]
function Plugins.GetRunningPlugin ()
	return Plugins.Plugins [Plugins.RunningPlugin]
end

function Plugins.IsPluginLoaded (pluginName)
	return Plugins.Plugins [pluginName].Loaded
end

function Plugins.IsPluginServerLoaded (name)
	return Plugins.Plugins [pluginName].ServerLoaded
end

function Plugins.LoadAllPlugins (instantLoad, delayLoad)
	CAdmin.Profiler.EnterFunction ("CAdmin.Plugins.LoadAllPlugins")
	if instantLoad == nil then
		instantLoad = true
	end
	if delayLoad == nil then
		delayLoad = true
	end

	local pluginList = {}
	for pluginName, plugin in pairs (Plugins.Plugins) do
		if plugin:CanLoad () then
			local shouldLoad = false
			if plugin:GetDelayLoaded () then
				if delayLoad then
					shouldLoad = true
				end
			elseif instantLoad then
				shouldLoad = true
			end
			   
			if shouldLoad then
				pluginList [#pluginList + 1] = pluginName
			end
		end
	end
	
	Plugins.LoadPlugins (pluginList)
		
	CAdmin.Profiler.ExitFunction ()
end

--[[
	Loads a list of plugins.
]]
function Plugins.LoadPlugins (pluginList)
	CAdmin.Profiler.EnterFunction ("CAdmin.Plugins.LoadPlugins")
	if type (pluginList) == "string" then
		pluginList = {pluginList}
	end
	local loadedPluginList = {}
	local plugin = nil
	for _, pluginName in ipairs (pluginList) do
		local plugin = Plugins.Plugins [pluginName]
		if plugin:CanLoad () then
			loadedPluginList [pluginName] = plugin
		end
	end

	CAdmin.Settings.IncreaseSession ("CAdmin.Busy")
	CAdmin.Hooks.Call ("CAdminPluginLoaded", loadedPluginList)
	for pluginName, plugin in pairs (loadedPluginList) do
		Plugins.SetRunningPlugin (pluginName)
		plugin:Load ()
	end
	Plugins.SetRunningPlugin ()
	CAdmin.Hooks.Call ("CAdminPluginPostLoaded", loadedPluginList)
	if SERVER then
		CAdmin.Datastream.SendStream ("CAdmin.Plugins.PluginState", CAdmin.Players.GetCAdminPlayers (), loadedPluginList, false)
	end
	CAdmin.Settings.DecreaseSession ("CAdmin.Busy")
	CAdmin.Profiler.ExitFunction ()
end

--[[
	Loads plugins in a folder and sets their type.
]]
function Plugins.LoadPluginsFolder (folder, pluginType)
	Plugins.RunningPluginType = pluginType
	CAdmin.Lua.IncludeFolder (folder)
	Plugins.SetRunningPlugin ()
end

function Plugins.SetRunningPlugin (pluginName)
	Plugins.RunningPlugin = pluginName
end

--[[
	Unloads a list of plugins.
]]
function Plugins.UnloadPlugins (pluginList)
	CAdmin.Profiler.EnterFunction ("CAdmin.Plugins.UnloadPlugins")
	if type (pluginList) == "string" then
		pluginList = {pluginList}
	end
	local unloadedPluginList = {}
	local plugin = nil
	for _, pluginName in ipairs (pluginList) do
		plugin = Plugins.Plugins [pluginName]
		if plugin:CanUnload () then
			unloadedPluginList [pluginName] = plugin
		end
	end
	CAdmin.Settings.IncreaseSession ("CAdmin.Busy")
	for pluginName, plugin in pairs (unloadedPluginList) do
		Plugins.SetRunningPlugin (pluginName)
		plugin:Unload ()
	end
	Plugins.SetRunningPlugin ()
	CAdmin.Hooks.Call ("CAdminPluginUnloaded", unloadedPluginList)
	if SERVER then
		CAdmin.Datastream.SendStream ("CAdmin.Plugins.PluginState", CAdmin.Players.GetCAdminPlayers (), unloadedPluginList, false)
	end
	CAdmin.Settings.DecreaseSession ("CAdmin.Busy")
	CAdmin.Profiler.ExitFunction ()
end

CAdmin.Datastream.RegisterServerToClientStream ("CAdmin.Plugins.PluginState", function (ply, pluginList, update)
	local pluginData = {}
	pluginList = pluginList or Plugins.Plugins
	for pluginName, plugin in pairs (pluginList) do
		pluginData [pluginName] = {
			ServerLoaded = plugin:IsServerLoaded ()
		}
		if not update then
			if plugin:GetPluginType () == "Server" then
				pluginData [pluginName].Author = plugin:GetAuthor ()
				pluginData [pluginName].Description = plugin:GetDescription ()
			end
		end
	end
	return ply, pluginData
end, function (ply, pluginData)
	local loadedPlugins = {}
	local unloadedPlugins = {}
	local serverLoadedPlugins = {}
	local serverUnloadedPlugins = {}
	local loadedPluginCount = 0
	local unloadedPluginCount = 0
	local serverLoadedPluginCount = 0
	local serverUnloadedPluginCount = 0
	
	CAdmin.Settings.IncreaseSession ("CAdmin.Busy")
	for pluginName, pluginInfo in pairs (pluginData) do
		local plugin = Plugins.Plugins [pluginName]
		if not plugin then
			-- It's a serverside plugin.
			plugin = Plugins.AddPlugin (pluginName)
			plugin:SetAuthor (pluginInfo.Author)
			plugin:SetDescription (pluginInfo.Description)
		end
		if plugin:IsServerLoaded () ~= pluginInfo.ServerLoaded then
			if plugin:GetPluginType () ~= "Server" and plugin:IsLoaded () ~= pluginInfo.ServerLoaded then
				if pluginInfo.ServerLoaded then
					loadedPlugins [pluginName] = plugin
					loadedPluginCount = loadedPluginCount + 1
				else
					plugin:Unload ()
					unloadedPlugins [pluginName] = plugin
					unloadedPluginCount = unloadedPluginCount + 1
				end
			end
			if pluginInfo.ServerLoaded then
				serverLoadedPlugins [pluginName] = plugin
				serverLoadedPluginCount = serverLoadedPluginCount + 1
			else
				serverUnloadedPlugins [pluginName] = plugin
				serverUnloadedPluginCount = serverUnloadedPluginCount + 1
			end
			plugin:SetServerLoaded (pluginInfo.ServerLoaded)
		end
	end
	if loadedPluginCount > 0 then
		CAdmin.Hooks.Call ("CAdminPluginLoaded", loadedPlugins)
		for pluginName, plugin in pairs (loadedPlugins) do
			plugin:Load ()
		end
	end
	if unloadedPluginCount > 0 then
		CAdmin.Hooks.Call ("CAdminPluginUnloaded", unloadedPlugins)
	end
	if serverLoadedPluginCount > 0 then
		CAdmin.Hooks.Call ("CAdminServerPluginLoaded", serverLoadedPlugins)
	end
	if serverUnloadedPluginCount > 0 then
		CAdmin.Hooks.Call ("CAdminServerPluginUnloaded", serverUnloadedPlugins)
	end
	CAdmin.Settings.DecreaseSession ("CAdmin.Busy")
end)

CAdmin.Hooks.Add ("CAdminPostInitialize", "CAdmin.Plugins.Initialize", function ()
	CAdmin.Plugins.LoadAllPlugins (true, false)

	CAdmin.Hooks.Add ("CAdminPlayerCAdminInitialized", "CAdmin.Plugins.SendPlugins", function (steamID, uniqueID, playerName, ply)
		CAdmin.Datastream.SendStream ("CAdmin.Plugins.PluginState", ply)
	end)

	if SERVER then
		CAdmin.Hooks.Add ("CAdminPluginLoaded", "CAdmin.Plugins.SendPluginState", function (pluginList)
			CAdmin.Datastream.SendStream ("CAdmin.Plugins.PluginState", CAdmin.Players.GetCAdminPlayers (), pluginList, update)
		end)

		CAdmin.Hooks.Add ("CAdminPluginUnloaded", "CAdmin.Plugins.SendPluginState", function (pluginList)
			CAdmin.Datastream.SendStream ("CAdmin.Plugins.PluginState", CAdmin.Players.GetCAdminPlayers (), pluginList, update)
		end)
	end
	
	-- Now do the delay loaded plugins
	CAdmin.Timers.RunNextTick (CAdmin.Plugins.LoadAllPlugins, false, true)
end)

if CLIENT then	
	CAdmin.Hooks.Add ("CAdminServerUninitialized", "CAdmin.Plugins.ServerUninitialize", function ()
		local unloadedPlugins = {}
		for pluginName, plugin in pairs (Plugins.Plugins) do
			if plugin:IsServerLoaded () then
				plugin:SetServerLoaded (false)
				unloadedPlugins [pluginName] = plugin
			end
		end
		CAdmin.Hooks.Call ("CAdminServerPluginUnloaded", unloadedPlugins)
	end)
end


CAdmin.Hooks.Add ("CAdminUninitialize", "CAdmin.Plugins.Uninitialize", function ()
	Plugins.UnloadPlugins (Plugins.GetPluginNames ())
	Plugins.Plugins = {}
end)