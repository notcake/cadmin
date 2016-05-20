CAdmin.RequireInclude ("sh_hooks")
CAdmin.RequireInclude ("sh_profiler")

CAdmin.Lua = CAdmin.Lua or {}
local Lua = CAdmin.Lua
Lua.BackedUpObjects = Lua.BackedUpObjects or {}
Lua.BackedUpList = Lua.BackedUpList or {}
Lua.HookedObjects = Lua.HookedObjects or {}
Lua.InvalidHooks = {}	-- This table needs to be recreated every reload.
Lua.CAdminInstalledLocally = file.IsDir ("../addons/cadmin/lua")

function Lua.BackupObject (str)
	if Lua.BackedUpObjects [str] and Lua.BackedUpObjects [str] != Lua.GetObject (str) then
		print ("CAdmin: Object " .. str .. "(" .. type (Lua.GetBackupObject (str)) .. ") is already backed up.")
		CAdmin.Debug.PrintStackTrace ()
		return Lua.BackedUpObjects [str]
	end
	Lua.BackedUpObjects [str] = Lua.GetObject (str)
	Lua.BackedUpList [str] = true
	return Lua.BackedUpObjects [str]
end

function Lua.GetBackupObject (str)
	return Lua.BackedUpObjects [str]
end

function Lua.GetLastTableIndex (str)
	local bits = string.Explode (".", str)
	return bits [table.maxn (bits)]
end

function Lua.GetObject (obj)
	local tbl, name = Lua.GetTable (obj)
	return tbl [name]
end

function Lua.GetTable (str)
	local tbl = _G
	local bits = string.Explode (".", str)
	for i = 1, #bits - 1 do
		tbl = tbl [bits [i]]
		if not tbl then
			return nil
		end
	end
	return tbl, bits [#bits]
end

function Lua.HookFunction (functionName, hookFunc)
	local backupFunc = Lua.BackupObject (functionName)
	local containerTable, keyName = Lua.GetTable (functionName)
	local invalidHooks = Lua.InvalidHooks	-- Needs to be an upvalue to survive reloads.
	local hookName = nil
	containerTable [keyName] = function (...)
		-- Check if this hook is still in place.
		if Lua.BackedUpObjects [functionName] and not invalidHooks [hookName] then
			return hookFunc (backupFunc, ...)
		else
			return backupFunc (...)
		end
	end
	hookName = tostring (containerTable [keyName])
	Lua.HookedObjects [functionName] = containerTable [keyName]
end

if Lua.CAdminInstalledLocally then
	function Lua.Include (fileName)
		local fileCode = file.Read ("../addons/cadmin/lua/cadmin/" .. fileName)
		
		if fileCode then
			RunString (fileCode)
		else
			include ("cadmin/" .. fileName)
		end
	end
else
	function Lua.Include (fileName)
		include ("cadmin/" .. fileName)
	end
end

local function IncludeFolderNoCall (folder)
	CAdmin.Profiler.EnterFunction ("CAdmin.Lua.IncludeFolder (FindInLua)")
	local fileList = file.FindInLua ("cadmin/" .. folder .. "/*.lua")
	CAdmin.Profiler.ExitFunction ()
	CAdmin.Profiler.EnterFunction ("CAdmin.Lua.IncludeFolderNoCall (Includes)")
	for _, v in pairs (fileList) do
		Lua.Include (folder .. "/" .. v)
	end
	CAdmin.Profiler.ExitFunction ()
end

--[[
	Includes all lua files in a folder.
	pre and post are run before and after a file is included, respectively.
]]
function Lua.IncludeFolder (folder, preFunc, postFunc)
	CAdmin.Profiler.EnterFunction ("CAdmin.Lua.IncludeFolder", folder)

	if not preFunc and not postFunc then
		IncludeFolderNoCall (folder)
		CAdmin.Profiler.ExitFunction ()
		return
	end
	CAdmin.Profiler.EnterFunction ("CAdmin.Lua.IncludeFolder (FindInLua)")
	local fileList = file.FindInLua ("cadmin/" .. folder .. "/*.lua")
	CAdmin.Profiler.ExitFunction ()
	
	CAdmin.Profiler.EnterFunction ("CAdmin.Lua.IncludeFolder (Includes)")
	for _, v in pairs (fileList) do
		if preFunc then
			preFunc (v)
		end
		include ("cadmin/" .. folder .. "/" .. v)
		if postFunc then
			postFunc (v)
		end
	end
	CAdmin.Profiler.ExitFunction ()
	CAdmin.Profiler.ExitFunction ()
end

function Lua.RestoreObject (str)
	local tbl, name = Lua.GetTable (str)
	if not tbl then
		return
	end
	local obj = Lua.BackedUpObjects [str]

	local failure = false
	if Lua.HookedObjects [str] then
		if tbl [name] ~= Lua.HookedObjects [str] then
			print ("CAdmin: Cannot restore hooked object " .. str .. ".")
			failure = true
			--[[
				This addon hooked the function first, and redirects calls to the original function.
				Then some other addon hooked it too, and redirects calls to our hook.
			]]
			Lua.InvalidHooks [tostring (Lua.HookedObjects [str])] = true
		end
		Lua.HookedObjects [str] = nil
	end
	if not failure and Lua.BackedUpList [str] then
		tbl [name] = obj
	end
	Lua.BackedUpList [str] = nil
	Lua.BackedUpObjects [str] = nil
end

function Lua.TryCall (errorFunc, func, ...)
	-- If a function is not given, use Msg. It shouldn't really do anything.
	func = func or Msg
	local status, r0error, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10 = pcall (func, ...)
	if not status then
		if type (r0error) ~= "string" then
			if type (r0error) == "table" then
				print ("Error returned was a table:")
				CAdmin.Debug.PrintTable (r0error)
			end
			r0error = tostring (r0error)
		end
		if errorFunc then
			errorFunc (r0error)
		else
			print ("Lua Error: " .. r0error)
		end
	end
	return r0error, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10
end

Lua.UnhookFunction = Lua.RestoreObject

CAdmin.Hooks.Add ("CAdminUninitialize", "CAdmin.Lua.Uninitialized", function ()
	for k, _ in pairs (Lua.BackedUpObjects) do
		Lua.RestoreObject (k)
	end
end)