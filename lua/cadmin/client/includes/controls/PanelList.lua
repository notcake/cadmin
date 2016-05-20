local PANEL = {}

function PANEL:Init ()
	self.NeedsReindexing = false
end

function PANEL:ReindexItems ()
	local itemList = {}
	for k, v in pairs (self.Items) do
		itemList [#itemList + 1] = v
	end
	self.Items = itemList
	itemList = nil
end

function PANEL:RemoveItem (itemPanel, doNotRemove)
	for k, panel in pairs (self.Items) do
		if panel == itemPanel then
			self.Items [k] = nil
			if not doNotRemove then
				itemPanel:Remove ()
			end
			
			self:InvalidateLayout ()
			self.NeedsReindexing = true
		end
	end
end

function PANEL:SortByMember (key, descending)
	if self.NeedsReindexing then
		self:ReindexItems ()
	end

	descending = descending or true
	table.sort (self.Items, function (a, b)
		if descending then
			local ta = a
			
			a = b
			b = ta
			
			ta = nil
		end
		
		if a [key] == nil or b [key] == nil then
			return false
		end
		return a [key] > b [key]
	end)
end

CAdmin.GUI.Register ("CPanelList", PANEL, "DPanelList")