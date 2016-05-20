CAdmin.RequireInclude ("sh_hooks")

CAdmin.Settings = CAdmin.Settings or {}
CAdmin.Settings.Settings = {}
CAdmin.Settings.SessionSettings = {}
if SERVER then
	CAdmin.Settings.SettingsPath = "cadmin/settings.txt"
elseif CLIENT then
	CAdmin.Settings.SettingsPath = "cadmin/settings_cl.txt"
end
CAdmin.Settings.Unsaved = false

function CAdmin.Settings.DecreaseSession (name)
	local settings = CAdmin.Settings.SessionSettings
	settings [name] = (settings [name] or 0) - 1
	if settings [name] == 0 and name == "CAdmin.Busy" then
		CAdmin.Hooks.Call ("CAdminExitBusy")
	end
end

function CAdmin.Settings.Get (settingName, default)
	local settings = CAdmin.Settings.Settings
	if settings [settingName] == nil and default ~= nil then
		CAdmin.Settings.Set (settingName, default)
	end
	if settings [settingName] == nil then
		return 0
	else
		return settings [settingName]
	end
end

function CAdmin.Settings.GetNumber (settingName, default)
	local settings = CAdmin.Settings.Settings
	if settings [settingName] == nil and default ~= nil then
		CAdmin.Settings.Set (settingName, default)
	end
	if settings [settingName] == nil then
		return 0
	else
		return tonumber (settings [settingName])
	end
end

function CAdmin.Settings.GetSession (settingName, default)
	local sessionSettings = CAdmin.Settings.SessionSettings
	if sessionSettings [settingName] == nil and default ~= nil then
		CAdmin.Settings.SetSession (settingName, default)
	end
	if sessionSettings [settingName] == nil then
		return false
	else
		return sessionSettings [settingName]
	end
end

function CAdmin.Settings.GetSessionSettings ()
	return CAdmin.Settings.SessionSettings
end

function CAdmin.Settings.GetSettingsPath ()
	return CAdmin.Settings.SettingsPath
end

function CAdmin.Settings.GetSettings ()
	return CAdmin.Settings.Settings
end

function CAdmin.Settings.HasUnsavedData ()
	return CAdmin.Settings.Unsaved
end

function CAdmin.Settings.IncreaseSession (settingName)
	local sessionSettings = CAdmin.Settings.SessionSettings
	sessionSettings [settingName] = (tonumber (sessionSettings [settingName]) or 0) + 1
	if sessionSettings [settingName] == 1 and settingName == "CAdmin.Busy" then
		CAdmin.Hooks.Call ("CAdminEnterBusy")
	end
end

function CAdmin.Settings.Load ()
	local data = file.Read (CAdmin.Settings.GetSettingsPath ())
	if not data then
		return
	end
	local tbl = util.KeyValuesToTable (data)
	for k, v in pairs (tbl) do
		if v == "true" then
			v = true
		elseif v == "false" then
			v = false
		end
		CAdmin.Settings.Settings [CAdmin.Util.URLDecode (k)] = v
	end
end

function CAdmin.Settings.Save ()
	local tbl = {}
	for k, v in pairs (CAdmin.Settings.Settings) do
		tbl [CAdmin.Util.URLEncodeCapitals (k)] = tostring (v)
	end
	file.Write (CAdmin.Settings.GetSettingsPath (), util.TableToKeyValues (tbl))
	CAdmin.Settings.Unsaved = false
end

function CAdmin.Settings.Set (settingName, value)
	local settings = CAdmin.Settings.Settings
	if settings [settingName] ~= value then
		print ("Setting " .. settingName .. " set to " .. tostring (value) ..  ".")
		CAdmin.Settings.Unsaved = true
	end
	settings [settingName] = value
end

function CAdmin.Settings.SetSession (settingName, value)
	CAdmin.Settings.SessionSettings [settingName] = value
end

CAdmin.Hooks.Add ("CAdminPreInitialize", "CAdmin.Settings.PreInitialize", function ()
	CAdmin.Settings.Load ()

	CAdmin.Hooks.Add ("CAdminUninitialize", "CAdmin.Settings.Uninitialize", function ()
		if CAdmin.Settings.HasUnsavedData () then
			CAdmin.Settings.Save ()
		end
	end)
end)