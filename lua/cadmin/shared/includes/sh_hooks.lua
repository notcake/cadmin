CAdmin.Hooks = CAdmin.Hooks or {}
local Hooks = CAdmin.Hooks
Hooks.Hooks = {}
Hooks.HookCounts = {}
Hooks.QueuedCalls = {}
Hooks.QueuedBusyCalls = {}

local Whitelist = {}
local SharedWhitelist = {
	"AcceptStream",				-- This hook is actually shared, despite what the wiki says.
	"CanPlayerEnterVehicle",
	"CompletedIncomingStream",
	"ContextScreenClick",
	"CreateTeams",
	"DoPlayerDeath",
	"EntityKeyValue",
	"EntityRemoved",
	"FinishMove",
	"GetGameDescription",
	"GravGunPunt",
	"InitPostEntity",
	"Initialize",
	"KeyPress",
	"KeyRelease",
	"Move",
	"OnEntityCreated",
	"OnPlayerHitGround",
	"PhysgunDrop",
	"PhysgunPickup",
	"PlayerAuthed",
	"PlayerConnect",
	"PlayerEnteredVehicle",
	"PlayerFootstep",
	"PlayerShouldTakeDamage",
	"PlayerStepSoundTime",
	"PlayerTraceAttack",
	"PropBreak",
	"Restored",
	"Saved",
	"SetPlayerSpeed",
	"SetupMove",
	"ShouldCollide",
	"ShowTeam",
	"ShutDown",
	"Think",
	"Tick",
	"UpdateAnimation",

	-- Fretta
	"TeamHasEnoughPlayers"
}

local ClientWhitelist = {
	"AddDeathNotice",
	"AddHint",
	"AddNotify",
	"AdjustMouseSensitivity",
	"CalcVehicleThirdPersonView",
	"CalcView",
	"CallScreenClickHook",
	"ChatText",
	"ChatTextChanged",
	"CreateMove",
	"DrawDeathNotice",
	"FinishChat",
	"ForceDermaSkin",
	"GUIMouseDoublePressed",
	"GUIMousePressed",
	"GUIMouseReleased",
	"GetMotionBlurValues",
	"GetTeamColor",
	"GetTeamNumColor",
	"GetTeamScoreInfo",
	"GetVehicles",
	"HUDAmmoPickedUp",
	"HUDDrawPickupHistory",
	"HUDDrawScoreBoard",
	"HUDDrawTargetID",
	"HUDItemPickedUp",
	"HUDPaint",
	"HUDPaintBackground",
	"HUDShouldDraw",
	"HUDWeaponPickedUp",
	"OnChatTab",
	"OnContextMenuOpen",
	"OnContextMenuClose",
	"OnPlayerChat",
	"OnSpawnMenuOpen",
	"OnSpawnMenuClose",
	"PlayerBindPress",
	"PlayerEndVoice",
	"PlayerStartVoice",
	"PopulateToolMenu",
	"PostDrawSkybox",
	"PostDrawOpaqueRenderables",
	"PostDrawTranslucentRenderables",
	"PostProcessPermitted",
	"PostReloadToolsMenu",
	"PostRenderVGUI",
	"PreDrawSkybox",
	"PreDrawOpaqueRenderables",
	"PreDrawTranslucentRenderables",
	"PreReloadToolsMenu",
	"RenderScene",
	"RenderScreenspaceEffects",
	"ScoreboardHide",
	"ScoreboardShow",
	"ShouldDrawLocalPlayer",
	"StartChat",
	"SuppressHint",

	-- Sandbox
	"GetSENTMenu",
	"GetSWEPMenu",
	"PopulateSTOOLMenu",
	"SpawnMenuEnabled",

	-- Fretta
	"DrawPlayerRing",
	"ShowGamemodeChooser",
	"ShowMapChooser",
	"ShowClassChooser",
	"ShowSplash",
	"PaintSplashScreen"
}

local ServerWhitelist = {
	"CanExitVehicle",
	"CanPlayerSuicide",
	"CanPlayerUnfreeze",
	"CreateEntityRagdoll",
	"EntityTakeDamage",
	"GravGunOnDropped",
	"GravGunOnPickedUp",
	"GravGunPickupAllowed",
	"GetFallDamage",
	"IsSpawnpointSuitable",
	"OnDamagedByExplosion",
	"OnNPCKilled",
	"OnPhysgunFreeze",
	"OnPhysgunReload",
	"OnPlayerChangedTeam",
	"PlayerCanHearPlayersVoice",
	"PlayerCanJoinTeam",
	"PlayerCanPickupWeapon",
	"PlayerCanSeePlayersChat",
	"PlayerDeath",
	"PlayerHurt",
	"PlayerSilentDeath",
	"PlayerDeathSound",
	"PlayerDeathThink",
	"PlayerDisconnected",
	"PlayerInitialSpawn",
	"PlayerJoinTeam",
	"PlayerLeaveVehicle",
	"PlayerLoadout",
	"PlayerNoClip",
	"PlayerRequestTeam",
	"PlayerSay",
	"PlayerSelectSpawn",
	"PlayerSelectTeamSpawn",
	"PlayerSetModel",
	"PlayerSpawn",
	"PlayerSpawnAsSpectator",
	"PlayerSpray",
	"PlayerSwitchFlashlight",
	"PlayerUse",
	"ScaleNPCDamage",
	"ScalePlayerDamage",
	"SetPlayerAnimation",
	"SetupPlayerVisibility",
	"ShowHelp",
	"ShowSpare1",
	"ShowSpare2",
	"WeaponEquip",

	-- Sandbox
	"CanTool",
	"PlayerGiveSWEP",
	"PlayerSpawnObject",
	"PlayerSpawnProp",
	"PlayerSpawnSENT",
	"PlayerSpawnSWEP",
	"PlayerSpawnNPC",
	"PlayerSpawnVehicle",
	"PlayerSpawnEffect",
	"PlayerSpawnRagdoll",
	"PlayerSpawnedProp",
	"PlayerSpawnedSENT",
	"PlayerSpawnedNPC",
	"PlayerSpawnedVehicle",
	"PlayerSpawnedEffect",
	"PlayerSpawnedRagdoll",

	-- Fretta
	"AutoTeam",
	"PlayerRequestClass",
	"PlayerJoinClass",
	"EndOfGame",
	"StartRoundBasedGame",
	"CanStartRound",
	"PreRoundStart",
	"SetInRound",
	"InRound",
	"OnRoundStart",
	"RoundTimerEnd",
	"RoundEnd",
	"RoundEndWithResult",
	"OnRoundEnd",
	"GetTeamAliveCounts",
	"CheckPlayerDeathRoundEnd",
	"CheckRoundEnd",
	"StartGamemodeVote",
	"FinishGamemodeVote",
	"GetWinningGamemode",
	"GetWinningMap",
	"GetWinningFraction",
	"IsValidGamemode",
	"VotePlayGamemode",
	"RecountVotes",
	"SetRoundResult",
	"SetRoundWinner"
}

for _, v in pairs (SharedWhitelist) do
	Whitelist [v] = true
end

if CLIENT then
	for _, v in pairs (ClientWhitelist) do
		Whitelist [v] = true
	end
end

if SERVER then
	for _, v in pairs (ServerWhitelist) do
		Whitelist [v] = true
	end
end

local function RunQueuedCalls ()
	for hookType, argumentsList in pairs (Hooks.QueuedCalls) do
		for _, arguments in pairs (argumentsList) do
			Hooks.Call (hookType, unpack (arguments))
		end
		Hooks.QueuedCalls [hookType] = nil
	end
	Hooks.Remove ("Think", "CAdmin.Hooks.RunQueuedCalls")
end

--[[
	Adds a hook with hook.Add if necessary.
	Otherwise just adds it to the list of internal hooks.
	Hooks are removed automatically.
]]
function Hooks.Add (hookType, name, func)
	if hookType == "Initialize" or hookType == "Uninitialize" then
		print ("WARNING: Hooks.Add: Tried to add an Initialize / Uninitialize hook.")
		print ("\t\tDid you mean CAdminInitialize / CAdminUninitalize?")
		CAdmin.Debug.PrintStackTrace ()
	end
	if hookType == "PluginLoaded" or hookType == "PluginUnloaded" then
		print ("WARNING: Hooks.Add: Tried to add a PluginLoaded / PluginUnloaded hook.")
		print ("\t\tDid you mean CAdminPluginLoaded / CAdminPluginUnloaded?")
		CAdmin.Debug.PrintStackTrace ()
	end
	Hooks.Hooks [hookType] = Hooks.Hooks [hookType] or {}
	if type (name) == "function" then
		func = name
		name = util.CRC (tostring (func))
		print ("WARNING: Hooks.Add called with an invalid name.")
		CAdmin.Debug.PrintStackTrace ()
	end
	if Hooks.Hooks [hookType] [name] then
		print ("WARNING: Hooks.Add: Hook " .. hookType .. ": " .. name .. " was overwritten.")
		CAdmin.Debug.PrintFunctionInfo (Hooks.Hooks [hookType] [name])
	else
		Hooks.HookCounts [hookType] = (Hooks.HookCounts [hookType] or 0) + 1
	end
	Hooks.Hooks [hookType] [name] = func
	if Whitelist [hookType] then
		hook.Add (hookType, name, func)
	end

	if CAdmin.Plugins and CAdmin.Plugins.GetRunningPlugin () then
		local hookPlugin = CAdmin.Plugins.GetRunningPlugin ()
		hookPlugin.Hooks [hookType] = hookPlugin.Hooks [hookType] or {}
		hookPlugin.Hooks [hookType] [name] = true
	end
end

function Hooks.AddToWhitelist (type)
	Whitelist [type] = true
end

local currentHookType = nil
local currentHookName = nil
local function OnHookFailure (errorMessage)
	ErrorNoHalt ("Failure in hook " .. (currentHookType or "<unknown>") .. ": " .. (currentHookName or "<unknown>") .. ": " .. errorMessage .. "\n")
end

--[[
	Calls an internal hook.
]]
function Hooks.Call (hookType, ...)
	if Hooks.Hooks [hookType] then
		CAdmin.Profiler.EnterFunction ("CAdmin.Hooks.Call", hookType)
		
		currentHookType = hookType
		for k, f in pairs (Hooks.Hooks [hookType]) do
			-- Do this for every hook in case another hook is called in one of them.
			currentHookType = hookType
			currentHookName = k
			CAdmin.Lua.TryCall (OnHookFailure, f, ...)
		end
		currentHookType = nil
		currentHookName = nil
		CAdmin.Profiler.ExitFunction ()
	end
	
	if hookType == "CAdminPostUninitialize" then
		CAdmin.Profiler.EnterFunction ("CAdmin.Hooks.Call (PostUninitialize)")
		for k, t in pairs (Hooks.Hooks) do
			for v, _ in pairs (t) do
				Hooks.Remove (k, v)
			end
		end
		Hooks.Hooks = {}
		CAdmin.Profiler.ExitFunction ()
	end
end

function Hooks.Exists (hookType, hookName)
	if Hooks.Hooks [hookType] then
		return Hooks.Hooks [hookType] [hookName] and true or false
	end
	return false
end

--[[
	Returns the complete table of internal hooks.
]]
function Hooks.GetHooks (hookType)
	if hookType then
		return Hooks.Hooks [hookType]
	end
	return Hooks.Hooks
end

--[[
	Queues a hook call until CAdmin.Busy is 0.
	Multiple identical calls with the same arguments are only called once.
]]
function Hooks.QueueBusyCall (hookType, ...)
	if CAdmin.Settings.GetSession ("CAdmin.Busy", 0) == 0 then
		return Hooks.Call (hookType, ...)
	end
	Hooks.QueuedBusyCalls [hookType] = Hooks.QueuedBusyCalls [hookType] or {}
	local callTable = Hooks.QueuedBusyCalls [hookType]
	local newArguments = {...}
	local newArgumentCount = #newArguments
	local alreadyPresent = true
	for _, arguments in pairs (callTable) do
		Msg (tostring (newArgumentCount) .. ":" .. tostring (#arguments) .. "\n")
		if newArgumentCount == #arguments then
			for i = 1, newArgumentCount do
				if newArguments [i] ~= arguments [i] then
					alreadyPresent = false
					break
				end
			end
		else
			alreadyPresent = false
		end
		if alreadyPresent then
			return
		end
	end
	if not alreadyPresent then
		callTable [#callTable + 1] = newArguments
	end
end

--[[
	Queues a hook call until the next think.
	Multiple identical calls with the same arguments are only called once.
]]
function Hooks.QueueCall (hookType, ...)
	Hooks.QueuedCalls [hookType] = Hooks.QueuedCalls [hookType] or {}
	local callTable = Hooks.QueuedCalls [hookType]
	local newArguments = {...}
	local newArgumentCount = #newArguments
	local alreadyPresent = not CAdmin.Util.IsTableEmpty (callTable)
	for _, arguments in pairs (callTable) do
		alreadyPresent = true
		if newArgumentCount == #arguments then
			for i = 1, newArgumentCount do
				if newArguments [i] ~= arguments [i] then
					alreadyPresent = false
					break
				end
			end
		else
			alreadyPresent = false
		end
		if alreadyPresent then
			return
		end
	end
	if not alreadyPresent then
		callTable [#callTable + 1] = newArguments
		if not Hooks.Exists ("Think", "CAdmin.Hooks.RunQueuedCalls") then
			Hooks.Add ("Think", "CAdmin.Hooks.RunQueuedCalls", RunQueuedCalls)
		end
	end
end

--[[
	Removes a hook.
]]
function Hooks.Remove (hookType, name)
	if not Hooks.Hooks [hookType] then
		return
	end
	if Hooks.Hooks [hookType] [name] then
		if Whitelist [hookType] then
			hook.Remove (hookType, name)
		end
		Hooks.Hooks [hookType] [name] = nil
		Hooks.HookCounts [hookType] = Hooks.HookCounts [hookType] - 1
	end
	if Hooks.HookCounts [hookType] == 0 then
		Hooks.Hooks [hookType] = nil
		Hooks.HookCounts [hookType] = nil
	end
end

function Hooks.RemoveFromWhitelist (hookType)
	Whitelist [hookType] = nil
end

Hooks.Add ("CAdminInitialize", "CAdmin.Hooks.Initialize", function ()
	Hooks.Add ("CAdminPluginLoaded", "CAdmin.Hooks.PluginLoaded", function (pluginList)
		for _, plugin in pairs (pluginList) do
			plugin.Hooks = {}
		end
	end)
	
	Hooks.Add ("CAdminPluginUnloaded", "CAdmin.Hooks.PluginUnloaded", function (pluginList)
		for _, plugin in pairs (pluginList) do
			for hookType, hookTable in pairs (plugin.Hooks) do
				for hookName, _ in pairs (hookTable) do
					Hooks.Remove (hookType, hookName)
				end
			end
			plugin.Hooks = nil
		end
	end)

	Hooks.Add ("CAdminPostInitialize", "CAdmin.Hooks.PostInitialize", function ()
		if #weapons.GetList () > 0 then
			Hooks.Call ("CAdminInitPostEntity")
		else
			Hooks.Add ("InitPostEntity", "CAdminInitPostEntity", function ()
				Hooks.Call ("CAdminInitPostEntity")
			end)
		end
	end)
	
	Hooks.Add ("CAdminExitBusy", "CAdmin.Hooks.RunQueuedCalls", function ()
		for hookType, argumentsList in pairs (Hooks.QueuedBusyCalls) do
			for _, arguments in pairs (argumentsList) do
				Hooks.Call (hookType, unpack (arguments))
			end
			Hooks.QueuedBusyCalls [hookType] = nil
		end
	end)
	
	--[[
		The following section supplies hooks for player deaths on the client.
	]]
	local function OnNPCDeath (victimName, attacker, inflictorName, attackerName)
		Hooks.Call ("CAdminNPCDeath", victimName, attacker, inflictorName, attackerName)
	end
	
	local function OnPlayerDeath (victim, attacker, inflictorName, attackerName)
		if victim == attacker then
			Hooks.Call ("CAdminPlayerSuicide", victim, inflictorName)
		end
		Hooks.Call ("CAdminPlayerDeath", victim, attacker, inflictorName, attackerName)
	end
	
	if CLIENT then
		-- Clientside death hooks
		CAdmin.Usermessages.AddInterceptHook ("PlayerKilledByPlayer", "CAdmin.Hooks.Death", function (hookType, umsg)
			local victim = umsg:ReadEntity ()
			local inflictorName = umsg:ReadString ()
			local attacker = umsg:ReadEntity ()
			
			OnPlayerDeath (victim, attacker, inflictorName, attacker:Name ())
		end)
		
		CAdmin.Usermessages.AddInterceptHook ("PlayerKilledSelf", "CAdmin.Hooks.Death", function (hookType, umsg)
			local victim = umsg:ReadEntity ()
			
			OnPlayerDeath (victim, victim)
		end)
		
		CAdmin.Usermessages.AddInterceptHook ("PlayerKilled", "CAdmin.Hooks.Death", function (hookType, umsg)
			local victim = umsg:ReadEntity ()
			local inflictorName = umsg:ReadString ()
			local attackerName = umsg:ReadString ()
			
			OnPlayerDeath (victim, nil, inflictorName, attackerName)
		end)
		
		CAdmin.Usermessages.AddInterceptHook ("PlayerKilledNPC", "CAdmin.Hooks.Death", function (hookType, umsg)
			local victimName = umsg:ReadString ()
			local inflictorName = umsg:ReadString ()
			local attacker = umsg:ReadEntity ()
			
			OnNPCDeath (victimName, attacker, inflictorName, attacker:Name ())
		end)
		
		CAdmin.Usermessages.AddInterceptHook ("NPCKilledNPC", "CAdmin.Hooks.Death", function (hookType, umsg)
			local victimName = umsg:ReadString ()
			local inflictorName = umsg:ReadString ()
			local attackerName = umsg:ReadString ()
			
			OnNPCDeath (victimName, nil, inflictorName, attackerName)
		end)
	end
end)

--[[
	Note: All CAdmin hooks are removed when CAdminPostUninitialize is called.
	      Hooks.Call handles this.
]]