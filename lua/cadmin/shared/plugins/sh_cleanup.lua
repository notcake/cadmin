local PLUGIN = CAdmin.Plugins.Create ("Cleanup")
PLUGIN:SetAuthor ("!cake")
PLUGIN:SetDescription ("Server Cleanup.")

function PLUGIN:Initialize ()
	local command = CAdmin.Commands.Create ("cleanup", "Sandbox", "Cleanup")
		:SetConsoleCommand ("cleanup")
		:SetLogString ("%Player% cleaned up the map.")
	command:AddArgument ("Time", "delay", "60")
		:SetPromptText ("Select countdown time until cleanup:")
	command:SetExecute (function (ply, delay)
		CAdmin.Timers.CreateCountdown ("Map Cleanup", delay, game.CleanUpMap)
	end)
	
	command = CAdmin.Commands.Create ("cleanup_decals", "Sandbox", "Cleanup Decals")
		:SetConsoleCommand ("cleanup_decals")
		:SetLogString ("%Player% removed all decals.")
	command:SetExecute (function (ply)
		CAdmin.RPC.FireEvent ("CAdminDoDecalCleanup")
	end)

	command = CAdmin.Commands.CreateFallback ("cleanup_decals", "Cleanup Decals (Clientside)")
		:SetLogString ("%Player% cleaned up decals locally.")
	command:SetCanExecute (function (ply)
		return true
	end)
	command:SetExecute (function (ply)
		PLUGIN:CleanupDecals ()
	end)

	command = CAdmin.Commands.Create ("cleanup_effects", "Sandbox", "Cleanup Effects")
		:SetConsoleCommand ("cleanup_effects")
		:SetLogString ("%Player% cleaned up effects.")
	command:SetExecute (function (ply)
		CAdmin.RPC.FireEvent ("CAdminDoEffectCleanup")
	end)

	if CLIENT then
		command = CAdmin.Commands.CreateFallback ("cleanup_effects", "Cleanup Effects (Clientside)")
			:SetLogString ("%Player% cleaned up effects locally.")
		command:SetCanExecute (function (ply)
			return true
		end)
		command:SetExecute (function (ply)
			PLUGIN:CleanupEffects ()
		end)

		command = CAdmin.Commands.Create ("cleanup_lamps", "Sandbox", "Cleanup Lamps (Clientside)")
			:SetConsoleCommand ("cleanup_lamps")
			:SetRequiresClient ()
			:SetLogString ("%Player% disabled lamps locally.")
		command:SetCanExecute (function (ply)
			if CAdmin.Players.IsConsole (ply) then
				return false
			end
			return true
		end)
		command:SetExecute (function (ply)
			PLUGIN:CleanupLamps ()
		end)
	end
	
	command = CAdmin.Commands.Create ("cleanup_ragdolls", "Sandbox", "Cleanup Ragdolls")
		:SetConsoleCommand ("cleanup_ragdolls")
		:SetLogString ("%Player% removed all ragdolls.")
	command:SetExecute (function (ply)
		CAdmin.RPC.FireEvent ("CAdminDoRagdollCleanup")
	end)

	command = CAdmin.Commands.CreateFallback ("cleanup_ragdolls", "Cleanup Ragdolls (Clientside)")
		:SetLogString ("%Player% cleaned up ragdolls locally.")
	command:SetCanExecute (function (ply)
		return true
	end)
	command:SetExecute (function (ply)
		PLUGIN:CleanupRagdolls ()
	end)

	command = CAdmin.Commands.Create ("destroy_ent", "Sandbox", "Destroy Entity")
		:SetConsoleCommand ("destroy_ent")
		:SetLogString ("%Player% destroyed %target%.")
	command:AddArgument ("Entity", "Entity")
		:SetPromptText ("Select the entity to destroy:")
	command:SetExecute (function (ply, ent)
		ent:Remove ()
	end)

	if CLIENT then
		CAdmin.Hooks.Add ("CAdminDoDecalCleanup", "CAdmin.Cleanup.HandleDecalCleanup", function ()
			PLUGIN:CleanupDecals ()
		end)
		CAdmin.Hooks.Add ("CAdminDoEffectCleanup", "CAdmin.Cleanup.HandleEffectCleanup", function ()
			PLUGIN:CleanupEffects ()
		end)
		CAdmin.Hooks.Add ("CAdminDoRagdollCleanup", "CAdmin.Cleanup.HandleRagdollCleanup", function ()
			PLUGIN:CleanupRagdolls ()
		end)
	end
end

function PLUGIN:CleanupDecals ()
	RunConsoleCommand ("r_cleardecals")
end

function PLUGIN:CleanupEffects ()
	local toremove = ents.FindByClass ("entityflame")
	for _, v in pairs (toremove) do
		v:Remove ()
	end
	toremove = ents.FindByClass ("gmod_ghost")
	for _, v in pairs (toremove) do
		v:Remove ()
	end
	toremove = ents.FindByClass ("gmod_wire_hologram")
	for _, v in pairs (toremove) do
		v:Remove ()
	end
end

function PLUGIN:CleanupLamps ()
	local todisable = ents.FindByClass ("gmod_lamp")
	for _, v in pairs (todisable) do
		v:SetOn (false)
	end
end

if CLIENT then
	function PLUGIN:CleanupRagdolls ()
		local toremove = ents.FindByClass ("class C_ClientRagdoll")
		for _, v in pairs (toremove) do
			v:Remove ()
		end
	end
end