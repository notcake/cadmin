--[[
	Function fallbacks.
]]
CAdmin.RequireInclude ("sh_plugins")

CAdmin.Fallbacks = CAdmin.Fallbacks or {}
CAdmin.Fallbacks.Functions = {}

function CAdmin.Fallbacks.Add (fallbackName, fallbackFunction)
	local fallback = {
		CallCount = 0,
		Function = fallbackFunction,
		Plugin = nil
	}
	CAdmin.Fallbacks.Functions [fallbackName] = fallback

	local runningPlugin = CAdmin.Plugins.GetRunningPlugin ()
	if runningPlugin then
		fallback.Plugin = runningPlugin.Name
		runningPlugin.Fallbacks [fallbackName] = true
	end

	CAdmin.Hooks.Call ("CAdminFallbackAdded", fallbackName)
	CAdmin.Hooks.Call ("CAdminFallbackChanged", fallbackName, true)
end

function CAdmin.Fallbacks.Call (fallbackName, minret, ...)
	local fallback = nil
	fallback = CAdmin.Fallbacks.Functions [fallbackName]
	if not fallback then
		return nil
	end
	local ret = {CAdmin.Lua.TryCall (function (error)
		print ("Lua Error in fallback " .. fallbackName .. ": " .. error)
	end, fallback.Function, ...)}
	if #ret >= minret then
		fallback.CallCount = fallback.CallCount + 1
	end
	return unpack (ret)
end

function CAdmin.Fallbacks.FallbackExists (name)
	if CAdmin.Fallbacks.GetFallbacks () [name] then
		return true
	end
	return false
end

function CAdmin.Fallbacks.GetFallbackCallCount (name)
	local fallback = CAdmin.Fallbacks.Functions [name]
	if not fallback then
		return 0
	end
	return fallback.CallCount
end

function CAdmin.Fallbacks.GetFallbacks ()
	return CAdmin.Fallbacks.Functions
end

function CAdmin.Fallbacks.Remove (name)
	local fallback = CAdmin.Fallbacks.Functions [name]
	if fallback.Plugin then
		CAdmin.Plugins.GetPlugin (fallback.Plugin).Fallbacks [name] = nil
	end
	CAdmin.Fallbacks.Functions [name] = nil

	CAdmin.Hooks.Call ("CAdminFallbackRemoved", name)
	CAdmin.Hooks.Call ("CAdminFallbackChanged", name, false)
end

function CAdmin.Fallbacks.ResetCallCount (name)
	local fallback = CAdmin.Fallbacks.Functions [name]
	if not fallback then
		return
	end
	fallback.CallCount = 0
end

CAdmin.Hooks.Add ("CAdminInitialize", "CAdmin.Fallbacks.Initialize", function ()
	CAdmin.Hooks.Add ("CAdminPluginLoaded", "CAdmin.Fallbacks.PluginLoaded", function (pluginList)
		for _, plugin in pairs (pluginList) do
			plugin.Fallbacks = plugin.Fallbacks or {}
		end
	end)

	CAdmin.Hooks.Add ("CAdminPluginUnloaded", "CAdmin.Fallbacks.PluginUnloaded", function (pluginList)
		for _, plugin in pairs (pluginList) do
			for fallbackType, _ in pairs (plugin.Fallbacks) do
				CAdmin.Fallbacks.Remove (fallbackType)
			end
			plugin.Fallbacks = nil
		end
	end)
end)