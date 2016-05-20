local PANEL = {}

function PANEL:Init ()
	self.TabCount = 0
	self.TabsCreated = 0
	self.Tabs = {}
	self.TabClass = "PropertySheet Tab"

	local OldPerformLayout = self.PerformLayout
	function self:PerformLayout (...)
		OldPerformLayout (self, ...)
		self:PerformTabLayout (...)
	end
end

function PANEL:Uninit ()
	self.Tabs = nil
end

function PANEL:CreateTab (name)
	local tab = self:GetTab (name)
	if tab then
		return tab
	end
	name = name or "<unnamed " .. tostring (self:GetTotalCreatedTabs ()) .. ">"

	tab = CAdmin.Objects.Create (self:GetTabClass (), self, name)
	self:GetTabs () [name] = tab

	self.TabCount = self.TabCount + 1
	self.TabsCreated = self.TabsCreated + 1

	return tab
end

local function TabSortFunction (a, b)
	return a:GetTabPosition () < b:GetTabPosition ()
end

function PANEL:CreateTabs ()
	local sorted = {}
	for _, v in pairs (self:GetTabs ()) do
		sorted [#sorted + 1] = v
	end
	table.sort (sorted, TabSortFunction)
	for _, v in pairs (sorted) do
		self:AddSheet (v:GetName (), v:GetContentPanel (), v:GetIcon (), false, false, v:GetTooltip ())
	end
	for k, v in pairs (self.Items) do
		local tab = self:GetTab (v.Tab:GetValue ())
		tab.Sheet = v
	end

	for _, v in pairs (self:GetTabs ()) do
		CAdmin.Lua.TryCall (function (error)
			print ("Lua Error in PropertySheet tab \"" .. v:GetName () .. "\": " .. error)
		end, v.Init, v)
	end
end

function PANEL:GetBackgroundColor ()
	return self.BackgroundColor or derma.GetDefaultSkin ().colPropertySheet
end

function PANEL:GetTab (name)
	return self:GetTabs () [name]
end

function PANEL:GetTabs ()
	return self.Tabs
end

function PANEL:GetTabClass ()
	return self.TabClass
end

function PANEL:Paint ()
	-- Derived from SKIN:PaintPropertySheet in skins/default.lua

	local ActiveTab = self:GetActiveTab ()
	local Offset = 0
	if ActiveTab then
		Offset = ActiveTab:GetTall ()
	end
	draw.RoundedBox (4, 0, Offset, self:GetWide (), self:GetTall () - Offset, self:GetBackgroundColor ())
end

function PANEL:PerformTabLayout (...)
	for _, v in pairs (self:GetTabs ()) do
		v:GetContentPanel ():SetSize (self:GetWide () - self:GetPadding () * 2, self:GetTall () - self:GetPadding () * 2 - self.tabScroller:GetTall () + 3)
		v:PerformLayout (...)
	end
end

local function PostIncludeFile (fileName)
	TAB = nil
end

function PANEL:LoadFolder (folder)
	CAdmin.Lua.BackupObject ("TAB")
	CAdmin.Lua.IncludeFolder (folder, function (file)
		TAB = self:CreateTab (file)
	end, PostIncludeFile)
	CAdmin.Lua.RestoreObject ("TAB")
end

function PANEL:SetBackgroundColor (color)
	self.BackgroundColor = color
end

function PANEL:SetTabClass (class)
	self.TabClass = class
end

function PANEL:GetTotalCreatedTabs ()
	return self.TabsCreated
end

CAdmin.GUI.Register ("CPropertySheet", PANEL, "DPropertySheet")