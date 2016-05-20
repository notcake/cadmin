local PLUGIN = CAdmin.Plugins.Create ("Developer Tools")
PLUGIN:SetAuthor ("!cake")
PLUGIN:SetDescription ("A set of useful commands.")

function PLUGIN:Initialize ()
	local command = CAdmin.Commands.Create ("displayprofilerstats", "Commands", "Display Profiler Statistics")
		:SetConsoleCommand ("print_profiler_info")
		:SetRunLocation (CAdmin.Commands.RUN_LOCAL)
		:SetAuthenticationRequired (false)
	command:SetExecute (function (ply)
		CAdmin.Profiler.PrintData ()
	end)
	
	command = CAdmin.Commands.Create ("showmodelname", "Commands", "Display Model Name")
		:SetConsoleCommand ("print_model")
		:SetRequiresClient ()
		:SetAuthenticationRequired (false)
		:SetRunLocation (CAdmin.Commands.RUN_BOTH)
	command:SetExecute (function (ply)
		local trace = ply:GetEyeTrace ()
		if trace.Fraction == 1 then
			CAdmin.Messages.TsayPlayer (ply, "Object is too far away.")
			return
		end
		SetClipboardText (ply:GetEyeTrace ().Entity:GetModel ():lower ())
		CAdmin.Messages.TsayPlayer (ply, "That model is \"" .. ply:GetEyeTrace ().Entity:GetModel () .. "\".")
	end)
	
	command = CAdmin.Commands.Create ("showtexturename", "Commands", "Display Texture Name")
		:SetConsoleCommand ("print_texture")
		:SetRequiresClient ()
		:SetAuthenticationRequired (false)
		:SetRunLocation (CAdmin.Commands.RUN_BOTH)
	command:SetExecute (function (ply)
		local trace = ply:GetEyeTrace ()
		if trace.Fraction == 1 then
			CAdmin.Messages.TsayPlayer (ply, "Object is too far away.")
			return
		end
		if trace.HitTexture == "**studio**" then
			CAdmin.Messages.TsayPlayer (ply, "Cannot obtain texture from an entity.")
		else
			SetClipboardText (ply:GetEyeTrace ().HitTexture:lower ())
			CAdmin.Messages.TsayPlayer (ply, "That texture is \"" .. ply:GetEyeTrace ().HitTexture .. "\".")
		end
	end)
	
	command = CAdmin.Commands.Create ("uptime", "Commands", "Display Server Uptime")
		:SetConsoleCommand ("uptime")
		:SetAuthenticationRequired (false)
		:SetRunLocation (CAdmin.Commands.RUN_LOCAL)
	command:SetExecute (function (ply)
		local uptime = CurTime ()
		local nonzero = false
		if uptime > 0 then
			nonzero = true
		end
		
		local milliseconds = uptime % 1 * 1000
		uptime = uptime - milliseconds / 1000
		local seconds = uptime % 60
		uptime = uptime - seconds
		local minutes = uptime % 3600 / 60
		uptime = uptime - minutes * 60
		local hours = uptime % 86400 / 3600
		uptime = uptime - hours * 3600
		local days = uptime / 86400
		
		local uptimeString = "Server Uptime:"
		if days > 0 then
			uptimeString = uptimeString .. " " .. string.format ("%.3d", days) .. " days"
		end
		if hours > 0 then
			uptimeString = uptimeString .. " " .. string.format ("%.2d", hours) .. " hours"
		end
		if minutes > 0 then
			uptimeString = uptimeString .. " " .. string.format ("%.2d", minutes) .. " minutes"
		end
		if seconds > 0 then
			uptimeString = uptimeString .. " " .. string.format ("%.2d", seconds) .. " seconds"
		end
		if milliseconds > 0 or not nonzero then
			uptimeString = uptimeString .. " " .. string.format ("%.3d", milliseconds) .. " milliseconds"
		end
		uptimeString = uptimeString .. "."
		CAdmin.Messages.TsayPlayer (ply, uptimeString)
	end)
end
