CAdmin.Messages = CAdmin.Messages or {}
CAdmin.Messages.LogBuffer = CAdmin.Messages.LogBuffer or ""
CAdmin.Messages.LogFile = nil

local WroteHeader = false
local BUFFER_SIZE = 1024	-- Bytes to accumulate before writing to log file.

local function WriteHeader ()
	if WroteHeader then
		return
	end
	if not gmod.GetGamemode () then
		return
	end
	WroteHeader = true
	local servername = GetHostName ()
	if SERVER then
		servername = GetConVarString ("hostname")
	end
	CAdmin.Messages.AppendToLog ("Server: " .. servername .. ".\n")
	CAdmin.Messages.AppendToLog ("Map: " .. game.GetMap () .. ".\n")
	CAdmin.Messages.AppendToLog ("Gamemode: " .. gmod.GetGamemode ().Name .. ".\n")
end

function CAdmin.Messages.AppendToLog (str)
	if not WroteHeader then
		WriteHeader ()
	end
	str = CAdmin.Messages.FormatTime () .. " " .. str
	CAdmin.Messages.LogBuffer = CAdmin.Messages.LogBuffer .. str
	if CAdmin.Messages.LogBuffer:len () > BUFFER_SIZE then
		CAdmin.Messages.FlushLog ()
	end
end

function CAdmin.Messages.FlushLog (filename)
	if not filename then
		filename = CAdmin.Messages.GetLogPath ()
	end
	filex.Append (filename, CAdmin.Messages.LogBuffer)
	CAdmin.Messages.LogBuffer = ""
end

function CAdmin.Messages.Echo (msg)
	print (msg)
end

function CAdmin.Messages.FormatTime ()
	return "[" .. os.date ("%H:%M:%S") .. "]"
end

function CAdmin.Messages.GetLogFilename ()
	local filename = os.date ("%y-%m-%d") .. ".txt"
	return filename
end

function CAdmin.Messages.GetLogPath ()
	local path = "cadmin/"
	if CLIENT then
		path = path .. "client_logs/"
	elseif SERVER then
		path = path .. "logs/"
	end
	path = path .. CAdmin.Messages.GetLogFilename ()

	if CAdmin.Messages.LogFile and path ~= CAdmin.Messages.LogFile then
		WriteHeader ()
		CAdmin.Messages.LogBuffer = CAdmin.Messages.LogBuffer .. "Log is continued in " .. path .. "\n"
		CAdmin.Messages.FlushLog (CAdmin.Messages.LogFile)
		CAdmin.Messages.LogFile = path
		CAdmin.Messages.LogBuffer = CAdmin.Messages.LogBuffer .. "Log continued from " .. CAdmin.Messages.LogFile .. "\n"
	end
	return path
end

function CAdmin.Messages.LogCommand (logtbl, localOnly)
	if not logtbl.LogString then
		return
	end
	if SERVER and not localOnly then
		if logtbl.Targets then
			for k, v in pairs (logtbl.Targets) do
				local str = tostring (v)
				if CAdmin.Commands.GetArgumentTypeName (v) == "Plugin" then
					v = v.Name
				end
				if type (v) == "table" or type (v) == "Player" or v.Name then
					if type (v.Name) == "function" then
						str = v:Name ()
					else
						str = v.Name
					end
				end
				logtbl.Targets [k] = {
					String = str,
					Target = v
				}
			end
		end
		CAdmin.RPC.BroadcastCall ("CAdmin.Messages.LogCommand", {logtbl})
	end
	if logtbl.Player and not logtbl.Player:IsValid () then
		logtbl.Player = CAdmin.Players.GetConsole ()
	end
	local targetstring = nil
	if logtbl.Targets then
		for k, v in pairs (logtbl.Targets) do
			local target = v
			if v.Target then
				target = v.Target
			end
			if target.IsValid and not target:IsValid () then
				target = v.String
			end
			local str = CAdmin.Commands.ConvertArgument (logtbl.Player, target, "String", nil, true) or "[" .. CAdmin.Commands.GetArgumentTypeName (target) .. "]"
			if CLIENT and target == LocalPlayer () then
				str = "yourself"
			end
			if targetstring then
				local add = ", "
				if k == #logtbl.Targets then
					add = " and "
				end
				targetstring = targetstring .. add .. str
			else
				targetstring = str
			end
		end
	end

	local str = logtbl.LogString
	str = string.gsub (str, "(%%[a-zA-Z0-9']+%%)", function (capture)
		local lcapture = capture:lower ()
		lcapture = string.gsub (lcapture, "%%arg([0-9]+)%%", function (a)
			local idx = tonumber (a)
			if idx == 0 then
				return targetstring
			end
			local replacement = logtbl.Arguments [idx] or "0"
			replacement = tostring (replacement)
			return replacement
		end)
		local ret = lcapture
		if lcapture == "%s%" then
			if logtbl.AffectedCount == 1 then
				ret = ""
			else
				ret = "s"
			end
		elseif lcapture == "%self%" then
			if CLIENT and logtbl.Player == LocalPlayer () then
				ret = "yourself"
			else
				ret = "themself"
			end
		elseif lcapture == "%player%" then
			ret = logtbl.Player:Name ()
			if CLIENT and logtbl.Player == LocalPlayer () then
				if capture == "%Player%" then
					ret = "You"
				else
					ret = "you"
				end
			end
		elseif lcapture == "%player's%" then
			ret = logtbl.Player:Name () .. "'s"
			local localPlayer = false
			if CLIENT and logtbl.Player == LocalPlayer () then
				localPlayer = true
			end
			if capture == "%Player's%" then
				ret = localPlayer and "Your" or "Their"
			else
				ret = localPlayer and "your" or "their"
			end
		elseif lcapture == "%target%" then
			ret = targetstring
		end
		return ret
	end)
	CAdmin.Messages.LogString (str)

	-- GLON can't encode the virtual console player.
	-- Do this at the end, since GLON uses a reference to the table, rather than a copy.
	if logtbl.Player and CAdmin.Players.IsConsole (logtbl.Player) then
		logtbl.Player = Entity (0)
	end
end

function CAdmin.Messages.LogString (str, dontlogtofile, dontlogtochat)
	if not dontlogtochat then
		if CLIENT then
			CAdmin.Messages.TsayPlayer (LocalPlayer (), str)
		elseif SERVER then
			CAdmin.Messages.TsayPlayer (CAdmin.Players.GetConsole (), str)
		end
	end
	if not dontlogtofile then
		CAdmin.Messages.AppendToLog (str .. "\n")
	end
end

function CAdmin.Messages.TsayPlayer (ply, message)
	if not ply then
		print ("CAdmin: TsayPlayer called with a nil player.")
		CAdmin.Debug.PrintStackTrace ()
	end
	if message then
		ply:PrintMessage (HUD_PRINTTALK, message)
	else
		print ("CAdmin: TsayPlayer called with no message.")
		CAdmin.Debug.PrintStackTrace ()
	end
end

CAdmin.Hooks.Add ("CAdminInitialize", "CAdmin.Messages.Initialize", function ()
	CAdmin.Messages.LogFile = CAdmin.Messages.GetLogPath ()

	-- Suppress header.
	WroteHeader = true
	CAdmin.Messages.AppendToLog ("CAdmin log opened.\n")
	WroteHeader = false
end)

CAdmin.Hooks.Add ("CAdminUninitialize", "CAdmin.Messages.Uninitialize", function ()
	CAdmin.Messages.AppendToLog ("CAdmin log closed.\n\n")
	CAdmin.Messages.FlushLog ()
end)