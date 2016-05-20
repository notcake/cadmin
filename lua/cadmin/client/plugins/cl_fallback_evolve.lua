local PLUGIN = CAdmin.Plugins.Create ("Evolve Fallback")
PLUGIN:SetAuthor ("!cake")
PLUGIN:SetDescription ("Provides Evolve fallback commands.")

local canEvolve = false

local EvolveAutocomplete = nil
local EvolveAutocompleteOverridden = false

function PLUGIN:Initialize ()
	if FindMetaTable ("Player").EV_IsAdmin then
		self:EvolveLoaded ()
	else
		CAdmin.Usermessages.AddInterceptHook ("EV_Init", "EvolveFallback", function ()
			self:EvolveLoaded ()
		end)
	end
	CAdmin.Usermessages.AddInterceptHook ("EV_Rank", "EvolveFallback", function (type, umsg)
		CAdmin.Fallbacks.ResetCallCount ("CAdmin.Priveliges.GetGroups")
		local groupID = umsg:ReadString ():lower ()
		CAdmin.Hooks.QueueCall ("CAdminGroupAdded", groupID)
		CAdmin.Hooks.QueueCall ("CAdminGroupDataChanged", groupID)
	end)
	CAdmin.Usermessages.AddInterceptHook ("EV_RemoveRank", "EvolveFallback", function (type, umsg)
		CAdmin.Fallbacks.ResetCallCount ("CAdmin.Priveliges.GetGroups")
		CAdmin.Hooks.QueueCall ("CAdminGroupRemoved", umsg:ReadString ():lower ())
	end)
	CAdmin.Usermessages.AddInterceptHook ("EV_RenameRank", "EvolveFallback", function (type, umsg)
		CAdmin.Fallbacks.ResetCallCount ("CAdmin.Priveliges.GetGroups")
		local groupID = umsg:ReadString ():lower ()
		CAdmin.Hooks.QueueCall ("CAdminGroupDataChanged", groupID)
	end)
	local function RankPriveligesChanged (type, umsg)
		CAdmin.Fallbacks.ResetCallCount ("CAdmin.Priveliges.GetGroups")
		CAdmin.Hooks.QueueCall ("CAdminGroupPriveligesChanged", umsg:ReadString ():lower ())
	end
	CAdmin.Usermessages.AddInterceptHook ("EV_RankPrivilege", "EvolveFallback", RankPriveligesChanged)
	CAdmin.Usermessages.AddInterceptHook ("EV_RankPrivileges", "EvolveFallback", RankPriveligesChanged)
	CAdmin.Usermessages.AddInterceptHook ("EV_RankPrivilegeAll", "EvolveFallback", RankPriveligesChanged)

	local function RegisterCommand (name, description, privelige, consoleCommand)
		consoleCommand = consoleCommand or privelige
	
		local command = CAdmin.Commands.CreateFallback (name, description)
		:SetFallbackType (CAdmin.FALLBACK_ADMIN)
		:SetSuppressLog (true)
		:SetCanExecute (function (ply, targply)
			if not canEvolve then
				return false
			end
			return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), privelige)
		end)
		:SetExecute (function (ply, targply)
			RunConsoleCommand ("ev", consoleCommand, targply:Name ())
			CAdmin.Timers.RunAfter (LocalPlayer ():Ping () * 0.002, function ()
				CAdmin.Hooks.Call ("CAdminCommandToggleStatesChanged")
			end)
		end)
		return command
	end
	
	local function RegisterToggleCommand (name, description, privelige, consoleCommand)
		consoleCommand = consoleCommand or privelige
	
		local command = CAdmin.Commands.CreateFallback (name, description)
		:SetFallbackType (CAdmin.FALLBACK_ADMIN)
		:SetSuppressLog (true)
		:SetCanExecute (function (ply, targply, toggle)
			if not canEvolve then
				return false
			end
			return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), privelige)
		end)
		:SetExecute (function (ply, targply, toggle)
			RunConsoleCommand ("ev", consoleCommand, targply:Name (), toggle and "1" or "0")
			CAdmin.Timers.RunAfter (LocalPlayer ():Ping () * 0.002, function ()
				CAdmin.Hooks.Call ("CAdminCommandToggleStatesChanged")
			end)
		end)
		return command
	end
	
	RegisterCommand ("bring", "Evolve Bring", "teleport", "bring")
	RegisterCommand ("goto", "Evolve Go To", "goto")
	RegisterToggleCommand ("blind", "Evolve Blind", "blind")
	RegisterToggleCommand ("freeze", "Evolve Freeze", "freeze")
	RegisterToggleCommand ("god", "Evolve God", "god")
	RegisterToggleCommand ("ignite", "Evolve Ignite", "ignite")
	RegisterToggleCommand ("jail", "Evolve Jail", "jail")
	RegisterToggleCommand ("noclip", "Evolve Noclip", "noclip")
	RegisterToggleCommand ("ragdoll", "Evolve Ragdoll", "ragdoll")
	RegisterToggleCommand ("gag", "Evolve Gag", "gag")
	RegisterToggleCommand ("mute", "Evolve Mute", "mute")
	RegisterCommand ("slay", "Evolve Slay", "slay")
	RegisterCommand ("strip", "Evolve Strip", "strip")
		
	command = CAdmin.Commands.CreateFallback ("pm", "Evolve Private Message")
		:SetFallbackType (CAdmin.FALLBACK_ADMIN)
		:SetSuppressLog (true)
		:SetCanExecute (function (ply, targply)
			if not canEvolve then
				return false
			end
			return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "private_messages")
		end)
		:SetExecute (function (ply, targply, message)
			RunConsoleCommand ("ev", "pm", targply:Name (), message)
		end)
	
	command = CAdmin.Commands.CreateFallback ("set_armor", "Evolve Armor")
		:SetFallbackType (CAdmin.FALLBACK_ADMIN)
		:SetSuppressLog (true)
		:SetCanExecute (function (ply, targply)
			if not canEvolve then
				return false
			end
			return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "armor")
		end)
		:SetExecute (function (ply, targply, armor)
			RunConsoleCommand ("ev", "armor", targply:Name (), armor)
		end)
	
	command = CAdmin.Commands.CreateFallback ("set_hp", "Evolve Health")
		:SetFallbackType (CAdmin.FALLBACK_ADMIN)
		:SetSuppressLog (true)
		:SetCanExecute (function (ply, targply)
			if not canEvolve then
				return false
			end
			return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "health")
		end)
		:SetExecute (function (ply, targply, health)
			RunConsoleCommand ("ev", "hp", targply:Name (), health)
		end)
end

function PLUGIN:Uninitialize ()
	if canEvolve then
		if EvolveAutocomplete then
			if EvolveAutocompleteOverridden then
				EvolveAutocomplete.HUDPaint = EvolveAutocomplete._HUDPaint
				EvolveAutocomplete.OnChatTab = EvolveAutocomplete._OnChatTab
				EvolveAutocomplete._HUDPaint = nil
				EvolveAutocomplete._OnChatTab = nil
			else
				CAdmin.Settings.SetSession ("CAdmin.ChatAutocomplete.Enabled", true)
			end
			EvolveAutocompleteOverridden = false
		end
	end
end

function PLUGIN:EvolveLoaded ()
	if not canEvolve and FindMetaTable ("Player").EV_IsAdmin then
		canEvolve = true
		CAdmin.Fallbacks.Add ("CAdmin.Priveliges.GetDefaultGroup", function ()
			return "guest"
		end)

		CAdmin.Fallbacks.Add ("CAdmin.Priveliges.GetGroups", function ()
			local sortedGroups = {}
			for name, group in pairs (evolve.ranks) do
				 sortedGroups [#sortedGroups + 1] = name
			end
			table.sort (sortedGroups, function (a, b)
				return evolve.ranks [a].Immunity < evolve.ranks [b].Immunity
			end)
			local groupBases = {}
			for i = 2, #sortedGroups do
				groupBases [sortedGroups [i]] = sortedGroups [i - 1]
			end
			local groups = {}
			for name, group in pairs (evolve.ranks) do
				local groupEntry = {}
				groups [name] = groupEntry
				groupEntry.Name = group.Title
				groupEntry.Base = groupBases [name]
				groupEntry.Icon = "gui/silkicons/" .. group.Icon
				groupEntry.Allow = {}
				for _, privelige in ipairs (group.Privileges) do
					groupEntry.Allow [#groupEntry.Allow + 1] = privelige:gsub (" ", "_")
				end
			end
			return groups
		end)

		CAdmin.Fallbacks.Add ("CAdmin.Priveliges.GetPlayerGroup", function (ply)
			return ply:GetNetworkedString ("EV_UserGroup")
		end)

		for _, v in pairs (evolve.plugins) do
			if v.Title == "Chat Autocomplete" then
				EvolveAutocomplete = v
				break
			end
		end
		if EvolveAutocomplete then
			if CAdmin.Settings.Get ("EvolveFallback.OverrideChatAutocomplete", true) then
				EvolveAutocompleteOverridden = true
				EvolveAutocomplete._HUDPaint = EvolveAutocomplete.HUDPaint
				EvolveAutocomplete._OnChatTab = EvolveAutocomplete.OnChatTab
				EvolveAutocomplete.HUDPaint = nil
				EvolveAutocomplete.OnChatTab = nil
			else
				CAdmin.Settings.SetSession ("CAdmin.ChatAutocomplete.Enabled", false)
			end
		end
		CAdmin.Hooks.Call ("CAdminPriveligesChanged")
	end
end