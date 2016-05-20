CAdmin.Lua.IncludeFolder ("server/includes/objects")

CAdmin.Hooks.Add ("CAdminInitialize", "CAdmin.Server.Initialize", function ()
	CAdmin.Tags.Add ("cadmin")
end)