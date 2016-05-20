local PANEL = {}

function PANEL:Init ()
	self.GroupList = self:Create ("DListView")
	self.GroupList:AddColumn ("Name")
	self.GroupList:AddColumn ("Base")
	self.GroupList:SetObjectConverter ("Group")
	
	self:SetSize (0.5 * ScrW (), 0.5 * ScrH ())
end

function PANEL:DoLayout ()
	self:PopulateGroups ()
end

function PANEL:GetArgumentValue ()
	return self.GroupList:GetSelectedObjects ()
end

function PANEL:PerformLayout ()
	local padding = self:GetPadding ()
	self.GroupList:SetPos (padding, padding)
	self.GroupList:SetSize (self:GetWide () - 2 * padding, self:GetTall () - 2 * padding)
end

function PANEL:PopulateGroups ()
	self.GroupList:Clear ()
	
	local line = nil
	for groupID, group in pairs (CAdmin.Priveliges.GetGroups ()) do
		line = self.GroupList:AddLine (CAdmin.Priveliges.GetGroupName (groupID), CAdmin.Priveliges.GetGroupName (CAdmin.Priveliges.GetBaseGroup (groupID)))
		line.Group = groupID
		line:SetIcon (CAdmin.Priveliges.GetGroupIcon (groupID))
	end
end

function PANEL:SetArgumentValue (groupList)
	local selectedGroups = {}
	for _, groupID in pairs (groupList) do
		selectedGroups [groupID] = true
	end
	for _, line in pairs (self.GroupList:GetLines ()) do
		if selectedGroups [line.Group] then
			self.GroupList:SelectItem (line)
		end
	end
end

CAdmin.GUI.Register ("CAdmin.GroupCompleter", PANEL, "CArgumentCompleter")