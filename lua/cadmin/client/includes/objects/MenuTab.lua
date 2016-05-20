local OBJ = CAdmin.Objects.Register ("Menu Tab", "PropertySheet Tab")

OBJ.LAYOUT_CUSTOM = 1
OBJ.LAYOUT_LISTVIEW = 2

function OBJ:__init (propertySheet, name)
	self.Layout = nil
end

function OBJ:__uninit ()
end

function OBJ:CreateCommandList ()
	self.CommandList = self:Create ("CCommandList", self:GetContentPanel ())
	self:UpdateCommands ()
end

function OBJ:CreateListViewLayout (type)
	if self.Layout then
		return
	end
	self.Layout = self.LAYOUT_LISTVIEW
	self.IDColumn = 1
	self.ItemList = self:Create ("CListView", self:GetContentPanel ())
	self.ItemList.Tab = self
	function self.ItemList:OnSelectionChanged (selectedLines)
		self.Tab:UpdateCommands ()
	end

	self.ItemList:AddEventListener ("MouseUp",
		function (_, mouseCode)
			if mouseCode ~= MOUSE_RIGHT then return end
			self.CommandList:ShowCommandMenu ()
		end
	)

	self:CreateCommandList ()

	CAdmin.Hooks.Add ("CAdminCommandToggleStatesChanged", "CAdmin.Menu." .. self:GetName (), function ()
		self:UpdateCommands ()
	end)

	CAdmin.Hooks.Add ("CAdminLocalPlayerPriveligesChanged", "CAdmin.Menu." .. self:GetName (), function ()
		self:UpdateCommands ()
	end)

	CAdmin.Hooks.Add ("CAdminCommandsChanged", "CAdmin.Menu." .. self:GetName (), function ()
		self:UpdateCommands ()
	end)
end

function OBJ:GetCommandArgumentType ()
	return self.CommandArgumentType
end

function OBJ:PerformCommandListLayout ()
	if not self.CommandList then
		return
	end
	self.CommandList:PerformLayoutRight ()
end

function OBJ:PerformLayout (...)
	self:PerformListViewLayout (...)
end

function OBJ:PerformListViewLayout ()
	if self.Layout == self.LAYOUT_LISTVIEW then
		self:PerformCommandListLayout ()

		self.ItemList:SetPos (self.Padding, self.Padding)
		self.ItemList:SetSize (self:GetWide () - 3 * self.Padding - self.CommandList:GetWide (), self:GetTall () - 2 * self.Padding)
		self.ItemList:PerformLayout ()
	end
end

function OBJ:PopulateItems ()
	if not self.ItemList then
		return
	end

	self.ItemList:Clear ()
end

function OBJ:PrepareArgumentList ()
	if not self.ItemList then
		return {}
	end
	return {self.ItemList:GetSelectedObjects ()}
end

function OBJ:SetCommandArgumentType (type)
	self.CommandArgumentType = type
end

function OBJ:SetIDColumn (col)
	self.IDColumn = col
end

function OBJ:UpdateCommands ()
	if not self.CommandList then
		return
	end 
	self.CommandList:SetCommandArgumentsList (self:PrepareArgumentList ())
	self.CommandList:SetCommandArgumentType (self:GetCommandArgumentType ())
	self.CommandList:PopulateCommands ()
end

function OBJ:UpdateItems ()
	if not self.ItemList then
		return
	end
end