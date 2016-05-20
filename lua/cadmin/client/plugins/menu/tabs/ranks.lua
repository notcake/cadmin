local TAB = TAB
TAB:SetName ("Ranks")
TAB:SetIcon ("gui/silkicons/group")
TAB:SetTabPosition (2)
TAB:SetTooltip ("Manage user ranks and priveliges.")

local SELECTION_GROUP		= 0
local SELECTION_PRIVLIGES	= 1

function TAB:Init ()
	self.SelectionMode = 0
	self.SelectedGroup = nil

	self.GroupListWidth = 0.2
	self.GroupList = self:Create ("CListView", self:GetContentPanel ())
	self.GroupList:AddColumn ("Group")
	self.GroupList:SetMultiSelect (false)
	self.GroupList.OnSelectionChanged = function (list, selected)
		self.SelectionMode = SELECTION_GROUP
		if selected [1] then
			self.SelectedGroup = selected [1].GroupName
		else
			self.SelectedGroup = nil
		end
		self:PopulateDerivedGroups ()
		self:PopulatePriveliges ()
	end

	self.DerivedGroupList = self:Create ("CListView", self:GetContentPanel ())
	self.DerivedGroupList:AddColumn ("Derived Group")
	self.DerivedGroupList.OnSelectionChanged = function (list, selected)
		self.SelectionMode = SELECTION_GROUP
		if selected [1] then
			self.SelectedGroup = selected [1].GroupName
		else
			self.SelectedGroup = nil
		end
		self:PopulatePriveliges ()
	end

	self.PriveligeList = self:Create ("CListView", self:GetContentPanel ())
	self.PriveligeList:AddColumn ("Privelige")

	self:PopulateGroups ()

	self:SetCommandArgumentType ("Group")
	self:CreateCommandList ()
	self:UpdateCommands ()

	CAdmin.Hooks.Add ("CAdminGroupAdded", "CAdmin.Menu.Ranks.Update", function ()
		self:PopulateGroups ()
	end)

	CAdmin.Hooks.Add ("CAdminGroupDataChanged", "CAdmin.Menu.Ranks.Update", function ()
		self:PopulateGroups ()
	end)
	
	CAdmin.Hooks.Add ("CAdminGroupPriveligesChanged", "CAdmin.Menu.Ranks.Update", function ()
		self:PopulatePriveliges ()
	end)

	CAdmin.Hooks.Add ("CAdminGroupRemoved", "CAdmin.Menu.Ranks.Update", function ()
		self:PopulateGroups ()
	end)

	CAdmin.Hooks.Add ("CAdminLocalPlayerPriveligesChanged", "CAdmin.Menu.Ranks.Update", function ()
		self:UpdateCommands ()
	end)
end

function TAB:PerformLayout ()
	self.GroupList:SetPos (self:GetPadding (), self:GetPadding ())
	self.GroupList:SetSize (self:GetWide () * self.GroupListWidth - 1.5 * self:GetPadding (), self:GetTall () * 0.75 - 1.5 * self:GetPadding ())

	self.DerivedGroupList:SetPos (self:GetPadding (), self:GetTall () * 0.75 + self:GetPadding () * 0.5)
	self.DerivedGroupList:SetSize (self:GetWide () * self.GroupListWidth - 1.5 * self:GetPadding (), self:GetTall () * 0.25 - 1.5 * self:GetPadding ())

	self:PerformCommandListLayout ()

	self.PriveligeList:SetPos (self.GroupList:GetWide () + 2 * self:GetPadding (), self:GetPadding ())
	self.PriveligeList:SetSize (self:GetWide () - self.CommandList:GetWide () - self.GroupList:GetWide () - 4 * self.Padding, self:GetTall () - 2 * self:GetPadding ())
end

function TAB:PopulateGroups ()
	self.GroupList:Clear ()

	local groups = CAdmin.Priveliges.GetGroups ()
	local line = nil
	for k, v in pairs (groups) do
		line = self.GroupList:AddLine (v.Name)
		line.GroupName = k
		line:SetIcon (CAdmin.Priveliges.GetGroupIcon (k))
	end
	self.GroupList:SortByColumn (1)
end

function TAB:PopulateDerivedGroups ()
	self.DerivedGroupList:Clear ()

	if #self.GroupList:GetSelected () == 0 then
		return
	end

	local selected = self.GroupList:GetSelected () [1].GroupName
	local groups = CAdmin.Priveliges.GetGroups ()
	local line = nil
	for k, v in pairs (groups) do
		if v.Base == selected then
			line = self.DerivedGroupList:AddLine (v.Name)
			line.GroupName = k
			line:SetIcon (CAdmin.Priveliges.GetGroupIcon (k))
		end
	end
end

function TAB:PopulatePriveliges ()
	self.PriveligeList:Clear ()

	if #self.GroupList:GetSelected () == 0 then
		return
	end
	local allow = CAdmin.Priveliges.GetGroupPriveliges (self.SelectedGroup)
	for k, v in pairs (allow) do
		if v == true then
			self.PriveligeList:AddLine (k)
		else
			self.PriveligeList:AddLine (k .. " " .. v)
		end
	end
	self.PriveligeList:SortByColumn (1)
end

CAdmin.Hooks.Add ("CAdminPriveligesChanged", "CAdmin.Menu.Ranks.Refresh", function ()
	if CAdmin.Settings.GetSession ("CAdmin.Busy") == 0 then
		TAB:UpdateCommands ()
	end
end)

CAdmin.Hooks.Add ("CAdminExitBusy", "CAdmin.Menu.Ranks.Refresh", function ()
	TAB:UpdateCommands ()
end)

CAdmin.Hooks.Add ("CAdminFallbackChanged", "CAdmin.Menu.Ranks.Refresh", function (fallbackName)
	if fallbackName == "CAdmin.Priveliges.GetGroups" then
		TAB:PopulateGroups ()
	end
end)