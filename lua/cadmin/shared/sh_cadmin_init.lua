if not CAdmin then
	CAdmin = {
		FirstTimeRun = false,
		Initialized = false,
		ServerInitialized = false
	}

	if CLIENT then
		CAdmin.ServerInitialized = GetGlobalBool ("CAdmin.ServerInitialized")
	end
end

local suppressStateBroadcast = false
-- Uninitialize CAdmin if it's already running.
if CAdmin.Initialized then
	if SERVER then
		suppressStateBroadcast = true
	end
	CAdmin.Uninitialize (suppressStateBroadcast)
end

local includes = file.FindInLua ("cadmin/shared/includes/*.lua")
local included = {}

function CAdmin.RequireInclude (file)
	file = file .. ".lua"
	if not included [file] then
		included [file] = true
		include ("cadmin/shared/includes/" .. file)
	end
end

for k, v in pairs (includes) do
	if not included [v] then
		included [v] = true
		include ("includes/" .. v)
	end
end

-- Now initialize the client and server only scripts.
if CLIENT then
	include ("cadmin/client/cl_cadmin.lua")
end
if SERVER then
	include ("cadmin/server/sv_cadmin.lua")
end
include ("sh_cadmin.lua")

-- Start CAdmin
CAdmin.Initialize ()

CAdmin.Console.AddPermanentClientCommand ("cadmin_load", function (ply, _, args)
	if CAdmin.Initialized then
		return
	end
	CAdmin.Reload ()
end)

CAdmin.Console.AddClientCommand ("cadmin_reload", function (ply, _, args)
	CAdmin.Reload ()
end)

CAdmin.Console.AddClientCommand ("cadmin_unload", function (ply, _, args)
	CAdmin.Uninitialize ()
end)

CAdmin.Console.AddPermanentServerCommand ("cadmin_load_sv", function (ply, _, args)
	if CAdmin.Initialized then
		return
	end
	CAdmin.Reload ()
end)

CAdmin.Console.AddServerCommand ("cadmin_reload_sv", function (ply, _, args)
	CAdmin.Reload ()
end)

CAdmin.Console.AddServerCommand ("cadmin_unload_sv", function (ply, _, args)
	CAdmin.Uninitialize ()
end)