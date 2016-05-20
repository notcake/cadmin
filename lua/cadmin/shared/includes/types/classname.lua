local TYPE = CAdmin.Commands.RegisterType ("Classname")

local SharedClassnames = {
	"*",
	"_firesmoke",
	"beam",
	"crossbow_bolt",
	"entityflame",
	"env_citadel_energy_core",
	"env_fire",
	"env_smokestack",
	"env_sprite",
	"env_spritetrail",
	"env_steam",
	"func_breakable",
	"func_brush",
	"func_door",
	"func_door_rotating",
	"func_illusionary",
	"func_movelinear",
	"func_physbox",
	"func_physbox_multiplayer",
	"func_rotating",
	"func_smokevolume",
	"func_tanktrain",
	"func_tracktrain",
	"func_useable_ladder",
	"func_wall",
	"gmod_anchor",
	"hunter_flechette",
	"item_ammo_ar2_altfire",
	"npc_alyx",
	"npc_antlion",
	"npc_antlion_worker",
	"npc_antlionguard",
	"npc_barnacle",
	"npc_barney",
	"npc_breen",
	"npc_citizen",
	"npc_combine_s",
	"npc_cscanner",
	"npc_dog",
	"npc_eli",
	"npc_fastzombie",
	"npc_fastzombie_torso",
	"npc_gman",
	"npc_grenade_frag",
	"npc_headcrab",
	"npc_headcrab_fast",
	"npc_headcrab_poison",
	"npc_hunter",
	"npc_kleiner",
	"npc_magnusson",
	"npc_manhack",
	"npc_monk",
	"npc_mossman",
	"npc_poisonzombie",
	"npc_rollermine",
	"npc_tripmine",
	"npc_vortigaunt",
	"npc_zombie",
	"npc_zombie_torso",
	"npc_zombine",
	"physgun_beam",
	"player",
	"point_tesla",
	"prop_combine_ball",
	"prop_dynamic",
	"prop_dynamic_override",
	"prop_physics",
	"prop_ragdoll",
	"prop_vehicle_jeep",
	"prop_vehicle_prisoner_pod",
	"rpg_missile",
	"weapon_357",
	"weapon_ar2",
	"weapon_bugbait",
	"weapon_crossbow",
	"weapon_crowbar",
	"weapon_frag",
	"weapon_physcannon",
	"weapon_physgun",
	"weapon_pistol",
	"weapon_rpg",
	"weapon_shotgun",
	"weapon_striderbuster",
	"weapon_smg1",
	"worldspawn"
}
local ClientClassnames = {
	"class C_BaseEntity",
	"class C_ClientRagdoll",
	"class C_EnvProjectedTexture",
	"class C_EnvTonemapController",
	"class C_FogController",
	"class C_Func_Dust",
	"class C_FuncAreaPortalWindow",
	"class C_FuncOccluder",
	"class C_HL2MPRagdoll",
	"class C_LaserDot",
	"class C_LightGlow",
	"class C_ParticleSystem",
	"class C_PhysPropClientside",
	"class C_PlayerResource",
	"class C_RopeKeyframe",
	"class C_SpotlightEnd",
	"class C_Sun",
	"class C_WaterLODControl",
	"class CLuaEffect",
	"viewmodel"
}
local ServerClassnames = {
	"bodyque",
	"info_player_start",
	"network",
	"player_manager",
	"predicted_viewmodel",
	"scene_manager",
	"trigger_multiple",
	"trigger_once"
}

local Classnames = {
}

CAdmin.Hooks.Add ("CAdminInitPostEntity", "CAdmin.Types.Classname", function ()
	table.Empty (Classnames)
	for k, _ in pairs (scripted_ents.GetList ()) do
		Classnames [k] = true
	end
	for _, v in pairs (weapons.GetList ()) do
		Classnames [v.ClassName] = true
	end
	for _, v in pairs (SharedClassnames) do
		Classnames [v] = true
	end
	if CLIENT then
		for _, v in pairs (ClientClassnames) do
			Classnames [v] = true
		end
	end
	if SERVER then
		for _, v in pairs (ServerClassnames) do
			Classnames [v] = true
		end
	end
end)

TYPE:SetAutocomplete (function (className)
	className = className:lower ()
	if className == "*" then
		className = ""
	end
	local classes = {}
	for k, _ in pairs (Classnames) do
		if k:lower ():find (className, 1, true) then
			classes [#classes + 1] = k
		end
	end
	return classes
end)

TYPE:RegisterConverter ("String", function (ply, className)
	return className
end)