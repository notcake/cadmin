local OBJ = CAdmin.Objects.Register ("PropertySheet Tab")

function OBJ:__init (propertySheet, name)
	self.PropertySheet = propertySheet
	self.Name = name

	self.Icon = ""

	self.Padding = 5
	self.TabPosition = 1
	self.Tooltip = ""

	self.ContentPanel = self:Create ("DPanel")
	local OldSetVisible = self.ContentPanel.SetVisible
	function self.ContentPanel.SetVisible (panel, vis)
		if vis ~= self:GetContentPanel ():IsVisible () then
			if vis then
				self:OnShow ()
			else
				self:OnHide ()
			end
		end
		OldSetVisible (panel, vis)
	end

	self.ChildPropertySheet = nil
end

function OBJ:__uninit ()
	self.PropertySheet = nil
	if self.ChildPropertySheet then
		self.ChildPropertySheet:Remove ()
		self.ChildPropertySheet = nil
	end
	if self.ContentPanel then
		self.ContentPanel:Remove ()
		self.ContentPanel = nil
	end
end

function OBJ:Create (panelType, parent, targetName)
	return CAdmin.GUI.Create (panelType, parent or self:GetContentPanel (), targetName)
end

function OBJ:CreateChildPropertySheet (folder)
	if self.ChildPropertySheet then
		return
	end
	self.ChildPropertySheet = self:Create ("CPropertySheet", self:GetContentPanel ())
	if folder then
		self.ChildPropertySheet:LoadFolder (folder)
		self.ChildPropertySheet:CreateTabs ()
	end
	self:SetBackgroundColor (Color (128, 128, 128, 255))
	self:LayoutChildPropertySheet ()
end

function OBJ:GetBackgroundColor ()
	return self.ContentPanel:GetBackgroundColor ()
end

function OBJ:GetChildPropertySheet ()
	return self.ChildPropertySheet
end

function OBJ:GetContentPanel ()
	return self.ContentPanel
end

function OBJ:GetIcon ()
	return self.Icon
end

function OBJ:GetName ()
	return self.Name
end

function OBJ:GetPadding ()
	return self.Padding
end

function OBJ:GetPropertySheet ()
	return self.PropertySheet
end

function OBJ:GetTabPosition ()
	return self.TabPosition
end

function OBJ:GetTall ()
	return self.ContentPanel:GetTall ()
end

function OBJ:GetTooltip ()
	return self.Tooltip
end

function OBJ:GetWide ()
	return self.ContentPanel:GetWide ()
end

function OBJ:Init ()
end

function OBJ:LayoutChildPropertySheet (...)
	if not self.ChildPropertySheet then
		return
	end
	self.ChildPropertySheet:SetPos (self:GetPadding (), self:GetPadding ())
	self.ChildPropertySheet:SetSize (self:GetWide () - 2 * self:GetPadding (), self:GetTall () - 2 * self:GetPadding ())
	self.ChildPropertySheet:PerformLayout (...)
end

function OBJ:OnHide ()
end

function OBJ:OnShow ()
end

function OBJ:PerformLayout ()
end

function OBJ:SetBackgroundColor (color, g, b, a)
	if g and b then
		color = Color (color, g, b, a)
	end
	self.ContentPanel:SetBackgroundColor (color)
end

function OBJ:SetIcon (icon)
	if self.Sheet then
		if icon then
			self.Sheet.Tab.Image:SetImage (icon)
			self.Sheet.Tab.Image:SetVisible (true)
		else
			self.Sheet.Tab.Image:SetVisible (false)
		end
	end
	self.Icon = icon
end

function OBJ:SetName (name)
	local t = self.PropertySheet:GetTab (self:GetName ())
	self.PropertySheet:GetTabs () [self:GetName ()] = nil
	self.Name = name
	self.PropertySheet:GetTabs () [self:GetName ()] = t
end

function OBJ:SetTabPosition (pos)
	self.TabPosition = pos
end

function OBJ:SetTooltip (text)
	if self.Sheet then
		self.Sheet.Tab:SetTooltip (text)
	end
	self.Tooltip = text
end
