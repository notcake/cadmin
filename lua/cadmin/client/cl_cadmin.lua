function CAdmin.CheckServerRunning ()
	if CAdmin.IsServerRunning () then
		CAdmin.Console.ForwardCommand (LocalPlayer (), "cadmin_client_loaded")
	end
end

function CAdmin.ClientInitialize (suppressStateBroadcast)
	CAdmin.Lua.IncludeFolder ("client/includes")
	CAdmin.Plugins.LoadPluginsFolder ("client/plugins", "Client")

	if CAdmin.IsServerRunning () then
		if not suppressStateBroadcast then
			CAdmin.Console.ForwardCommand (LocalPlayer (), "cadmin_client_loaded")
		end
	else
		CAdmin.Timers.RunNextTick (CAdmin.CheckServerRunning)
	end
end

function CAdmin.ClientUninitialize (suppressStateBroadcast)
	if CAdmin.IsServerRunning () and not suppressStateBroadcast then
		CAdmin.Console.ForwardCommand (LocalPlayer (), "cadmin_client_unloaded")
	end
end

function CAdmin.ReceiveServerState (serverInitialized)
	CAdmin.ServerInitialized = serverInitialized
	if serverInitialized and CAdmin.Initialized then
		CAdmin.Console.ForwardCommand (LocalPlayer (), "cadmin_client_loaded")
	end
end