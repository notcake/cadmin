CAdmin.RequireInclude ("sh_hooks")

CAdmin.Lists = CAdmin.Lists or {}
local Lists = CAdmin.Lists
Lists.Lists = {}

function Lists.AddToKVList (listName, k, v)
	local list = Lists.GetList (listName)
	list [k] = v or true

	if CAdmin.Plugins and CAdmin.Plugins.GetRunningPlugin () then
		local plugin = CAdmin.Plugins.GetRunningPlugin ()
		if not plugin.KVLists [list] then
			plugin.KVLists [list] = {}
		end
		plugin.KVLists [list] [k] = true
	end

	CAdmin.Hooks.Call ("CAdminListAdded", listName, k, v or true)
end

function Lists.AddToList (listName, v)
	local list = Lists.GetList (listName)
	list [#list + 1] = v

	CAdmin.Hooks.Call ("CAdminListAdded", listName, table.maxn (list), v)
end

function Lists.GetList (listName)
	if Lists.Lists [listName] then
		return Lists.Lists [listName]
	end
	Lists.Lists [listName] = {}
	return Lists.Lists [listName]
end

function Lists.GetLists ()
	return Lists.Lists
end

function Lists.IsInKVList (listName, k)
	if Lists.GetList (listName) [k] then
		return true
	end
	return false
end

function Lists.IsInKVLists (listNames, k)
	for _, listName in pairs (listNames) do
		if Lists.GetList (listName) [k] then
			return true
		end
	end
	return false
end

function Lists.RemoveFromKVList (listName, k)
	local list = Lists.GetList (listName)
	list [k] = nil
end

function Lists.RemoveFromList (listName, value)
	local list = Lists.GetList (listName)
	for k, v in pairs (list) do
		if v == value then
			list [k] = nil
			break
		end
	end
end

CAdmin.Hooks.Add ("CAdminInitialize", "CAdmin.Lists.Initialize", function ()
	CAdmin.Hooks.Add ("CAdminPluginLoaded", "CAdmin.Lists.PluginLoaded", function (pluginList)
		for _, plugin in pairs (pluginList) do
			plugin.KVLists = plugin.KVLists or {}
		end
	end)
	
	CAdmin.Hooks.Add ("CAdminPluginUnloaded", "CAdmin.Lists.PluginUnloaded", function (pluginList)
		for _, plugin in pairs (pluginList) do
			for listName, listTable in pairs (plugin.KVLists) do
				for listKey, _ in pairs (listTable) do
					Lists.RemoveFromKVList (listName, listKey)
				end
			end
			plugin.KVLists = nil
		end
	end)
end)