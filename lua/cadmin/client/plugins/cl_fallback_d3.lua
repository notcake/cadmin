local PLUGIN = CAdmin.Plugins.Create ("D3vine Fallback")
PLUGIN:SetAuthor ("!cake")
PLUGIN:SetDescription ("Provides D3vine admin fallback commands.")

local canD3vine = false

--[[
	The full list is ridiculously long.
]]
PLUGIN.Groups = {
	d3vine = {
		Base = "superadmin",
		Name = "The D3vine"
	},
	superadmin = {
		Base = "doubleadmin",
		Name = "Super Administrators"
	},
	doubleadmin = {
		Base = "admin",
		Name = "Double Administrators"
	},
	admin = {
		Base = "moderator",
		Icon = "gui/silkicons/shield",
		Name = "Administrators"
	},
	moderator = {
		Base = "member",
		Name = "Moderator"
	},
	member = {
		Base = "builder",
		Icon = "gui/silkicons/star",
		Name = "Member"
	},
	builder = {
		Base = "recruit",
		Name = "Dedicated"
	},
	recruit = {
		Base = "guest",
		Name = "Recruit"
	},
	guest = {
		Base = "minge",
		Icon = "gui/silkicons/user",
		Name = "Guest"
	},
	minge = {
		Icon = "gui/silkicons/exclamation",
		Name = "Minge"
	}
}

function PLUGIN:Initialize ()
	if LocalPlayer ():GetNetworkedString ("flags") ~= "" then
		self:D3vineLoaded ()
	end
end

function PLUGIN:Uninitialize ()
end

function PLUGIN:D3vineLoaded ()
	if not D3vine and LocalPlayer ():GetNetworkedString ("flags") ~= "" then
		canD3vine = true
		CAdmin.Fallbacks.Add ("CAdmin.Priveliges.GetDefaultGroup", function ()
			return "guest"
		end)

		CAdmin.Fallbacks.Add ("CAdmin.Priveliges.GetGroups", function ()
			return self.Groups
		end)

		CAdmin.Fallbacks.Add ("CAdmin.Priveliges.GetPlayerGroup", function (ply)
			local flags = ply:GetNetworkedString ("flags")
			if flags:find ("S") then
				return "d3vine"
			elseif flags:find ("D") then
				return "doubleadmin"
			elseif flags:find ("A") then
				return "admin"
			elseif flags:find ("M") then
				return "moderator"
			elseif flags:find ("E") then
				return "member"
			elseif flags:find ("U") then
				return "builder"
			elseif flags:find ("N") then
				return "recruit"
			elseif flags:find ("Z") then
				return "minge"
			end
			return "guest"
		end)
		CAdmin.Hooks.Call ("CAdminPriveligesChanged")
	end
end