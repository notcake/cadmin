local PANEL = {}

function PANEL:Init ()
	-- Works around DermaDetectMenuFocus in addons/derma/lua/derma/derma_menus.lua.
	self.ClassName = "DMenu"
end

local function OptionPanelClick (optionPanel)
	if optionPanel.CallbackFunction then
		optionPanel.CallbackFunction (optionPanel.ItemID, optionPanel.Data)
	end
end

function PANEL:AddOption (displayText, callbackFunction, itemID, data)
	local optionPanel = self:Create ("DMenuOption")
	optionPanel:SetText (displayText or "")
	
	optionPanel.ItemID = itemID or displayText
	optionPanel.Data = data
	optionPanel.CallbackFunction = callbackFunction
	optionPanel.DoClick = OptionPanelClick
	
	self:AddPanel (optionPanel)
	return true
end

function PANEL:AddSubMenu (displayText, callbackFunction, itemID, data)
	local subMenu = CAdmin.GUI.CreateMenu (self)
	subMenu:SetVisible (false)
	
	local optionPanel = self:Create ("DMenuOption")
	optionPanel:SetSubMenu (subMenu)
	optionPanel:SetText (displayText or "")
	
	optionPanel.ItemID = itemID or displayText
	optionPanel.Data = data
	optionPanel.CallbackFunction = callbackFunction
	optionPanel.DoClick = OptionPanelClick
	
	self:AddPanel (optionPanel)
	
	return subMenu
end

function PANEL:GetItemCount ()
	return #self:GetItems ()
end

CAdmin.GUI.Register ("CMenu", PANEL, "DMenu")