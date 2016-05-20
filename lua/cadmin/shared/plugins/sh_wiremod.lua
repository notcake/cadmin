local PLUGIN = CAdmin.Plugins.Create ("Wiremod")
PLUGIN:SetAuthor ("!cake")
PLUGIN:SetDescription ("Provides Wiremod support.")

function PLUGIN:Initialize ()
	if CLIENT then
		local wire_screens = {
			gmod_wire_consolescreen = {"NeedRefresh", nil},
			gmod_wire_digitalscreen = {"NeedRefresh", nil},
			gmod_wire_egp = {"NeedsRender", nil},
			gmod_wire_gpu = {nil, nil},
			gmod_wire_graphics_tablet = {nil, true},
			gmod_wire_oscilloscope = {nil, nil},
			gmod_wire_panel = {nil, true},
			gmod_wire_textscreen = {"NeedRefresh", nil}
		}
		
		local command = CAdmin.Commands.Create ("wire_fix_screens", "Wiremod", "Fix Wire Screens")
			:SetConsoleCommand ("wire_fix_screens")
			:SetAuthenticationRequired (false)
			:SetLogString ("%Player% reinitialized broken wiremod screens.")
		command:SetExecute (function (ply, targply, reason)
			for className, t in pairs (wire_screens) do
				for _, entity in pairs (ents.FindByClass (className)) do
					if entity.GPU and not entity.GPU.RT then
						entity.GPU:Initialize (t [2])
					end
					
					if t [1] then
						entity [t [1]] = true
					end
				end
			end
		end)
	
		CAdmin.Lists.AddToKVList ("CAdmin.EntityFinders", "Expression 2", function (ent)
			return ent:GetClass () == "gmod_wire_expression2"
		end)
		
		local highSpeedDevices = {
			["gmod_wire_addressbus"] = true,
			["gmod_wire_cpu"] = true,
			["gmod_wire_data_store"] = true,
			["gmod_wire_dynamicmemory"] = true,
			["gmod_wire_ramcard_default024"] = true,
			["gmod_wire_ramcard_default32"] = true,
			["gmod_wire_ramcard_default64"] = true,
			["gmod_wire_ramcard_default128"] = true,
			["gmod_wire_ramcard_default1024"] = true,
			["gmod_wire_ramcard_defaultbase"] = true,
			["gmod_wire_ramcard_proxy024"] = true,
			["gmod_wire_ramcard_proxy32"] = true,
			["gmod_wire_ramcard_proxybase"] = true,
			["gmod_wire_stringbuf"] = true
		}
		
		CAdmin.Lists.AddToKVList ("CAdmin.EntityFinders", "High Speed Devices", function (ent)
			return highSpeedDevices [ent:GetClass ()] or false
		end)

		CAdmin.Lists.AddToKVList ("CAdmin.EntityFinders", "Holograms", function (ent)
			return ent:GetClass () == "gmod_wire_hologram"
		end)
		
		local usermessageHeavyDisplays = {
			["gmod_wire_consolescreen"] = true,
			["gmod_wire_digitalscreen"] = true,
			["gmod_wire_egp"] = true
		}
		
		CAdmin.Lists.AddToKVList ("CAdmin.EntityFinders", "Usermessage-Heavy Displays", function (ent)
			return usermessageHeavyDisplays [ent:GetClass ()] or false
		end)

		CAdmin.Lists.AddToKVList ("CAdmin.ExplosiveEntities", "gmod_wire_detcord")
		CAdmin.Lists.AddToKVList ("CAdmin.ExplosiveEntities", "gmod_wire_detonator")
		CAdmin.Lists.AddToKVList ("CAdmin.ExplosiveEntities", "gmod_wire_explosive")
		CAdmin.Lists.AddToKVList ("CAdmin.ExplosiveEntities", "gmod_wire_simple_explosive")

		CAdmin.Lists.AddToKVList ("CAdmin.IgnitingEntities", "gmod_wire_field_device")
		CAdmin.Lists.AddToKVList ("CAdmin.IgnitingEntities", "gmod_wire_igniter")

		CAdmin.Lists.AddToKVList ("CAdmin.PropSpawningEntities", "gmod_adv_dupe_paster")
		CAdmin.Lists.AddToKVList ("CAdmin.PropSpawningEntities", "gmod_wire_spawner")

		CAdmin.Lists.AddToKVList ("CAdmin.TurretEntities", "gmod_wire_turret")

		CAdmin.Lists.AddToKVList ("CAdmin.MingeDevices", "gmod_wire_expression2")
		CAdmin.Lists.AddToKVList ("CAdmin.MingeDevices", "gmod_wire_hologram")
	end
	
	local blockedPlayers = nil
	local wire_holograms_block_client = CAdmin.Console.GetCommandFunction ("wire_holograms_block_client")
	local wire_holograms_unblock_client = CAdmin.Console.GetCommandFunction ("wire_holograms_unblock_client")
	if wire_holograms_block_client then
		local upvalueCount = debug.getinfo (wire_holograms_block_client).nups
		for i = 1, upvalueCount do
			local name, value = debug.getupvalue (wire_holograms_block_client, i)
			if name == "blocked" then
				blockedPlayers = value
				break
			end
		end
	end
	
	if blockedPlayers then
		if CLIENT then
			local command = CAdmin.Commands.Create ("block_holograms_cl", "Wiremod", "Hide Holograms", true)
			command:SetAuthenticationRequired (false)
			command:SetRunLocation (CAdmin.Commands.RUN_LOCAL)
			command:SetConsoleCommand ("block_holograms_cl")
			command:SetLogString ("%Player% disabled hologram display for %target% clientside.")
			command:SetReverseDisplayName ("Show Holograms")
			command:SetReverseConsoleCommand ("unblock_holograms_cl")
			command:SetReverseLogString ("%Player% enabled hologram display for %target% clientside.")
			command:AddArgument ("Player")
			command:SetExecute (function (ply, targply, hide)
				CAdmin.Console.RunCommand ("wire_holograms_" .. (hide and "" or "un") .. "block_client", targply:Name ())
			end)
			command:SetGetToggleState (function (ply)
				return blockedPlayers [ply:UserID ()] or false
			end)
		end
		
		command = CAdmin.Commands.Create ("block_holograms_sv", "Wiremod", "Block Holograms", true)
		command:SetConsoleCommand ("block_holograms")
		command:SetLogString ("%Player% disabled hologram use for %target%.")
		command:SetReverseDisplayName ("Unblock Holograms")
		command:SetReverseConsoleCommand ("unblock_holograms")
		command:SetReverseLogString ("%Player% enabled hologram use for %target%.")
		command:AddArgument ("Player")
		command:SetExecute (function (ply, targply, block)
			CAdmin.Console.RunCommand ("wire_holograms_" .. (block and "" or "un") .. "block", targply:Name ())
		end)
		command:SetGetToggleState (function (ply)
			return blockedPlayers [ply:UserID ()] or false
		end)
		
		command = CAdmin.Commands.Create ("remove_holograms", "Wiremod", "Remove All Holograms")
		command:SetConsoleCommand ("remove_holograms")
		command:SetLogString ("%Player% removed all holograms.")
		command:SetExecute (function (ply, targply)
			CAdmin.Console.RunCommand ("wire_holograms_remove_all")
		end)
	end
end