local PANEL = {}

function PANEL:Init ()
	self.Icon = nil
end

function PANEL:Uninit ()
	if self.Icon then
		self.Icon:Remove ()
		self.Icon = nil
	end
end

function PANEL:DataLayout (ListView)
	self:ApplySchemeSettings ()
	local height = self:GetTall ()
	local x = 0
	for k, Column in pairs (self.Columns) do
		local w = ListView:ColumnWidth (k)
		if k == 1 and self.Icon then
			local spacing = (self:GetTall () - self.Icon:GetTall ()) * 0.5
			x = x + spacing
			self.Icon:SetPos (x, spacing)
			x = x + self.Icon:GetWide ()
			w = w - self.Icon:GetWide () - spacing
		end
		Column:SetPos (x, 0)
		Column:SetSize (w, height)
		x = x + w
	end
end

function PANEL:GetIcon ()
	if self.Icon then
		return self.Icon:GetImage ()
	end
	return nil
end

function PANEL:RemoveIcon ()
	if self.Icon then
		self.Icon:Remove ()
		self.Icon = nil
	end
end

function PANEL:SetIcon (icon)
	if icon then
		if not self.Icon then
			self.Icon = vgui.Create ("DImage", self)
			self.Icon:SetImage (icon)
			self.Icon:SizeToContents ()
		end
	else
		if self.Icon then
			self.Icon:Remove ()
			self.Icon = nil
		end
	end
end

CAdmin.GUI.Register ("CListView_Line", PANEL, "DListView_Line")