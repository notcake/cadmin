function CAdmin.ServerInitialize (suppressStateBroadcast)
	CAdmin.Lua.IncludeFolder ("server/includes")
	CAdmin.Plugins.LoadPluginsFolder ("server/plugins", "Server")

	if not suppressStateBroadcast then
		CAdmin.BroadcastServerState ()
	end

	CAdmin.Hooks.Add ("InitPostEntity", "CAdmin.ServerState", function ()
		SetGlobalBool ("CAdmin.ServerInitialized", CAdmin.IsServerRunning ())
	end)

end

function CAdmin.ServerUninitialize (suppressStateBroadcast)
	if not suppressStateBroadcast then
		CAdmin.BroadcastServerState ()
	end
	CAdmin.RPC.FireEvent ("CAdminServerUninitialized")
end

local SendServerStateStringStart = [[
	local C = CAdmin
	if C then
		C.ReceiveServerState (
]]

local SendServerStateStringEnd = [[
		)
	end
]]

function CAdmin.BroadcastServerState ()
	CAdmin.RPC.BroadcastLua (SendServerStateStringStart .. tostring (CAdmin.IsServerRunning ()) .. SendServerStateStringEnd)
end

function CAdmin.SendServerState (ply)
	CAdmin.RPC.SendLua (ply, SendServerStateStringStart .. tostring (CAdmin.IsServerRunning ()) .. SendServerStateStringEnd)
end