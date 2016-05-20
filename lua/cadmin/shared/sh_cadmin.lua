--[[
	Core CAdmin functions.
	
	Hooks:
		CAdminInitialize:
			Called when CAdmin is loading.
		CAdminServerInitialize:
			Called on the client when CAdmin is loading on the server.
		CAdminServerUninitialize:
			Called on the client when CAdmin is unloading on the server.
		CAdminUninitialize:
			Called when CAdmin is unloading.
]]
function CAdmin.Initialize (suppressStateBroadcast)
	if CAdmin.Initialized then
		CAdmin.Messages.Echo ("CAdmin initialize aborted: CAdmin already initialized.")
		return
	end
	CAdmin.Profiler.EnterFunction ("CAdmin.Initialize")
	CAdmin.Hooks.Call ("CAdminPreInitialize")
	CAdmin.Settings.IncreaseSession ("CAdmin.Busy")
	CAdmin.Plugins.LoadPluginsFolder ("shared/plugins", "Shared")
	
	if SERVER then
		CAdmin.ServerInitialized = true
		CAdmin.ServerInitialize (suppressStateBroadcast)
	end
	if CLIENT then
		CAdmin.ClientInitialize (suppressStateBroadcast)
	end
	CAdmin.Hooks.Call ("CAdminInitialize")
	CAdmin.Settings.DecreaseSession ("CAdmin.Busy")
	CAdmin.Hooks.Call ("CAdminPostInitialize")
	if SERVER then
		CAdmin.Downloads.AddClientLuaFiles ()
	end
	if not CAdmin.Settings.Get ("PreviouslyRun", false) then
		CAdmin.FirstTimeRun = true
		CAdmin.Hooks.Call ("CAdminFirstRun")
		CAdmin.Settings.Set ("PreviouslyRun", true)
		CAdmin.Messages.Echo ("CAdmin initialized for the first time.")
	else
		CAdmin.Messages.Echo ("CAdmin initialized.")
	end
	CAdmin.Initialized = true
	CAdmin.Profiler.ExitFunction ()
end

function CAdmin.IsFirstRun ()
	return true
end

function CAdmin.IsRunning ()
	return CAdmin.Initialized
end

function CAdmin.IsServerRunning ()
	return CAdmin.ServerInitialized
end

function CAdmin.Reload ()
	CAdmin.Profiler.EnterFunction ("CAdmin.Reload")
	if CLIENT then
		include ("cadmin/client/cl_cadmin.lua")
	end
	if SERVER then
		include ("cadmin/server/sv_cadmin.lua")
	end
	include ("cadmin/shared/sh_cadmin_init.lua")
	CAdmin.Profiler.ExitFunction ()
end

function CAdmin.Uninitialize (suppressStateBroadcast)
	if not CAdmin.Initialized then
		CAdmin.Messages.Echo ("CAdmin uninitialize aborted: CAdmin already uninitialized.")
		return
	end
	CAdmin.Profiler.EnterFunction ("CAdmin.Uninitialize")
	
	CAdmin.Hooks.Call ("CAdminPreUninitialize")
	CAdmin.Settings.IncreaseSession ("CAdmin.Busy")
	CAdmin.Hooks.Call ("CAdminUninitialize")
	if SERVER then
		CAdmin.ServerInitialized = false
		CAdmin.ServerUninitialize (suppressStateBroadcast)
	end
	if CLIENT then
		CAdmin.ClientUninitialize (suppressStateBroadcast)
	end
	CAdmin.Settings.DecreaseSession ("CAdmin.Busy")
	CAdmin.Hooks.Call ("CAdminPostUninitialize")
	CAdmin.Messages.Echo ("CAdmin uninitialized.")
	CAdmin.Initialized = false
	
	CAdmin.Profiler.ExitFunction ()
end

CAdmin.Hooks.Add ("ShutDown", "CAdmin.ShutDown", function ()
	CAdmin.Uninitialize (true)
end)

if SERVER then
	CAdmin.Console.AddCommand ("cadmin_client_loaded", function (ply)
		CAdmin.Players.PlayerCAdminLoaded (ply)
	end)

	CAdmin.Console.AddCommand ("cadmin_client_unloaded", function (ply)
		CAdmin.Players.PlayerCAdminUnloaded (ply)
	end)
end