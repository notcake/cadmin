local TYPE = CAdmin.Commands.RegisterType ("Plugin")

TYPE:SetAutocomplete (function (pluginName)
	local pluginList = {}
	local lowerName = pluginName:lower ()
	if lowerName == "*" then
		lowerName = ""
	end
	for k, v in pairs (CAdmin.Plugins.GetPlugins ()) do
		if k:lower ():find (lowerName, 1, true) then
			pluginList [#pluginList + 1] = k
		end
	end
	table.sort (pluginList)
	return pluginList
end)

TYPE:SetSerializer (function (ply, plugin)
	return plugin:GetName ()
end)

TYPE:RegisterConverter ("String", function (ply, pluginName)
	local pluginList = {}
	local lowername = pluginName:lower ()
	local selectAll = false
	if lowername == "*" then
		selectAll = true
	end
	if CAdmin.Plugins.GetPlugin (pluginName) then
		return {CAdmin.Plugins.GetPlugin (pluginName)}
	end
	for _, v in pairs (CAdmin.Plugins.GetPlugins ()) do
		if selectAll or v.Name:lower ():find (lowername, 1, true) then
			pluginList [#pluginList + 1] = v
		end
	end
	return pluginList
end)