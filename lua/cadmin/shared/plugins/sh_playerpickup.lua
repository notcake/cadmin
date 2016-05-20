local PLUGIN = CAdmin.Plugins.Create ("Player Pickup")
PLUGIN:SetAuthor ("!cake")
PLUGIN:SetDescription ("Enables players to pick up other players with the physgun.")

function PLUGIN:Initialize ()
	CAdmin.Hooks.Add ("PhysgunPickup", "CAdmin.PlayerPickup.PhysgunPickup", function (ply, ent)
		if ent:GetClass () == "player" then
			if CAdmin.Priveliges.IsPlayerAuthorized (ply, "playerpickup", ent) then
				return true
			end
		end
	end)
	
	if SERVER then
		CAdmin.Hooks.Add ("OnPhysgunReload", "CAdmin.PlayerPickup.NoclipPlayers", function (weapon, ply)
			local ent = ply:GetEyeTrace ().Entity
			if ent:GetClass () == "player" and ent:GetMoveType () == MOVETYPE_NOCLIP then
				if CAdmin.Priveliges.IsPlayerAuthorized (ply, "playerpickup", ent) then
					ent:SetMoveType (MOVETYPE_WALK)
				end
			end
		end)
		
		CAdmin.Hooks.Add ("OnPhysgunFreeze", "CAdmin.PlayerPickup.NoclipPlayers", function (weapon, physobj, ent, ply)
			if ent:GetClass () == "player" and ent:GetMoveType () ~= MOVETYPE_NOCLIP then
				if CAdmin.Priveliges.IsPlayerAuthorized (ply, "playerpickup", ent) then
					ent:SetMoveType (MOVETYPE_NOCLIP)
				end
			end
		end)
	end
end