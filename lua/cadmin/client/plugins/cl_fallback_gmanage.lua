local PLUGIN = CAdmin.Plugins.Create ("GManage Fallback")
PLUGIN:SetAuthor ("!cake")
PLUGIN:SetDescription ("Provides GManage fallback commands.")

local canGManage = false

function PLUGIN:Initialize ()
	if LocalPlayer ():GetNetworkedString ("usr_group") ~= "" then
		self:GManageLoaded ()
	end

	local command = CAdmin.Commands.CreateFallback ("bring", "GManage Bring")
	command:SetFallbackType (CAdmin.FALLBACK_ADMIN)
	command:SetSuppressLog (true)
	command:SetCanExecute (function (ply, targply)
		if not canGManage then
			return false
		end
		return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "g_teleportation")
	end)
	command:SetExecute (function (ply, targply)
		GManage.Plugs.Call ("DoPlayerAction", targply, "bring")
	end)

	local command = CAdmin.Commands.CreateFallback ("bring_view", "GManage Bring to View")
	command:SetFallbackType (CAdmin.FALLBACK_ADMIN)
	command:SetSuppressLog (true)
	command:SetCanExecute (function (ply, targply)
		if not canGManage then
			return false
		end
		return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "g_teleportation")
	end)
	command:SetExecute (function (ply, targply)
		GManage.Plugs.Call ("DoPlayerAction", targply, "tp")
	end)

	local command = CAdmin.Commands.CreateFallback ("goto", "GManage Go To")
	command:SetFallbackType (CAdmin.FALLBACK_ADMIN)
	command:SetSuppressLog (true)
	command:SetCanExecute (function (ply, targply)
		if not canGManage then
			return false
		end
		return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "g_teleportation")
	end)
	command:SetExecute (function (ply, targply)
		GManage.Plugs.Call ("DoPlayerAction", targply, "goto")
	end)

	local command = CAdmin.Commands.CreateFallback ("ragdoll", "GManage Ragdoll")
	command:SetFallbackType (CAdmin.FALLBACK_ADMIN)
	command:SetSuppressLog (true)
	command:SetCanExecute (function (ply, targply, ragdoll)
		if not canGManage then
			return false
		end
		return CAdmin.Priveliges.IsPlayerAuthorized (LocalPlayer (), "g_ragdoll")
	end)
	command:SetExecute (function (ply, targply, ragdoll)
		if ragdoll then
			GManage.Plugs.Call ("DoPlayerAction", targply, "ragdoll")
		else
			GManage.Plugs.Call ("DoPlayerAction", targply, "unragdoll")
		end
	end)
	command:SetGetToggleState (function (targply)
		return targply:GetNetworkedBool ("Ragdolled")
	end)
end

function PLUGIN:Uninitialize ()
end

local groupIcons = {
	owner = "gui/silkicons/shield",
	superadmin = "gui/silkicons/shield",
	admin = "gui/silkicons/shield",
	respected = "gui/silkicons/star",
	vip = "gui/silkicons/star",
	guest = "gui/silkicons/user",
}

function PLUGIN:GManageLoaded ()
	if not canGManage then
		canGManage = true
		CAdmin.Fallbacks.Add ("CAdmin.Priveliges.GetDefaultGroup", function ()
			return GManage.Plugs.Call ("GetDefaultGroup"):lower ()
		end)

		CAdmin.Fallbacks.Add ("CAdmin.Priveliges.GetGroups", function ()
			local groups = {}
			for _, v in pairs (GManage.Plugs.Call ("GetUGSNames")) do
				local groupName = v [1]:lower ()
				groups [groupName] = {
					Allow = {},
					Icon = groupIcons [groupName],
					Name = v [2]
				}
				local groupData = GManage.Plugs.Call ("GetUG", v [1])
				if not groupData then
					return nil
				end
				for k, v in pairs (groupData.Privs) do
					groups [groupName].Allow [k] = "g_" .. v
					if not groups [groupName].Icon and v == "status_admin" or v == "status_superadmin"  then
						groups [groupName].Icon = "gui/silkicons/shield"
					end
				end
			end
			return groups
		end)

		CAdmin.Fallbacks.Add ("CAdmin.Priveliges.GetPlayerGroup", function (ply)
			return ply:GetNetworkedString ("usr_group"):lower ()
		end)
		CAdmin.Hooks.Call ("CAdminPriveligesChanged")
	end
end