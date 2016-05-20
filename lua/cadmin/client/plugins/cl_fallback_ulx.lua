local PLUGIN = CAdmin.Plugins.Create ("ULX Fallback")
PLUGIN:SetAuthor ("!cake")
PLUGIN:SetDescription ("Provides ULX fallback commands.")

local canULX = false

function PLUGIN:Initialize ()
	CAdmin.Hooks.AddToWhitelist ("UCLAuthed")
	CAdmin.Hooks.AddToWhitelist ("UCLChanged")
	CAdmin.Hooks.AddToWhitelist ("UlibReplicatedCVarChanged")
	CAdmin.Hooks.AddToWhitelist ("ULibLocalPlayerReady")
	CAdmin.Hooks.AddToWhitelist ("ULibCommandCalled")
	CAdmin.Hooks.AddToWhitelist ("ULibPlayerTarget")
	CAdmin.Hooks.AddToWhitelist ("ULibPlayerTargets")
	CAdmin.Hooks.AddToWhitelist ("ULibPostTranslatedCommand")

	if ULib and ULib.ucl and (ULib.ucl.authed [LocalPlayer ()] or ULib.ucl.authed [CAdmin.Players.GetUniqueID (LocalPlayer ())]) then
		self:ULXLoaded ()
	else
		CAdmin.Usermessages.AddInterceptHook ("ULibUserUCL", "ULX Fallback", function (type, umsg)
			self:ULXLoaded (type, umsg)
		end)
		CAdmin.Usermessages.AddInterceptHook ("ULibFinishedUCL", "ULX Fallback", function (type, umsg)
			self:ULXLoaded (type, umsg)
		end)
	end
	CAdmin.Hooks.Add ("UCLAuthed", "CAdmin.ULXFallback", function ()
		CAdmin.Hooks.Call ("CAdminPriveligesChanged")
		CAdmin.Timers.RunNextTick (self.ULXLoaded, self)
	end)

	CAdmin.Usermessages.AddInterceptHook ("tsayc", "ULX Fallback", function (type, umsg)
		local argn = umsg:ReadChar ()
		local args = {}
		for i = 1, argn do
			table.insert (args, Color (umsg:ReadChar () + 128, umsg:ReadChar () + 128, umsg:ReadChar () + 128))
			table.insert (args, umsg:ReadString ())
		end
		local originator = args [2]
		if not args [4] then
			return
		end
		local action = string.Trim (args [4])
		local players = {}
		for i = 3, argn do
			local color = args [i * 2 - 1]
			if color.r == 50 and color.g == 160 and color.b == 255 then
				if args [i * 2] ~= ", " then
					break
				end
			else
				if color.r == 75 and color.g == 0 and color.b == 130 and
				(args [i * 2] == "You" or args [i * 2] == "yourself") then
					table.insert (players, LocalPlayer ():Name ())
				else
					if args [i * 2] == "themself" then
						table.insert (players, originator)
					else
						table.insert (players, args [i * 2])
					end
				end
			end
		end
		for k, v in pairs (players) do
			players [k] = CAdmin.Players.GetPlayerByName (v)
		end
		for k, v in pairs (players) do
			if action == "blinded" then
				v.CAdminBlinded = true
			elseif action == "unblinded" then
				v.CAdminBlinded = false
			elseif action == "gagged" then
				v.CAdminGagged = true
			elseif action == "ungagged" then
				v.CAdminGagged = false
			elseif action == "gimped" then
				v.CAdminGimped = true
			elseif action == "ungimped" then
				v.CAdminGimped = false
			elseif action == "granted god mode upon" then
				v.CAdminGodded = true
			elseif action == "revoked god mode from" then
				v.CAdminGodded = false
			elseif action == "jailed" then
				v.CAdminJailed = true
			elseif action == "unjailed" then
				v.CAdminJailed = false
			elseif action == "muted" then
				v.CAdminMuted = true
			elseif action == "unmuted" then
				v.CAdminMuted = false
			end
		end
		CAdmin.Hooks.QueueBusyCall ("CAdminCommandToggleStatesChanged")
	end)
	
	local command = CAdmin.Commands.CreateFallback ("set_armor", "ULX Armor")
		:SetFallbackType (CAdmin.FALLBACK_ADMIN)
		:SetSuppressLog (true)
		:SetCanExecute (function (ply, targply, armor)
			if not canULX then
				return false
			end
			return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "ulx armor")
		end)
		:SetExecute (function (ply, targply, armor)
			RunConsoleCommand ("ulx", "armor", targply:Name (), tostring (armor))
		end)

	command = CAdmin.Commands.CreateFallback ("ban", "ULX Ban")
		:SetFallbackType (CAdmin.FALLBACK_ADMIN)
		:SetSuppressLog (true)
		:SetCanExecute (function (ply, targply)
			if not canULX then
				return false
			end
			return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "ulx banid")
		end)
		:SetExecute (function (ply, targply, banTime, reason)
			RunConsoleCommand ("ulx", "banid", targply:SteamID (), banTime, reason)
		end)

	command = CAdmin.Commands.CreateFallback ("blind", "ULX Blind")
		:SetFallbackType (CAdmin.FALLBACK_ADMIN)
		:SetSuppressLog (true)
		:SetCanExecute (function (ply, targply, blind)
			if not canULX then
				return false
			end
			if blind then
				return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "ulx blind")
			else
				return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "ulx unblind")
			end
		end)
		:SetExecute (function (ply, targply, blind)
			if blind then
				RunConsoleCommand ("ulx", "blind", targply:Name ())
			else
				RunConsoleCommand ("ulx", "unblind", targply:Name ())
			end
		end)
		:SetGetToggleState (function (targply)
			if targply.CAdminBlinded then
				return true
			end
			return false
		end)

	command = CAdmin.Commands.CreateFallback ("bring", "ULX Bring")
		:SetFallbackType (CAdmin.FALLBACK_ADMIN)
		:SetSuppressLog (true)
		:SetCanExecute (function (ply, targply)
			if not canULX then
				return false
			end
			return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "ulx bring")
		end)
		:SetExecute (function (ply, targply)
			RunConsoleCommand ("ulx", "bring", targply:Name ())
		end)

	command = CAdmin.Commands.CreateFallback ("cloak", "ULX Cloak")
		:SetFallbackType (CAdmin.FALLBACK_ADMIN)
		:SetSuppressLog (true)
		:SetCanExecute (function (ply, targply, cloak)
			if not canULX then
				return false
			end
			if freeze then
				return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "ulx cloak")
			else
				return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "ulx uncloak")
			end
		end)
		:SetExecute (function (ply, targply, cloak)
			if cloak then
				RunConsoleCommand ("ulx", "cloak", targply:Name ())
			else
				RunConsoleCommand ("ulx", "uncloak", targply:Name ())
			end
		end)
		:SetGetToggleState (function (targent)
			if not targent.GetMaterial then
				CAdmin.Debug.PrintStackTrace ()
				return false
			end
			if targent:GetMaterial () == "models/effects/vol_light001" then
				return true
			end
			return false
		end)

	command = CAdmin.Commands.CreateFallback ("freeze", "ULX Freeze")
		:SetFallbackType (CAdmin.FALLBACK_ADMIN)
		:SetSuppressLog (true)
		:SetCanExecute (function (ply, targply, freeze)
			if not canULX then
				return false
			end
			if freeze then
				return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "ulx freeze")
			else
				return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "ulx unfreeze")
			end
		end)
		:SetExecute (function (ply, targply, freeze)
			if freeze then
				RunConsoleCommand ("ulx", "freeze", targply:Name ())
			else
				RunConsoleCommand ("ulx", "unfreeze", targply:Name ())
			end
		end)
		:SetGetToggleState (function (targply)
			if targply:IsFrozen () then
				return true
			end
			return false
		end)

	command = CAdmin.Commands.CreateFallback ("gimp", "ULX Gimp")
		:SetFallbackType (CAdmin.FALLBACK_ADMIN)
		:SetSuppressLog (true)
		:SetCanExecute (function (ply, targply, gimp)
			if not canULX then
				return false
			end
			if gimp then
				return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "ulx gimp")
			else
				return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "ulx ungimp")
			end
		end)
		:SetExecute (function (ply, targply, gimp)
			if gimp then
				RunConsoleCommand ("ulx", "gimp", targply:Name ())
			else
				RunConsoleCommand ("ulx", "ungimp", targply:Name ())
			end
		end)
		:SetGetToggleState (function (targply)
			if targply.CAdminGimped then
				return true
			end
			return false
		end)

	command = CAdmin.Commands.CreateFallback ("god", "ULX God")
		:SetFallbackType (CAdmin.FALLBACK_ADMIN)
		:SetSuppressLog (true)
		:SetCanExecute (function (ply, targply, god)
			if not canULX then
				return false
			end
			if god then
				return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "ulx god")
			else
				return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "ulx ungod")
			end
		end)
		:SetExecute (function (ply, targply, god)
			if god then
				RunConsoleCommand ("ulx", "god", targply:Name ())
			else
				RunConsoleCommand ("ulx", "ungod", targply:Name ())
			end
		end)
		:SetGetToggleState (function (targply)
			if targply.CAdminGodded then
				return true
			end
			return false
		end)

	command = CAdmin.Commands.CreateFallback ("goto", "ULX Go To")
		:SetFallbackType (CAdmin.FALLBACK_ADMIN)
		:SetSuppressLog (true)
		:SetCanExecute (function (ply, targply)
			if not canULX then
				return false
			end
			return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "ulx goto")
		end)
		:SetExecute (function (ply, targply)
			RunConsoleCommand ("ulx", "goto", targply:Name ())
		end)
		
	command = CAdmin.Commands.CreateFallback ("set_hp", "ULX Health")
		:SetFallbackType (CAdmin.FALLBACK_ADMIN)
		:SetSuppressLog (true)
		:SetCanExecute (function (ply, targply, hp)
			if not canULX then
				return false
			end
			return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "ulx hp")
		end)
		:SetExecute (function (ply, targply, hp)
			RunConsoleCommand ("ulx", "hp", targply:Name (), tostring (hp))
		end)

	command = CAdmin.Commands.CreateFallback ("ignite", "ULX Ignite")
		:SetFallbackType (CAdmin.FALLBACK_ADMIN)
		:SetSuppressLog (true)
		:SetCanExecute (function (ply, targply, ignite)
			if not canULX then
				return false
			end
			if ignite then
				return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "ulx ignite")
			else
				return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "ulx unignite")
			end
		end)
		:SetExecute (function (ply, targply, ignite)
			if ignite then
				RunConsoleCommand ("ulx", "ignite", targply:Name ())
			else
				RunConsoleCommand ("ulx", "unignite", targply:Name ())
			end
		end)

	command = CAdmin.Commands.CreateFallback ("jail", "ULX Jail")
		:SetFallbackType (CAdmin.FALLBACK_ADMIN)
		:SetSuppressLog (true)
		:SetCanExecute (function (ply, targply, jail)
			if not canULX then
				return false
			end
			if jail then
				return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "ulx jail")
			else
				return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "ulx unjail")
			end
		end)
		:SetExecute (function (ply, targply, jail)
			if jail then
				RunConsoleCommand ("ulx", "jail", targply:Name ())
			else
				RunConsoleCommand ("ulx", "unjail", targply:Name ())
			end
		end)
		:SetGetToggleState (function (targply)
			if targply.CAdminJailed then
				return true
			end
			return false
		end)

	command = CAdmin.Commands.CreateFallback ("kick", "ULX Kick")
		:SetFallbackType (CAdmin.FALLBACK_ADMIN)
		:SetSuppressLog (true)
		:SetCanExecute (function (ply, targply)
			if not canULX then
				return false
			end
			return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "ulx kick")
		end)
		:SetExecute (function (ply, targply, reason)
			RunConsoleCommand ("ulx", "kick", targply:Name (), reason)
		end)

	command = CAdmin.Commands.CreateFallback ("mute", "ULX Mute")
		:SetFallbackType (CAdmin.FALLBACK_ADMIN)
		:SetSuppressLog (true)
		:SetCanExecute (function (ply, targply, mute)
			if not canULX then
				return false
			end
			if mute then
				return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "ulx mute")
			else
				return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "ulx unmute")
			end
		end)
		:SetExecute (function (ply, targply, mute)
			if mute then
				RunConsoleCommand ("ulx", "mute", targply:Name ())
			else
				RunConsoleCommand ("ulx", "unmute", targply:Name ())
			end
		end)
		:SetGetToggleState (function (targply)
			if targply.CAdminMuted then
				return true
			end
			return false
		end)

	command = CAdmin.Commands.CreateFallback ("mute_voice", "ULX Mute Voice")
		:SetFallbackType (CAdmin.FALLBACK_ADMIN)
		:SetSuppressLog (true)
		:SetCanExecute (function (ply, targply, gag)
			if not canULX then
				return false
			end
			if gag then
				return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "ulx gag")
			else
				return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "ulx ungag")
			end
		end)
		:SetExecute (function (ply, targply, gag)
			if gag then
				RunConsoleCommand ("ulx", "gag", targply:Name ())
			else
				RunConsoleCommand ("ulx", "ungag", targply:Name ())
			end
		end)
		:SetGetToggleState (function (targply)
			if targply.CAdminGagged then
				return true
			end
			return false
		end)
		
	command = CAdmin.Commands.CreateFallback ("pm", "ULX Private Message")
		:SetFallbackType (CAdmin.FALLBACK_ADMIN)
		:SetCanExecute (function (ply, targply, message)
			if not canULX then
				return false
			end
			return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "ulx psay")
		end)
		:SetExecute (function (ply, targply, message)
			RunConsoleCommand ("ulx", "psay", targply:Name (), message)
		end)

	command = CAdmin.Commands.CreateFallback ("ragdoll", "ULX Ragdoll")
		:SetFallbackType (CAdmin.FALLBACK_ADMIN)
		:SetSuppressLog (true)
		:SetCanExecute (function (ply, targply, ragdoll)
			if not canULX then
				return false
			end
			if ragdoll then
				return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "ulx ragdoll")
			else
				return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "ulx unragdoll")
			end
		end)
		:SetExecute (function (ply, targply, ragdoll)
			if ragdoll then
				RunConsoleCommand ("ulx", "ragdoll", targply:Name ())
			else
				RunConsoleCommand ("ulx", "unragdoll", targply:Name ())
			end
		end)
		:SetGetToggleState (function (targply)
			if targply:GetObserverMode () == OBS_MODE_CHASE and
			   targply:GetObserverTarget () and targply:GetObserverTarget ():IsValid () and targply:GetObserverTarget ():GetClass () == "prop_ragdoll" then
				return true
			end
			return false
		end)

	command = CAdmin.Commands.CreateFallback ("send", "ULX Send")
		:SetFallbackType (CAdmin.FALLBACK_ADMIN)
		:SetSuppressLog (true)
		:SetCanExecute (function (ply, targply, destply)
			if not canULX then
				return false
			end
			if targply and destply and targply == destply then
				return false
			end
			return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "ulx send")
		end)
		:SetExecute (function (ply, targply, destply)
			RunConsoleCommand ("ulx", "send", targply:Name (), destply:Name ())
		end)

	command = CAdmin.Commands.CreateFallback ("slay", "ULX Slay")
		:SetFallbackType (CAdmin.FALLBACK_ADMIN)
		:SetSuppressLog (true)
		:SetCanExecute (function (ply, targply)
			if not canULX then
				return false
			end
			return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "ulx slay")
		end)
		:SetExecute (function (ply, targply)
			RunConsoleCommand ("ulx", "slay", targply:Name ())
		end)

	command = CAdmin.Commands.CreateFallback ("sslay", "ULX Slay (Silent)")
		:SetFallbackType (CAdmin.FALLBACK_ADMIN)
		:SetSuppressLog (true)
		:SetCanExecute (function (ply, targply)
			if not canULX then
				return false
			end
			return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "ulx sslay")
		end)
		:SetExecute (function (ply, targply)
			RunConsoleCommand ("ulx", "sslay", targply:Name ())
		end)

	command = CAdmin.Commands.CreateFallback ("strip", "ULX Strip")
		:SetFallbackType (CAdmin.FALLBACK_ADMIN)
		:SetSuppressLog (true)
		:SetCanExecute (function (ply, targply, strip, ...)
			if not canULX then
				return false
			end
			if not targply or strip then
				return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "ulx strip")
			else
				return false
			end
		end)
		:SetExecute (function (ply, targply, strip)
			if strip then
				RunConsoleCommand ("ulx", "strip", targply:Name ())
			else
				RunConsoleCommand ("ulx", "unstrip", targply:Name ())
			end
		end)
		:SetGetToggleState (function (targply)
			return false
		end)
end

function PLUGIN:Uninitialize ()
end

function PLUGIN:ULXLoaded (type, umsg)
	local priveligesChanged = false
	if type == "ULibUserUCL" then
		ULib.ucl.rcvUserData (umsg)
		priveligesChanged = true
	end
	if not canULX and ULib and ULib.ucl then
		if ULib.ucl.authed [LocalPlayer ()] or ULib.ucl.authed [CAdmin.Players.GetUniqueID (LocalPlayer ())] then
			canULX = true
			CAdmin.Fallbacks.Add ("CAdmin.Priveliges.GetGroups", function (ply)
				if not ULib then
					return nil
				end
				local groups = {}
				for k, v in pairs (ULib.ucl.groups) do
					groups [k] = {
						Name = k,
						Base = v.inherit_from,
						Allow = table.Copy (v.allow)
					}
					if k == "admin" or k == "superadmin" then
						groups [k].Icon = "gui/silkicons/shield"
					end
					if k == "respected" or k == "vip" then
						groups [k].Icon = "gui/silkicons/star"
					end
					if k == "user" then
						groups [k].Icon = "gui/silkicons/user"
					end
				end
				return groups
			end)
		
			CAdmin.Fallbacks.Add ("CAdmin.Priveliges.GetPlayerGroup", function (ply)
				if not ULib.ucl.authed [ply] and not ULib.ucl.authed [CAdmin.Players.GetUniqueID (ply)] then
					return nil
				end
				if ply.GetUserGroup then
					local group = ply:GetUserGroup ()
					if group == "" then
						return nil
					end
					return ply:GetUserGroup ()
				end
				if not ULib then
					return nil
				end
				if ULib.ucl.authed [ply] then
					return ULib.ucl.authed [ply].groups [1]
				end
			end)
			priveligesChanged = true
		end
	end
	if priveligesChanged then
		CAdmin.Hooks.Call ("CAdminPriveligesChanged")
	end
end