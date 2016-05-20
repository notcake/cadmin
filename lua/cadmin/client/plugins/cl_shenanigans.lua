local PLUGIN = CAdmin.Plugins.Create ("Shenanigans")
PLUGIN:SetAuthor ("!cake")
PLUGIN:SetDescription ("Lua hijinks.")

function PLUGIN:Initialize ()
	self.OriginalName = nil
	self.PlayerName = nil
	
	local command = CAdmin.Commands.Create ("setname", "Shenanigans", "Set Name")
		:SetCommandType (CAdmin.COMMAND_CLIENT)
		:SetConsoleCommand ("setname")
		:SetLogString ("%Player% changed your name to %arg0%.")
	command:AddArgument ("String", "Name")
		:SetPromptText ("Enter your new name:")
	command:SetExecute (function (ply, name)
		PLUGIN.PlayerName = name
	end)

	CAdmin.Hooks.Add ("Think", "CAdmin.ChangeName", function ()
		if PLUGIN:ShouldChangeName () then
			RunConsoleCommand ("setinfo", "name", PLUGIN:GetPlayerName ())
		end
	end)
end

function PLUGIN:GetOriginalName ()
	if not self.OriginalName then
		self.OriginalName = LocalPlayer ():Name ()
	end
	return self.OriginalName
end

function PLUGIN:GetPlayerName ()
	if not self.PlayerName then
		self.PlayerName = LocalPlayer ():Name ()
	end
	return self.PlayerName
end

function PLUGIN:ShouldChangeName ()
	return self:GetPlayerName () ~= self:GetOriginalName ()
end