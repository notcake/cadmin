--[[
	Provides functions for using datastreams.
]]
CAdmin.RequireInclude ("sh_hooks")
require ("datastream")

CAdmin.Datastream = CAdmin.Datastream or {}
local Datastream = CAdmin.Datastream
Datastream.StreamReceivers = {}
Datastream.StreamSenders = {}

--[[
	Functions for stripping out the unnecessary arguments.
]]
local function ClientStreamReceiver (streamName, id, encodedData, decodedData)
	Msg ("Receiving stream " .. streamName .. " of length " .. tostring (encodedData:len ()) .. " bytes.\n")
	Datastream.StreamReceivers [streamName] (LocalPlayer (), decodedData)
end

local function ServerStreamReceiver (ply, streamName, id, encodedData, decodedData)
	Datastream.StreamReceivers [streamName] (ply, decodedData)
end

local StreamReceiver = ClientStreamReceiver
if SERVER then
	StreamReceiver = ServerStreamReceiver
end

function Datastream.RegisterClientToServerStream (streamName, sendFunc, receiveFunc)
	if SERVER then
		Datastream.RegisterStreamReceiver (streamName, receiveFunc)
	end
	if CLIENT then
		Datastream.RegisterStreamSender (streamName, sendFunc)
	end
end

function Datastream.RegisterServerToClientStream (streamName, sendFunc, receiveFunc)
	if CLIENT then
		Datastream.RegisterStreamReceiver (streamName, receiveFunc)
	end
	if SERVER then
		Datastream.RegisterStreamSender (streamName, sendFunc)
	end
end

function Datastream.RegisterStream (streamName, sendFunc, receiveFunc)
	Datastream.RegisterStreamReceiver (streamName, receiveFunc)
	Datastream.RegisterStreamSender (streamName, sendFunc)
end

function Datastream.RegisterStreamReceiver (streamName, receiveFunc)
	datastream.Hook (streamName, StreamReceiver)
	Datastream.StreamReceivers [streamName] = receiveFunc
end

function Datastream.RegisterStreamSender (streamName, sendFunc)
	Datastream.StreamSenders [streamName] = sendFunc
end

function Datastream.SendStream (streamName, ply, sendData, ...)
	if CLIENT then
		ply = ply or LocalPlayer ()
		if not ply or not ply:IsValid () then
			CAdmin.Timers.RunNextTick (Datastream.SendStream, streamName, ply, sendData, ...)
			return
		end
	end
	if Datastream.StreamSenders [streamName] then
		ply, sendData = Datastream.StreamSenders [streamName] (ply, sendData, ...)
	end
	if not sendData then
		return false
	end
	Msg ("Sending stream " .. streamName .. " to:\n")
	if type (ply) == "table" then
		CAdmin.Debug.PrintTable (ply)
	else
		CAdmin.Debug.PrintTable ({ply})
	end
	if SERVER then
		if not ply or type (ply) == "table" and #ply == 0 then
			return false
		end
		if ply.IsValid and not ply:IsValid () then
			return false
		end
		datastream.StreamToClients (ply, streamName, sendData)
	elseif CLIENT then
		datastream.StreamToServer (streamName, sendData)
	end
	return true
end

CAdmin.Hooks.Add ("CAdminInitialize", "CAdmin.Datastream.Initialize", function ()
	CAdmin.Hooks.Add ("AcceptStream", "CAdmin.Datastream.AcceptStream", function (ply, streamName, id)
		if CAdmin.Datastream.StreamReceivers [streamName] then
			return true
		end
	end)
	
	CAdmin.Lua.IncludeFolder ("shared/includes/datastreams")
end)