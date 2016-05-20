local PLUGIN = CAdmin.Plugins.Create ("ASSMod Fallback")
PLUGIN:SetAuthor ("!cake")
PLUGIN:SetDescription ("Provides ASSMod fallback commands.")

local canASSMod = false

PLUGIN.GroupLevels = {
	"owner",
	"superadmin",
	"admin",
	"tempadmin",
	"respected",
	"guest"
}
PLUGIN.GroupLevels [256] = "banned"

PLUGIN.Groups = {
	owner = {
		Base = "superadmin",
		Name = "Server Owner"
	},
	superadmin = {
		Base = "admin",
		Name = "Super Administrators"
	},
	admin = {
		Base = "tempadmin",
		Name = "Administrators"
	},
	tempadmin = {
		Base = "respected",
		Icon = "gui/silkicons/shield",
		Name = "Temporary Administrators"
	},
	respected = {
		Base = "guest",
		Icon = "gui/silkicons/star",
		Name = "Respected"
	},
	guest = {
		Icon = "gui/silkicons/user",
		Name = "Guest"
	},
	banned = {
		Name = "Previously Banned"
	}
}

function PLUGIN:Initialize ()
	if FindMetaTable ("Player").GetLevel then
		self:ASSModLoaded ()
	end
end

function PLUGIN:Uninitialize ()
end

function PLUGIN:ASSModLoaded ()
	if not canASSMod and FindMetaTable ("Player").GetLevel then
		canASSMod = true
		CAdmin.Fallbacks.Add ("CAdmin.Priveliges.GetDefaultGroup", function ()
			return "guest"
		end)

		CAdmin.Fallbacks.Add ("CAdmin.Priveliges.GetGroups", function ()
			return self.Groups
		end)

		CAdmin.Fallbacks.Add ("CAdmin.Priveliges.GetPlayerGroup", function (ply)
			return self.GroupLevels [ply:GetLevel () + 1]
		end)
		CAdmin.Hooks.Call ("CAdminPriveligesChanged")
	end
end