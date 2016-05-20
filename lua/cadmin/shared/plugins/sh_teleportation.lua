local PLUGIN = CAdmin.Plugins.Create ("Teleportation")
PLUGIN:SetAuthor ("!cake")
PLUGIN:SetDescription ("Provides commands for defying physics.")

function PLUGIN:Initialize ()
	local command = CAdmin.Commands.Create ("bring", "Teleportation", "Bring")
		:SetAllowConsole (false)
		:SetConsoleCommand ("bring")
		:SetLogString ("%Player% brought %target% to %self%.")
	command:AddArgument ("Player")
	command:SetLastArgumentDisallowSelf (true)
	command:SetExecute (function (ply, targply)
		local position = ply:GetAimVector ()
		position.z = 0
		position:Normalize ()
		position = position * 72
		position = position + ply:GetPos ()
		targply:SetPos (position)
	end)
	
	command = CAdmin.Commands.Create ("bring_view", "Teleportation", "Bring to View")
		:SetAllowConsole (false)
		:SetConsoleCommand ("bring_view")
		:SetLogString ("%Player% brought %target% to %player's% view.")
	command:AddArgument ("Player")
	command:SetLastArgumentDisallowSelf (true)
	command:SetExecute (function (ply, targply)
		targply:SetPos (ply:GetEyeTrace ().HitPos + ply:GetAimVector () * 50 + Vector (0, 0, 25))
	end)

	command = CAdmin.Commands.Create ("goto", "Teleportation", "Go To")
		:SetAllowConsole (false)
		:SetConsoleCommand ("goto")
		:SetLogString ("%Player% went to %target%.")
	command:AddArgument ("Player")
	command:SetLastArgumentDisallowMultiple (true)
	command:SetLastArgumentDisallowSelf (true)
	command:SetExecute (function (ply, targply)
		local position = targply:GetAimVector ()
		position.z = 0
		position:Normalize ()
		position = position * 72
		position = position + targply:GetPos ()
		ply:SetPos (position)
		ply:SetEyeAngles ((targply:GetPos () - position):Angle ())
	end)

	command = CAdmin.Commands.Create ("send", "Teleportation", "Send")
		:SetConsoleCommand ("send")
		:SetLogString ("%Player% sent %target% to %arg1%.")
	command:AddArgument ("Player")
	command:AddArgument ("Player")
	command:SetLastArgumentDisallowMultiple (true)
	command:SetCanExecute (function (ply, targply, destply)
		if not targply or not destply then
			return true
		end
		if targply == destply then
			return false
		end
		return true
	end)
	command:SetExecute (function (ply, targply, destply)
		local position = destply:GetAimVector ()
		position.z = 0
		position:Normalize ()
		position = position * 72
		position = position + destply:GetPos ()
		targply:SetPos (position)
	end)
end