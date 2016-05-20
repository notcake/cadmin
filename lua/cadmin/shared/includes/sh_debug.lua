CAdmin.RequireInclude ("sh_hooks")
CAdmin.RequireInclude ("sh_settings")

CAdmin.Debug = CAdmin.Debug or {}
CAdmin.Debug.HookedFunctions = {
	"hook.Remove",
	"pairs"
}
CAdmin.Debug.FunctionsToRestore = {}
CAdmin.Debug.Mode = 0

CAdmin.Debug.DEBUG_OFF = 0
CAdmin.Debug.DEBUG_ON = 1

function CAdmin.Debug.GetDebugMode ()
	return CAdmin.Debug.Mode
end

--[[
	Dumps function info to the console.
]]
function CAdmin.Debug.PrintFunctionInfo (func)
	local t = debug.getinfo (func)
	if not t then
		return
	else
		local name = t.name
		local src = t.short_src
		src = src or "<unknown>"
		if name then
			print ("Function: " .. name .. " (" .. src .. ": " .. tostring (t.currentline) .. ")")
		else
			if src and t.currentline then
				print ("Function: (" .. src .. ": " .. tostring (t.currentline) .. ")")
			else
				print ("Function:")
				CAdmin.Debug.PrintTable (t)
			end
		end
	end
end

--[[
	Dumps a table to the console.
	Derived from PrintTable.
]]
function CAdmin.Debug.PrintTable (t)
	local lines = CAdmin.Debug.TableToString (t):Split ("\n")
	
	local i = 1
	local function printNextLine ()
		if i > #lines then return end
		
		print (lines [i])
		i = i + 1
		
		timer.Simple (0, function ()
			printNextLine ()
		end)
	end
	
	timer.Simple (0, function ()
		printNextLine ()
	end)
end

--[[
	Dumps a table to the console.
	Does not include child tables.
	Derived from PrintTable.
]]
function CAdmin.Debug.PrintTableShallow (t)
	print ("{")
	for key, value in pairs (t or {["nil"] = "table"}) do
		print ("    " .. tostring (key) .. "\t=\t" .. tostring (value))
	end
	print ("}")
end

--[[
	Dumps a stack trace to the console.
]]
function CAdmin.Debug.PrintStackTrace (levels, offset)
	local offset = offset or 0
	local exit = false
	local i = 0
	local shown = 0
	while not exit do
		local t = debug.getinfo (i)
		if not t or shown == levels then
			exit = true
		else
			local name = t.name
			local src = t.short_src
			src = src or "<unknown>"
			if i >= offset then
				shown = shown + 1
				if name then
					ErrorNoHalt (tostring (i) .. ": " .. name .. " (" .. src .. ": " .. tostring (t.currentline) .. ")\n")
				else
					if src and t.currentline then
						ErrorNoHalt (tostring (i) .. ": (" .. src .. ": " .. tostring (t.currentline) .. ")\n")
					else
						ErrorNoHalt (tostring (i) .. ":\n")
						PrintTable (t)
					end
				end
			end
		end
		i = i + 1
	end
end

function CAdmin.Debug.SetDebugMode (on, doNotSave)
	if CAdmin.Debug.Mode ~= on then
		CAdmin.Hooks.Call ("CAdminDebugMode", on)
	end
	CAdmin.Debug.Mode = on
	if not doNotSave then
		CAdmin.Settings.Set ("Debug.DebugMode", on)
	end
end

--[[
	Converts a table to a printable string
	Derived from PrintTable.
]]
function CAdmin.Debug.TableToString (t, indent, done)
	local ret = ""
	
	if not t then
		return string.rep ("    ", indent) .. "nil"
	end

	done = done or {}
	indent = indent or 0
	ret = ret .. string.rep ("    ", indent) .. "[" .. tostring (t):sub (8) .. "] {\n"
	indent = indent + 1
	for key, value in pairs (t) do
		if type (value) == "table" and not done [value] then
			done [value] = true
			ret = ret .. string.rep ("    ", indent) .. tostring (key) .. ":\n"
			ret = ret .. CAdmin.Debug.TableToString (value, indent, done) .. "\n"
		else
			if type (value) == "string" then
				value = value:gsub ("\\", "\\\\")
				value = value:gsub ("\r", "\\r")
				value = value:gsub ("\n", "\\n")
				value = value:gsub ("\t", "\\t")
				value = value:gsub ("\1", "\\1")
				value = value:gsub ("\2", "\\2")
				value = value:gsub ("\3", "\\3")
				value = value:gsub ("\4", "\\4")
				value = value:gsub ("\5", "\\5")
				value = value:gsub ("\6", "\\6")
				value = value:gsub ("\7", "\\7")
				value = value:gsub ("\8", "\\8")
				value = value:gsub ("\9", "\\9")
				value = value:gsub ("\10", "\\10")
				value = value:gsub ("\255", "\\255")
			end
			ret = ret .. string.rep ("    ", indent) .. tostring (key) .. "\t=\t" .. tostring (value) .. "\n"
		end
	end
	indent = indent - 1
	ret = ret .. string.rep ("    ", indent) .. "}"
	return ret
end

CAdmin.Hooks.Add ("CAdminDebugMode", "CAdmin.Debug.DebugModeChanged", function (mode)
	if mode == CAdmin.Debug.DEBUG_OFF then
		for k, v in pairs (CAdmin.Debug.FunctionsToRestore) do
			CAdmin.Lua.RestoreObject (k)
		end
	else
		for _, v in pairs (CAdmin.Debug.HookedFunctions) do
			CAdmin.Lua.BackupObject (v)
			CAdmin.Debug.FunctionsToRestore [v] = true
		end
		--[[
		CAdmin.Lua.HookFunction ("hook.Remove", function (func, type, name)
			if not hook.GetTable () [type] [name] then
				print ("hook.Remove called with an inexistent hook (\"" .. type .. "\": \"" .. name .. "\").")
				CAdmin.Debug.PrintStackTrace ()
			end
			func (type, name)
		end)CAdmin.Lua.HookFunction ("pairs", function (func, tbl)
			if type (tbl) == "table" then
				return func (tbl)
			else
				print ("pairs called with a non-table argument! (" .. tostring (tbl) .. ").")
				CAdmin.Debug.PrintStackTrace ()
				return nil
			end
		end)]]
	end
end)

CAdmin.Hooks.Add ("CAdminInitialize", "CAdmin.Debug.DebugDisable", function ()
	CAdmin.Debug.SetDebugMode (CAdmin.Settings.GetNumber ("Debug.DebugMode", CAdmin.Debug.DEBUG_OFF))
end)

CAdmin.Hooks.Add ("CAdminUninitialize", "CAdmin.Debug.DebugDisable", function ()
	CAdmin.Debug.SetDebugMode (CAdmin.Debug.DEBUG_OFF, true)
end)