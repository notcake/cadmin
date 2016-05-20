local PLUGIN = CAdmin.Plugins.Create ("Anti Bullshit")
PLUGIN:SetAuthor ("!cake")
PLUGIN:SetDescription ("Stops servers from running ridiculous scripts.")
--[[
	This will not stop _R.Player.ConCommand, or server plugins.
]]

local blockedConVars = {
	["_restart"] = true,
	["+duck"] = true,
	["+jump"] = true,
	["+showscores"] = true,
	["-duck"] = true,
	["-jump"] = true,
	["-showscores"] = true,
	["cancelselect"] = true,
	["connect"] = true,
	["disconnect"] = true,
	["exit"] = true,
	["gameui_activate"] = true,
	["gameui_allowescape"] = true,
	["gameui_allowescapetoshow"] = true,
	["gameui_show"] = true,
	["killserver"] = true,
	["lua_openscript_cl"] = true,
	["quit"] = true,
	["retry"] = true,
	["say"] = true,
	["say_team"] = true,
	["sv_timeout"] = true,
	["toggleconsole"] = true
}

local blockedCommands = {
	["con_filter_enable"] = true,
	["con_filter_text_out"] = true,
	["connect"] = true,
	["clear"] = true,
	["disconnect"] = true,
	["gamemenucommand"] = true,
	-- ["gameui_hide"] = true,
	-- ["gameui_preventescape"] = true,
	-- ["gameui_preventescapetoshow"] = true,
	["lua_run_cl"] = true
}

local convarBlockedCommands = {
	["gameui_preventescape"] = true,
	["gameui_preventescapetoshow"] = true,
	["lua_run_cl"] = true,
	["plugin_load"] = true
}

if true then
	convarBlockedCommands ["bind"] = true
	convarBlockedCommands ["clear"] = true
	convarBlockedCommands ["host_writeconfig"] = true
	convarBlockedCommands ["unbindall"] = true
end

function PLUGIN:Initialize ()
	local alreadyBlocked = {}

	--[[
	-- It's over ;_;
	CAdmin.Lua.HookFunction ("CreateClientConVar", function (_CreateClientConVar, convarName, value, ...)
		if blockedConVars [convarName:lower ()] then
			if alreadyBlocked [convarName] then
				return
			end
			alreadyBlocked [convarName] = true
			MsgC (Color (255, 0, 0, 255), "Anticrap: Blocked creation of convar \"" .. convarName .. " with value \"" .. tostring (value) .. "\"!\n")
			CAdmin.Messages.AppendToLog ("Anticrap: Blocked creation of convar \"" .. convarName .. " with value \"" .. tostring (value) .. "\"!\n")
			return nil
		end
		return _CreateClientConVar (convarName, value, ...)
	end)
	
	CAdmin.Lua.HookFunction ("CreateConVar", function (_CreateConVar, convarName, value, ...)
		if blockedConVars [convarName:lower ()] then
			if alreadyBlocked [convarName] then
				return
			end
			alreadyBlocked [convarName] = true
			MsgC (Color (255, 0, 0, 255), "Anticrap: Blocked creation of convar \"" .. convarName .. " with value \"" .. tostring (value) .. "\"!\n")
			CAdmin.Messages.AppendToLog ("Anticrap: Blocked creation of convar \"" .. convarName .. " with value \"" .. tostring (value) .. "\"!\n")
			return nil
		end
		return _CreateConVar (convarName, value, ...)
	end)
	]]
	
	CAdmin.Lua.HookFunction ("RunConsoleCommand", function (_RunConsoleCommand, consoleCommand, ...)
		if blockedCommands [consoleCommand:lower ()] then
			MsgC (Color (255, 0, 0, 255), "Anticrap: Blocked console command \"" .. table.concat ({consoleCommand, ...}, " ") .. "\" from running!\n")
			CAdmin.Messages.AppendToLog ("Anticrap: Blocked console command \"" .. table.concat ({consoleCommand, ...}, " ") .. "\" from running!\n")
			return
		end
		_RunConsoleCommand (consoleCommand, ...)
	end)
	
	--[[
	-- It's over ;_;
	for k, _ in pairs (convarBlockedCommands) do
		CreateClientConVar (k, "Blocked", false, false)
		CAdmin.Console.AddChangeCallback (k, function (convarName, oldValue, newValue)
			if newValue == "Blocked" then
				return
			end
			MsgC (Color (255, 0, 0, 255), "Anticrap: Blocked command \"" .. k .. "\" with arguments \"" .. tostring (newValue) .. "\".\n")
			CAdmin.Messages.AppendToLog ("Anticrap: Blocked command \"" .. k .. "\" with arguments \"" .. tostring (newValue) .. "\".\n")
			RunConsoleCommand (convarName, "Blocked")
		end)
	end
	]]
	
	CAdmin.Lua.HookFunction ("CompileString", function (_CompileString, code, ...)
		if code:sub (1, 27) ~= "Compiler.native = function(" and
			code:sub (1, 42) ~= "native = function(self) return self.vars[\"" and
			code:sub (1, 11) ~= "-- HTTPFS\r\n" then
			local logCode = tostring (code):gsub("\r\n", "\n")
			local lines = string.Explode ("\n", logCode)
			MsgC (Color (255, 0, 0, 255), "Anticrap: CompileString:\n")
			CAdmin.Messages.AppendToLog ("Anticrap: CompileString:\n")
			for _, line in ipairs (lines) do
				MsgC (Color (255, 0, 0, 255), "\t" .. line .. "\n")
				CAdmin.Messages.AppendToLog ("\t" .. line .. "\n")
			end
		end
		return _CompileString (code, ...)
	end)
	
	CAdmin.Lua.HookFunction ("RunString", function (_RunString, code, ...)
		if code:sub (1, 27) ~= "Compiler.native = function(" and
			code:sub (1, 42) ~= "native = function(self) return self.vars[\"" and
			code:sub (1, 11) ~= "-- HTTPFS\r\n" then
			local logCode = tostring (code):gsub("\r\n", "\n")
			local lines = string.Explode ("\n", logCode)
			MsgC (Color (255, 0, 0, 255), "Anticrap: RunString:\n")
			CAdmin.Messages.AppendToLog ("Anticrap: RunString:\n")
			for _, line in ipairs (lines) do
				MsgC (Color (255, 0, 0, 255), "\t" .. line .. "\n")
				CAdmin.Messages.AppendToLog ("\t" .. line .. "\n")
			end
		end
		return _RunString (code, ...)
	end)
	
	local function IsBadPath (fileName)
		return fileName:sub (1, 1) == "/" or fileName:sub (1, 1) == "\\"
	end
	
	CAdmin.Lua.HookFunction ("file.Read", function (_fileRead, fileName, ...)
		if IsBadPath (fileName) then
			MsgC (Color (255, 0, 0, 255), "file.Read blocked: " .. tostring (fileName) .. "\n")
			return "GTFO"
		else
			MsgC (Color (255, 0, 0, 255), "file.Read: " .. tostring (fileName) .. "\n")
		end
		return _fileRead (fileName, ...)
	end)
	
	CAdmin.Lua.HookFunction ("file.Exists", function (_fileExists, fileName, ...)
		MsgC (Color (255, 0, 0, 255), "file.Exists: " .. tostring (fileName) .. "\n")
		return _fileExists (fileName, ...)
	end)
	
	CAdmin.Lua.HookFunction ("file.Find", function (_fileFind, fileName, ...)
		MsgC (Color (255, 0, 0, 255), "file.Find: " .. tostring (fileName) .. "\n")
		return _fileFind (fileName, ...)
	end)
	
	CAdmin.Lua.HookFunction ("file.TFind", function (_fileTFind, fileName, ...)
		MsgC (Color (255, 0, 0, 255), "file.TFind: " .. tostring (fileName) .. "\n")
		return _fileTFind (fileName, ...)
	end)
	
	CAdmin.Lua.HookFunction ("file.Write", function (_fileWrite, fileName, fileContents, ...)
		fileContents = fileContents or "[nil]"
		MsgC (Color (255, 0, 0, 255), "file.Write: " .. tostring (fileName) .. " (\"" .. tostring (fileContents:sub (1, 32)):gsub("\r", "\\r"):gsub("\n", "\\n") .. "\")\n")
		return _fileWrite (fileName, fileContents, ...)
	end)
	
	-- Rendering exploits.
	CAdmin.Lua.HookFunction ("render.AddBeam", function (_renderAddBeam, position, width, texture, color)
		if position == nil then
			MsgC (Color (255, 0, 0, 255), "Anticrap: render.AddBeam: Blocked exploit.\n")
			CAdmin.Messages.AppendToLog ("Anticrap: render.AddBeam: Blocked exploit.\n")
		end
		return _renderAddBeam (position or Vector (0, 0, 0), width, texture, color)
	end)
	
	CAdmin.Lua.HookFunction ("surface.DrawPoly", function (_surfaceDrawPoly, tbl)
		if not tbl then
			MsgC (Color (255, 0, 0, 255), "Anticrap: surface.DrawPoly: Blocked exploit.\n")
			CAdmin.Messages.AppendToLog ("Anticrap: surface.DrawPoly: Blocked exploit.\n")
			return nil
		end
		return _surfaceDrawPoly (tbl)
	end)
	
	CAdmin.Lua.HookFunction ("Derma_DrawBackgroundBlur", function (_Derma_DrawBackgroundBlur)
		return
	end)
	
	CAdmin.Hooks.Add ("PlayerBindPress", "CAdmin.AntiCrap.BindPress", function (ply, bind, pressed)
		if pressed and bind == "cancelselect" then
			RunConsoleCommand ("gameui_allowescapetoshow")
			RunConsoleCommand ("gameui_allowescape")
		end
	end)
	
	if blockedCommands ["lua_run_cl"] then
		concommand.Add ("lua_run_cl2", function (ply, _, args)
			local c = table.concat (args, " ")
			RunString (c)
		end)
	end
end

function PLUGIN:Uninitialize ()
	CAdmin.Lua.UnhookFunction ("CreateClientConVar")
	CAdmin.Lua.UnhookFunction ("CreateConVar")
	CAdmin.Lua.UnhookFunction ("RunConsoleCommand")
	
	CAdmin.Lua.UnhookFunction ("CompileString")
	CAdmin.Lua.UnhookFunction ("RunString")
	CAdmin.Lua.UnhookFunction ("file.Exists")
	CAdmin.Lua.UnhookFunction ("file.Find")
	CAdmin.Lua.UnhookFunction ("file.Read")
	CAdmin.Lua.UnhookFunction ("file.TFind")
	CAdmin.Lua.UnhookFunction ("file.Write")
	
	CAdmin.Lua.UnhookFunction ("render.AddBeam")
	CAdmin.Lua.UnhookFunction ("surface.DrawPoly")
end