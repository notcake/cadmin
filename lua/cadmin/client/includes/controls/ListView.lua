local PANEL = {}

function PANEL:Init ()
	self.ObjectConverter = converter
	self.SelectedObjects = {}
	self.SelectedOutdated = true

	self:SetHeaderHeight (19)
	self:SetDataHeight (24)
	
	self.SelectionController:AddEventListener ("SelectionChanged",
		function ()
			self.SelectedOutdated = true
			self:OnSelectionChanged ()
		end
	)
end

function PANEL:GetSelectedObjects ()
	if not self.SelectedOutdated then
		return self.SelectedObjects
	end
	self.SelectedOutdated = false
	if #self.SelectionController:GetSelectedItems () == 0 then
		self.SelectedObjects = nil
		return nil
	end
	local selectedObjects = {}
	-- GetSelected returns a newly created table when called, so we can modify it.
	for line in self.SelectionController:GetSelectionEnumerator () do
		if self.ObjectConverter then
			local selectedObject = nil
			if type (self.ObjectConverter) == "function" then
				selectedObject = self.ObjectConverter (line)
			else
				selectedObject = line [self.ObjectConverter] or line:GetText (self.ObjectConverter)
			end
			selectedObject = selectedObject or line
			if selectedObject then
				selectedObjects [#selectedObjects + 1] = selectedObject
			end
		end
	end
	self.SelectedObjects = selectedObjects
	return selectedObjects
end

function PANEL:GetObjectConverter ()
	return self.ObjectConverter
end

function PANEL:OnSelectionChanged ()
end

function PANEL:SetObjectConverter (converter)
	self.ObjectConverter = converter
end

CAdmin.GUI.Register ("CListView", PANEL, "GListView")