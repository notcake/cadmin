local PLUGIN = CAdmin.Plugins.Create ("Fallback Commands")
PLUGIN:SetAuthor ("!cake")
PLUGIN:SetDescription ("Provides basic fallback commands.")

function PLUGIN:Initialize ()
	local command = CAdmin.Commands.CreateFallback ("goto", "Teleportation", "Go To")
	command:SetCanExecute(function (ply, targply)
		return GetConVar ("sv_cheats"):GetBool ()
	end)
	command:SetExecute (function (ply, targply)
		local position = targply:GetAimVector ()
		position.z = 0
		position:Normalize ()
		position = position * 72
		position = position + targply:GetPos ()
		RunConsoleCommand ("setpos", tostring (position.x), tostring (position.y), tostring (position.z))
		ply:SetEyeAngles ((targply:GetPos () - position):Angle ())
	end)
	
	command = CAdmin.Commands.CreateFallback ("kick", "Disconnect")
	command:SetLogString ("%Player% disconnected.")
	command:SetCanExecute (function (ply, targply)
		if ply == targply then
			return true
		end
		return false
	end)
	command:SetExecute (function (ply, targply, reason)
		RunConsoleCommand ("disconnect")
	end)

	command = CAdmin.Commands.CreateFallback ("mute_voice", "Mute Voice")
	command:SetLogString ("Muted %target% locally.")
	command:SetReverseLogString ("Unmuted %target% locally.")
	command:SetCanExecute (function (ply, targply, mute)
		if not targply then
			return true
		end
		if mute then
			if not targply:IsMuted () then
				return true
			end
		else
			if targply:IsMuted () then
				return true
			end
		end
		return false
	end)
	command:SetExecute (function (ply, targply, mute)
		targply:SetMuted ()
	end)
	command:SetGetToggleState (function (targply)
		return targply:IsMuted ()
	end)

	command = CAdmin.Commands.CreateFallback ("noclip", "Noclip")
	command:SetLogString ("%Player% entered noclip.")
	command:SetReverseLogString ("%Player% exited noclip.")
	command:SetCanExecute (function (ply, targply, noclip)
		if targply == LocalPlayer () then
			return targply:GetMoveType () == (noclip and MOVETYPE_WALK or MOVETYPE_NOCLIP)
		end
		return false
	end)
	command:SetExecute (function (ply, targply, noclip)
		RunConsoleCommand ("noclip")
		CAdmin.Timers.RunAfter (LocalPlayer ():Ping () * 0.002, function ()
			CAdmin.Hooks.Call ("CAdminCommandToggleStatesChanged")
		end)
	end)
	command:SetGetToggleState (function (targply)
		return targply:GetMoveType () == MOVETYPE_NOCLIP
	end)

	command = CAdmin.Commands.CreateFallback ("runcommand_cl", "Run Console Command")
	command:SetCanExecute (function (ply, targply)
		if ply == targply then
			return true
		end
		return false
	end)
	command:SetExecute (function (ply, targply, consoleCommand)
		targply:ConCommand (consoleCommand)
	end)

	command = CAdmin.Commands.CreateFallback ("runlua_cl", "Run Lua")
	command:SetCanExecute (function (ply, targply)
		if ply == targply then
			return true
		end
		return false
	end)
	command:SetExecute (function (ply, targply, code)
		RunString (code)
	end)
	
	command = CAdmin.Commands.CreateFallback ("slay", "Suicide")
	command:SetLogString ("%Player% committed suicide.")
	command:SetCanExecute (function (ply, targply)
		if ply == targply then
			return true
		end
		return false
	end)
	command:SetExecute (function (ply, targply)
		RunConsoleCommand ("explode")
	end)
end