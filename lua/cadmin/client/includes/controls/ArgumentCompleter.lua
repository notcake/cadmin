local PANEL = {}

function PANEL:Init ()
	self.ArgumentInfo = nil
	self.ArgumentPrompt = nil

	self:SetWide (ScrW () * 0.25)
	self:SetTall (ScrH () * 0.25)
end

function PANEL:Uninit ()
	self.ArgumentPrompt = nil
end

function PANEL:DoLayout ()
end

function PANEL:GetArgumentInfo ()
	return self.ArgumentInfo
end

function PANEL:GetArgumentPrompt ()
	return self.ArgumentPrompt
end

function PANEL:GetArgumentValue ()
	return nil
end

function PANEL:GetTitle ()
	return self.ArgumentPrompt:GetDisplayName () .. ": " .. self.ArgumentPrompt:GetMissingArgument ():GetArgumentTypeName () .. " needed"
end

function PANEL:SetArgumentInfo (argumentInfo)
	self.ArgumentInfo = argumentInfo
end

function PANEL:SetArgumentPrompt (argumentPrompt)
	self.ArgumentPrompt = argumentPrompt
end

function PANEL:SetArgumentValue ()
end

CAdmin.GUI.Register ("CArgumentCompleter", PANEL, "DPanel")