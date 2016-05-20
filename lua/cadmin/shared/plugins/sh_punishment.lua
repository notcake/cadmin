local PLUGIN = CAdmin.Plugins.Create ("Punishment")
PLUGIN:SetAuthor ("!cake")
PLUGIN:SetDescription ("Provides commands for punishing players.")

function PLUGIN:Initialize ()
	local command = CAdmin.Commands.Create ("blind", "Punishment", "Blind", true)
	command:SetConsoleCommand ("blind")
	command:SetLogString ("%Player% blinded %target%.")
	command:SetReverseDisplayName ("Unblind")
	command:SetReverseConsoleCommand ("unblind")
	command:SetReverseLogString ("%Player% unblinded %target%.")
	command:AddArgument ("Player")
	command:SetExecute (function (ply, targply, blind)
		CAdmin.Players.SetSessionData (targply, "Blinded", blind, true)
		if not blind then
			targply:ConCommand ("pp_mat_overlay 0")
		end
	end)
	command:SetGetToggleState (function (ply)
		return CAdmin.Players.GetSessionData (ply, "Blinded")
	end)

	command = CAdmin.Commands.Create ("freeze", "Punishment", "Freeze", true)
	command:SetConsoleCommand ("freeze")
	command:SetLogString ("%Player% froze %target%.")
	command:SetReverseDisplayName ("Unfreeze")
	command:SetReverseConsoleCommand ("unfreeze")
	command:SetReverseLogString ("%Player% unfroze %target%.")
	command:AddArgument ("Player")
	command:SetExecute (function (ply, targply, freeze)
		targply:Freeze (freeze)
		CAdmin.Players.SetSessionData (targply, "Frozen", freeze, true)
	end)
	command:SetGetToggleState (function (ply)
		return CAdmin.Players.GetSessionData (ply, "Frozen")
	end)

	command = CAdmin.Commands.Create ("ignite", "Punishment", "Ignite", true)
	command:SetConsoleCommand ("ignite")
	command:SetLogString ("%Player% ignited %target%.")
	command:SetReverseDisplayName ("Extinguish")
	command:SetReverseConsoleCommand ("unignite")
	command:SetReverseLogString ("%Player% extinguished %target%.")
	command:AddArgument ("Player")
	command:SetExecute (function (ply, targply, fire)
		if fire then
			-- 1 gigasecond should do it.
			targply:Ignite (1000000000)
		else
			targply:Extinguish ()
		end
		CAdmin.Players.SetSessionData (targply, "Burning", fire, true)
	end)
	command:SetGetToggleState (function (ply)
		if CLIENT then
			if CAdmin.IsServerRunning () then
				return CAdmin.Players.GetSessionData (ply, "Burning")
			end
		end
		local flameEntities = ents.FindByClass ("entityflame")
		for _, flame in pairs (flameEntities) do
			if flame:GetPos () == ply:GetPos () then
				return true
			end
		end
		return false
	end)

	command = CAdmin.Commands.Create ("jail", "Punishment", "Jail", true)
	command:SetConsoleCommand ("jail")
	command:SetLogString ("%Player% jailed %target%.")
	command:SetReverseDisplayName ("Unjail")
	command:SetReverseConsoleCommand ("unjail")
	command:SetReverseLogString ("%Player% unjailed %target%.")
	command:AddArgument ("Player")
	command:SetExecute (function (ply, targply, jail)
		CAdmin.Players.SetSessionData (ply, "Jailed", ragdoll, true)
	end)

	command = CAdmin.Commands.Create ("ragdoll", "Punishment", "Ragdoll", true)
	command:SetConsoleCommand ("ragdoll")
	command:SetLogString ("%Player% ragdolled %target%.")
	command:SetReverseDisplayName ("Unragdoll")
	command:SetReverseConsoleCommand ("unragdoll")
	command:SetReverseLogString ("%Player% unragdolled %target%.")
	command:AddArgument ("Player")
	command:SetExecute (function (ply, targply, ragdoll)
		CAdmin.Players.SetSessionData (ply, "Ragdolled", ragdoll, true)
	end)

	command = CAdmin.Commands.Create ("slay", "Punishment", "Slay")
	command:SetConsoleCommand ("slay")
	command:SetLogString ("%Player% slew %target%.")
	command:AddArgument ("Player")
	command:SetExecute (function (ply, targply)
		targply:Kill ()
	end)

	command = CAdmin.Commands.Create ("sslay", "Punishment", "Slay (Silent)")
	command:SetConsoleCommand ("sslay")
	command:SetLogString ("%Player% slew %target% silently.")
	command:AddArgument ("Player")
	command:SetExecute (function (ply, targply)
		targply:KillSilent ()
	end)

	command = CAdmin.Commands.Create ("strip", "Punishment", "Strip", true)
	command:SetConsoleCommand ("strip")
	command:SetLogString ("%Player% stripped %target%.")
	command:SetReverseDisplayName ("Unstrip")
	command:SetReverseConsoleCommand ("unstrip")
	command:SetReverseLogString ("%Player% returned weapon access to %target%.")
	command:AddArgument ("Player")
	command:SetExecute (function (ply, targply, strip)
		if strip then
			targply:StripWeapons ()
		else
			hook.Call ("PlayerLoadout", targply)
		end
		CAdmin.Players.SetSessionData (ply, "Stripped", strip, true)
	end)
	
	CAdmin.Timers.RunEveryTick ("CAdmin.Punishment.Blind", function ()
		for _, ply in ipairs (CAdmin.Players.GetPlayers ()) do
			if CAdmin.Players.GetSessionData (ply, "Blinded") then
				ply:ConCommand ("pp_mat_overlay 1")
				ply:ConCommand ("pp_mat_overlay_texture black_outline")
			end
		end
	end)
end