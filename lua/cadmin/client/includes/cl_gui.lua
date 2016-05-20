CAdmin.GUI = CAdmin.GUI or {}
local GUI = CAdmin.GUI
GUI.CleanupPanels = {}
GUI.ClassTables = {}
GUI.Registered = {}
GUI.CurrentDirectory = "client/includes/controls/"

local vguiCreate = vgui.Create
local chainFunctions = {
	"OnMousePressed",
	"OnMouseReleased",
	"PerformLayout",
	"Uninit",
	"UpdateStyle"
}

--[[
	Used in Register
]]
local function PanelCreate (panel, panelType, parent, targetname)
	if not parent then
		parent = panel
	end
	return GUI.Create (panelType, parent, targetName)
end

local function PanelInit (panel)
	if panel._BaseClassName ~= "CBasePanel" then
		GUI.GetClassTable ("CBasePanel").Init (panel)
	end
	if panel._Init then
		panel:_Init ()
	end
	panel._Initialized = true
end

--[[
	Creates a window that is automagically destroyed when CAdmin unloads
	or when the plugin that created it is unloaded.
]]
local function RedirectPanelType (panelType)
	if GUI.Registered ["C" .. panelType] then
		return "C" .. panelType
	end
	return "D" .. panelType
end

local function PanelRemove (self)
	if self.Uninit and self.ClassName:sub (1, 1):upper () == "C" then
		self:Uninit ()
	end
	self:_OldRemove ()
	if self.OnRemove then
		self:OnRemove ()
	end
	self.Plugin = nil
	local cleanupEntry = GUI.CleanupPanels [self.CRC]
	if cleanupEntry and cleanupEntry.Plugin then
		cleanupEntry.Plugin.Panels [self.CRC] = nil
	end
	GUI.CleanupPanels [self.CRC] = nil
end

function GUI.Create (panelType, parent, targetName)
	panelType = string.gsub (panelType, "^D(.*)", RedirectPanelType)

	local panel = vguiCreate (panelType, parent, targetName)
	if not panel then
		return nil
	end
	panel.CRC = util.CRC (tostring (panel))
	
	local runningPlugin = CAdmin.Plugins.GetRunningPlugin ()
	GUI.CleanupPanels [panel.CRC] = {
		Panel = panel,
		Plugin = runningPlugin
	}
	panel.Plugin = runningPlugin

	if runningPlugin then
		if parent then
			GUI.CleanupPanels [panel.CRC].Plugin = nil
		else
			runningPlugin.Panels [panel.CRC] = true
		end
	end

	panel._OldRemove = panel.Remove
	panel.Remove = PanelRemove
	
	local basePanelTable = GUI.GetClassTable ("CBasePanel")
	if not GUI.Registered [panelType] then
		for k, v in pairs (basePanelTable) do 
			if not panel [k] then
				panel [k] = v
			end
		end
	end
	if not panel._Initialized then
		basePanelTable.Init (panel)
		panel._Initialized = true
	end
	return panel
end

--[[
	Copied from DermaMenu.
]]
function GUI.CreateMenu (parentMenu)
	if not parentMenu then
		CloseDermaMenus ()
	end
	local menu = vgui.Create ("CMenu")
	return menu
end

function GUI.Destroy (panel)
	if type (panel) == "string" then
		panel = GUI.CleanupPanels [panel].Panel
	end
	
	if panel:IsValid () then
		panel:Remove ()
	end

	local cleanupEntry = GUI.CleanupPanels [panel.CRC]
	if cleanupEntry then
		if cleanupEntry.Plugin then
			cleanupEntry.Plugin.Panels [panel.CRC] = nil
		end
		GUI.CleanupPanels [panel.CRC] = nil
	end
end

function GUI.GetClassTable (panelType)
	if not panelType then
		return nil
	end
	if GUI.ClassTables [panelType] then
		return GUI.ClassTables [panelType]
	end
	local classTable = nil
	if panelType:sub (1,1) == "D" and _G [panelType] then
		classTable = _G [panelType]
	end
	if panelType == "Panel" then
		classTable = FindMetaTable ("Panel")
	end
	GUI.ClassTables [panelType] = classTable
	return classTable
end

function GUI.GetCurrentDirectory ()
	return self.CurrentDirectory
end

local function VGUICreateHook (oldVGUICreate, panelType, parent, targetName)
	return GUI.Create (panelType, parent, targetName)
end

function GUI.HookVGUICreate ()
	CAdmin.Lua.HookFunction ("vgui.Create", VGUICreateHook)
end

function GUI.Register (panelType, panelTable, baseType)
	if GUI.Registered [panelType] then
		return
	end
	CAdmin.Profiler.EnterFunction ("CAdmin.GUI.Register", panelType)
	
	GUI.ClassTables [panelType] = panelTable
	GUI.Registered [panelType] = panelTable
	panelTable.ClassName = panelTable.ClassName or panelType
	panelTable.Plugin = CAdmin.Plugins.GetRunningPlugin ()
	if baseType then
		panelTable._BaseClassName = baseType
		local baseTable = GUI.GetClassTable (baseType)
		if baseType:sub (1, 1) ~= "D" then
			if not baseTable then
				CAdmin.Lua.Include (GUI.CurrentDirectory .. "/" .. baseType:sub (2) .. ".lua")
				baseTable = GUI.GetClassTable (baseType)
			end
			if baseTable then
				--[[
					Note that this won't work if a class in the hierarchy is missing a function.
				]]
				for _, v in pairs (chainFunctions) do
					local derivedFunc = panelTable [v]
					local baseFunc = baseTable [v]
					if derivedFunc and baseFunc then
						panelTable [v] = function (self, ...)
							baseFunc (self, ...)
							derivedFunc (self, ...)
						end
					end
				end
			end
		end
	end
	if not panelTable.Create then
		panelTable.Create = PanelCreate
	end
	local basePanelTable = GUI.GetClassTable ("CBasePanel")
	if panelType ~= "CBasePanel" and basePanelTable then
		for k, v in pairs (basePanelTable) do 
			if not panelTable [k] then
				panelTable [k] = v
			end
		end
		if panelTable.Init then
			panelTable._Init = panelTable.Init
			panelTable.Init = PanelInit
		end
	end
	vgui.Register (panelType, panelTable, baseType)
	
	CAdmin.Profiler.ExitFunction ()
end

function GUI.RegisterAndCreate (panelType, panelTable, baseType)
	GUI.Register (panelType, panelTable, baseType)
	return GUI.Create (panelType)
end

function GUI.RegisterFolder (folder)
	GUI.SetCurrentDirectory (folder)
	CAdmin.Lua.IncludeFolder (GUI.CurrentDirectory)
end

function GUI.SetCurrentDirectory (currentDirectory)
	GUI.CurrentDirectory = currentDirectory
end

function GUI.UnhookVGUICreate ()
	CAdmin.Lua.UnhookFunction ("vgui.Create")
end

CAdmin.Lua.Include (GUI.CurrentDirectory .. "BasePanel.lua")
CAdmin.GUI.RegisterFolder ("client/includes/controls")
CAdmin.GUI.RegisterFolder ("shared/includes/controls")

CAdmin.Hooks.Add ("CAdminInitialize", "CAdmin.GUI.Initialize", function ()
	CAdmin.Hooks.Add ("CAdminPluginLoaded", "CAdmin.GUI.PluginLoaded", function (pluginList)
		for _, plugin in pairs (pluginList) do
			plugin.Panels = {}
		end
	end)

	CAdmin.Hooks.Add ("CAdminPluginUnloaded", "CAdmin.GUI.PluginUnloaded", function (pluginList)
		for _, plugin in pairs (pluginList) do
			for k, _ in pairs (plugin.Panels) do
				GUI.Destroy (k)
			end
			plugin.Panels = nil
		end
	end)
end)

CAdmin.Hooks.Add ("CAdminUninitialize", "CAdmin.GUI.Uninitialize", function ()
	for _, t in pairs (GUI.CleanupPanels) do
		GUI.Destroy (t.Panel)
	end
	GUI.CleanupPanels = {}
end)