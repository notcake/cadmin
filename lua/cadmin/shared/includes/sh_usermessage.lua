CAdmin.RequireInclude ("sh_hooks")
CAdmin.RequireInclude ("sh_plugins")

CAdmin.Usermessages = CAdmin.Usermessages or {}
CAdmin.Usermessages.InterceptHooks = {}
CAdmin.Usermessages.InterceptHookCounts = {}

function CAdmin.Usermessages.AddInterceptHook (hookType, hookName, func)
	if not CAdmin.Usermessages.InterceptHooks [hookType] then
		CAdmin.Usermessages.InterceptHooks [hookType] = {}
		CAdmin.Usermessages.InterceptHookCounts [hookType] = 0
	end
	CAdmin.Usermessages.InterceptHooks [hookType] [hookName] = {
		Function = func
	}
	CAdmin.Usermessages.InterceptHookCounts [hookType] = CAdmin.Usermessages.InterceptHookCounts [hookType] + 1

	local hookPlugin = CAdmin.Plugins.GetRunningPlugin ()
	if hookPlugin then
		CAdmin.Usermessages.InterceptHooks [hookType] [hookName].Plugin = hookPlugin:GetName ()
		if not hookPlugin.UsermessageInterceptHooks [hookType] then
			hookPlugin.UsermessageInterceptHooks [hookType] = {}
			hookPlugin.UsermessageInterceptHookCounts [hookType] = 0
		end
		hookPlugin.UsermessageInterceptHookCounts [hookType] = hookPlugin.UsermessageInterceptHookCounts [hookType] + 1
		hookPlugin.UsermessageInterceptHooks [hookType] [hookName] = true
	end
end

function CAdmin.Usermessages.Hook (hookType, callbackFunc, ...)
	usermessage.Hook (hookType, callbackFunc, ...)
end

function CAdmin.Usermessages.RemoveInterceptHook (hookType, hookName)
	if not CAdmin.Usermessages.InterceptHooks [hookType] then
		return
	end
	if not CAdmin.Usermessages.InterceptHooks [hookType] [hookName] then
		print ("Attempted to remove an inexistant usermessage hook: " .. hookType .. ": " .. hookName)
		CAdmin.Debug.PrintStackTrace ()
	end
	
	-- Remove the hook entry from the plugin.
	local hookPlugin = CAdmin.Usermessages.InterceptHooks [hookType] [hookName].Plugin
	if hookPlugin then
		hookPlugin = CAdmin.Plugins.GetPlugin (hookPlugin)
		hookPlugin.UsermessageInterceptHooks [hookType] [hookName] = nil
		hookPlugin.UsermessageInterceptHookCounts [hookType] = hookPlugin.UsermessageInterceptHookCounts [hookType] - 1
		if hookPlugin.UsermessageInterceptHookCounts [hookType] == 0 then
			hookPlugin.UsermessageInterceptHooks [hookType] = nil
			hookPlugin.UsermessageInterceptHookCounts [hookType] = nil
		end
	end
	
	-- Remove the hook.
	CAdmin.Usermessages.InterceptHooks [hookType] [hookName] = nil
	CAdmin.Usermessages.InterceptHookCounts [hookType] = CAdmin.Usermessages.InterceptHookCounts [hookType] - 1
	if CAdmin.Usermessages.InterceptHookCounts [hookType] == 0 then
		CAdmin.Usermessages.InterceptHooks [hookType] = nil
		CAdmin.Usermessages.InterceptHookCounts [hookType] = nil
	end
end

CAdmin.Hooks.Add ("CAdminInitialize", "CAdmin.Usermessages.Initialize", function ()
	-- Intercept usermessages
	CAdmin.Lua.HookFunction ("usermessage.IncomingMessage", function (_usermessageIncomingMessage, hookType, umsg)
		local blockMessage = false
		if CAdmin.Usermessages.InterceptHooks [hookType] then
			for _, t in pairs (CAdmin.Usermessages.InterceptHooks [hookType]) do
				blockMessage = blockMessage or t.Function (hookType, umsg)
				if umsg then
					umsg:Reset ()
					umsg:ReadString ()
				end
			end
		end
		
		-- If the usermessage should not be eaten, pass it on.
		if not blockMessage then
			_usermessageIncomingMessage (hookType, umsg)
		end
	end)

	CAdmin.Hooks.Add ("CAdminPluginLoaded", "CAdmin.Usermessages.PluginLoaded", function (pluginList)
		for _, plugin in pairs (pluginList) do
			plugin.UsermessageInterceptHooks = {}
			plugin.UsermessageInterceptHookCounts = {}
		end
	end)

	CAdmin.Hooks.Add ("CAdminPluginUnloaded", "CAdmin.Usermessages.PluginUnloaded", function (pluginList)
		for _, plugin in pairs (pluginList) do
			for k, t in pairs (plugin.UsermessageInterceptHooks) do
				for v, _ in pairs (t) do
					CAdmin.Usermessages.RemoveInterceptHook (k, v)
				end
			end
			plugin.UsermessageInterceptHooks = nil
			plugin.UsermessageInterceptHookCounts = nil
		end
	end)
end)

CAdmin.Hooks.Add ("CAdminUninitialize", "CAdmin.Usermessages.Uninitialize", function ()
	for k, t in pairs (CAdmin.Usermessages.InterceptHooks) do
		for v, _ in pairs (t) do
			CAdmin.Usermessages.RemoveInterceptHook (k, v)
		end
	end
end)