local OBJ = CAdmin.Objects.Register ("Plugin")

function OBJ:__init (name, type)
	self.Name = name or "<unnamed>"
	self.Author = nil
	self.Description = nil

	self.Type = type or "Shared"
	self.DelayLoaded = false

	self.Loaded = false
	self.ServerLoaded = false
end

function OBJ:CanLoad ()
	if self.Loaded then
		return false
	end
	if CLIENT and self.Type == "Server" then
		return false
	end
	return true
end

function OBJ:CanServerLoad ()
	return not self.ServerLoaded
end

function OBJ:CanServerUnload ()
	return self.ServerLoaded
end

function OBJ:CanUnload ()
	return self.Loaded
end

function OBJ:GetAuthor ()
	return self.Author
end

function OBJ:GetDelayLoaded ()
	return self.DelayLoaded
end

function OBJ:GetDescription ()
	return self.Description
end

function OBJ:GetLoadedDescription ()
	local str = nil
	if self:IsLoaded () then
		str = "Client"
	end
	if self:IsServerLoaded () then
		if str then
			str = "Both"
		else
			str = "Server"
		end
	end
	return str or ""

end

function OBJ:GetName ()
	return self.Name
end

function OBJ:GetPluginType ()
	return self.Type
end

function OBJ:GetType ()
	return "Plugin"
end

function OBJ:Initialize ()
end

function OBJ:IsLoaded ()
	return self.Loaded
end

function OBJ:IsServerLoaded ()
	return self.ServerLoaded
end

--[[
	Calls the PLUGIN:Initialize function.
	Should not be called directly, use CAdmin.Plugins.Load instead.
]]
function OBJ:Load ()
	if self:IsLoaded () then
		return
	end
	local callHooks = true

	CAdmin.Plugins.SetRunningPlugin (self:GetName ())
	self.Loaded = true
	if SERVER then
		self.ServerLoaded = true
	end
	CAdmin.Plugins.SetRunningPlugin (self:GetName ())
	CAdmin.Lua.TryCall (function (error)
		print ("Failed to load plugin " .. self:GetName () .. ": " .. error)
	end, self.Initialize, self)
	CAdmin.Plugins.SetRunningPlugin ()
end

function OBJ:SetAuthor (author)
	self.Author = author
end

function OBJ:SetDelayLoaded (delayLoaded)
	self.DelayLoaded = delayLoaded
end

function OBJ:SetDescription (desc)
	self.Description = desc
end

function OBJ:SetPluginType (pluginType)
	self.Type = pluginType
end

function OBJ:SetServerLoaded (serverLoaded)
	self.ServerLoaded = serverLoaded
end

function OBJ:Uninitialize ()
end

--[[
	Calls the PLUGIN:Uninitialize function.
	Should not be called directly, use CAdmin.Plugins.Unload instead.
]]
function OBJ:Unload ()
	if not self:IsLoaded () then
		return
	end
	CAdmin.Plugins.SetRunningPlugin (self:GetName ())
	CAdmin.Lua.TryCall (function (error)
		print ("Failed to unload plugin " .. self:GetName () .. ": " .. error)
	end, self.Uninitialize, self)
	self.Loaded = false
	if SERVER then
		self.ServerLoaded = false
	end
end