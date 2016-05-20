local PLUGIN = CAdmin.Plugins.Create ("Citrus Fallback")
PLUGIN:SetAuthor ("!cake")
PLUGIN:SetDescription ("Provides Citrus fallback commands.")

local canCitrus = false

PLUGIN.GroupNamesToGroups = {
	["Super Administrator"] = "superadmin",
	["Administrator"] = "admin",
	["Moderator"] = "moderator",
	["Guest"] = "guest"
}

PLUGIN.Groups = {
	superadmin = {
		Allow = {
			"crash",
			"playerpickup"
		},
		Base = "admin",
		Name = "Super Administrators"
	},
	admin = {
		Allow = {
			"cexec",
			"god"
		},
		Base = "moderator",
		Icon = "gui/silkicons/shield",
		Name = "Administrators"
	},
	moderator = {
		Allow = {
			"blind",
			"bring",
			"freeze",
			"ghost",
			"giveammo",
			"giveweapon",
			"ignite",
			"mute",
			"mute_voice",
			"rocket",
			"send",
			"slap",
			"slay",
			"strip"
		},
		Base = "guest",
		Icon = "gui/silkicons/star",
		Name = "Moderator"
	},
	guest = {
		Allow = {
			"goto",
			"title"
		},
		Icon = "gui/silkicons/user",
		Name = "Guest"
	}
}

function PLUGIN:Initialize ()
	if LocalPlayer ():GetNetworkedString (util.CRC ("citrus.PlayerInformation['Public']['Group']")) ~= "" then
		self:CitrusLoaded ()
	end
end

function PLUGIN:CitrusLoaded ()
	if not canCitrus then
		canCitrus = true
		CAdmin.Fallbacks.Add ("CAdmin.Priveliges.GetDefaultGroup", function ()
			return "guest"
		end)

		CAdmin.Fallbacks.Add ("CAdmin.Priveliges.GetGroups", function ()
			return self.Groups
		end)

		CAdmin.Fallbacks.Add ("CAdmin.Priveliges.GetPlayerGroup", function (ply)
			local groupName = ply:GetNetworkedString (util.CRC ("citrus.PlayerInformation['Public']['Group']")):lower ()
			if self.GroupNamesToGroups [groupName] then
				return self.GroupNamesToGroups [groupName]
			end
			return groupName:lower ()
		end)
		
		CAdmin.Hooks.Call ("CAdminPriveligesChanged")
	end
end