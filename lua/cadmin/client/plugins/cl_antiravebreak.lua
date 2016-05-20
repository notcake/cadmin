local PLUGIN = CAdmin.Plugins.Create ("Anti Ravebreak")
PLUGIN:SetAuthor ("!cake")
PLUGIN:SetDescription ("Suppresses the ravebreak lua script.")

local function DoNothing ()
end

function PLUGIN:Initialize ()
	CAdmin.Usermessages.AddInterceptHook ("RaveBreak", "AntiRavebreak", function ()
		if CAdmin.Settings.Get ("AntiRavebreak.AntiRavebreakEnabled", true) then
			hook.Add ("RenderScreenspaceEffects", "RaveDraw", DoNothing)
			--[[
				Avoid breaking RaveEnd when hook.Remove is hooked to
				complain when an inexistant hook is removed.
			]]
			return true
		end
	end)
end