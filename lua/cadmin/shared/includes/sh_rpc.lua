CAdmin.RequireInclude ("sh_datastream")
CAdmin.RequireInclude ("sh_hooks")

CAdmin.RPC = CAdmin.RPC or {}

--[[
	Runs a lua string on every client.
]]
function CAdmin.RPC.BroadcastLua (code)
	if CLIENT then
		RunString (code)
		return
	end
	code = CAdmin.RPC.CompressCode (code)
	BroadcastLua (code)
end

--[[
	Sends a lua variable to every client.
]]
function CAdmin.RPC.BroadcastLuaVar (var, value)
	if CLIENT then
		return
	end
	if value == nil then
		RunString ("CAdmin.RPC.Value = " .. var)
		value = CAdmin.RPC.Value
		CAdmin.RPC.Value = nil
	end
	datastream.StreamToClients (player.GetAll (), "CAdmin.RPC.SendLuaVar",
		{
			var,
			value
		}
	)
end

--[[
	Calls a function with the given arguments on every client.
]]
function CAdmin.RPC.BroadcastCall (func, argumentList)
	if CLIENT then
		RunString ("CAdmin.RPC.Function = " .. func)
		CAdmin.RPC.Function (unpack (argumentList))
		CAdmin.RPC.Function = nil
	elseif SERVER then
		datastream.StreamToClients (player.GetAll (), "CAdmin.RPC.BroadcastCall",
			{
				func, argumentList
			}
		)
	end
end

function CAdmin.RPC.CompressCode (code)
	local oldLength = code:len ()
	code = string.gsub (code, "[ \t\r\n]+", " ")
	code = string.gsub (code, " ?([%(%)%[%]=<>!%.\",]) ?", "%1")
	code = code:Trim ()
	return code
end

--[[
	Calls CAdmin.Hooks.Call on every client.
]]
function CAdmin.RPC.FireEvent (name, ...)
	if CLIENT then
		hook.Call (name, nil, ...)
	else
		datastream.StreamToClients (CAdmin.Players.GetCAdminPlayers (), "CAdmin.RPC.FireEvent", {name, {...}})
	end
end

CAdmin.Datastream.RegisterServerToClientStream ("CAdmin.RPC.BroadcastCall", nil, function (ply, callData)
	RunString ("CAdmin.RPC.Function = " .. callData [1])
	CAdmin.RPC.Function (unpack (callData [2]))
	CAdmin.RPC.Function = nil
end)

CAdmin.Datastream.RegisterServerToClientStream ("CAdmin.RPC.FireEvent", nil, function (ply, eventData)
	CAdmin.Hooks.Call (eventData [1], unpack (eventData [2]))
end)

CAdmin.Datastream.RegisterServerToClientStream ("CAdmin.RPC.SendLuaVar", nil, function (ply, varData)
	CAdmin.RPC.Value = varData [2]
	RunString (varData [1] .. " = CAdmin.RPC.Value")
	CAdmin.RPC.Value = nil
end)

--[[
	Runs a lua string on one client.
]]
function CAdmin.RPC.SendLua (ply, code)
	if CLIENT then
		if ply:EntIndex () == LocalPlayer ():EntIndex () then
			RunString (code)
		end
		return
	end
	code = CAdmin.RPC.CompressCode (code)
	if code:len () > 255 then
		datastream.StreamToClients (ply, "CAdmin.RPC.RunLua", {
			code
		})
	else
		ply:SendLua (code)
	end
end

--[[
	Calls a function with the givnen arguments on a client.
]]
function CAdmin.RPC.SendCall (ply, func, argumentList)
	if CLIENT then
		return
	end
	if type (ply) ~= "table" then
		ply = {ply}
	end
	datastream.StreamToClients (ply, "CAdmin.RPC.BroadcastCall",
		{
			func,
			argumentList
		}
	)
end

--[[
	Sends a lua variable to one client.
]]
function CAdmin.RPC.SendLuaVar (ply, var, value)
	if CLIENT then
		return
	end
	if value == nil then
		RunString ("CAdmin.RPC.Value = " .. var)
		value = CAdmin.RPC.Value
		CAdmin.RPC.Value = nil
	end
	if type (ply) ~= "table" then
		ply = {ply}
	end
	datastream.StreamToClients (ply, "CAdmin.RPC.SendLuaVar",
		{
			var,
			value
		}
	)
end

if CLIENT then
	datastream.Hook ("CAdmin.RPC.RunLua", function (_, _, _, data)
		RunString (data [1])
	end)
end