CAdmin.Downloads = CAdmin.Downloads or {}

function CAdmin.Downloads.AddClientLuaFiles ()
	if CAdmin.Debug.GetDebugMode () > 0 then
		return
	end
	CAdmin.Downloads.AddLuaFile ("autorun/sh_cadmin.lua")
	CAdmin.Downloads.AddLuaFile ("autorun/client/cl_cadmin.lua")
	CAdmin.Downloads.AddLuaFile ("autorun/shared/sh_cadmin.lua")
	CAdmin.Downloads.AddLuaFolderRecursive ("cadmin/client")
	CAdmin.Downloads.AddLuaFolderRecursive ("cadmin/shared")
end

function CAdmin.Downloads.AddLuaFile (file)
	AddCSLuaFile (file)
end

function CAdmin.Downloads.AddLuaFolder (folder)
	local files = file.FindInLua (folder .. "/*")
	for _, fileName in pairs (files) do
		if fileName:sub (-4) == ".lua" then
			AddCSLuaFile (folder .. "/" .. fileName)
		end
	end
end

function CAdmin.Downloads.AddLuaFolderRecursive (folder)
	CAdmin.Profiler.EnterFunction ("Downloads.AddLuaFolderRecursive", folder)
	CAdmin.Downloads.AddLuaFolder (folder)
	local folders = file.FindDir ("../lua/" .. folder .. "/*")
	for _, v in pairs (folders) do
		CAdmin.Downloads.AddLuaFolderRecursive (folder .. "/" .. v)
	end
	CAdmin.Profiler.ExitFunction ()
end