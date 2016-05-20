local TAB = TAB
TAB:SetName ("Server Log")
TAB:SetIcon ("gui/silkicons/table_edit.vmt")
TAB:SetTabPosition (3)
TAB:SetTooltip ("The server log.")

function TAB:Init ()
	self.Log = self:Create ("DComboBox")
	
	CAdmin.Hooks.Add ("CAdminPlayerConnected", "CAdminLog", function (steamID, uniqueID, playerName, ply)
		self.Log:AddItem (CAdmin.Messages.FormatTime () .. " " .. playerName .. " (" .. steamID .. ") connected.")
	end)
	
	CAdmin.Hooks.Add ("CAdminPlayerDisconnected", "CAdminLog", function (steamID, uniqueID, playerName)
		self.Log:AddItem (CAdmin.Messages.FormatTime () .. " " .. playerName .. " (" .. steamID .. ") disconnected.")
	end)

	CAdmin.Hooks.Add ("CAdminPlayerNameChanged", "CAdminLog", function (steamID, uniqueID, ply, originalName, oldName, newName)
		self.Log:AddItem (CAdmin.Messages.FormatTime () .. " (" .. steamID .. " \"" .. originalName .. "\") Renamed themself from " .. oldName .. " to " .. newName .. ".")
	end)
	
	CAdmin.Hooks.Add ("CAdminPlayerDeath", "CAdminLog", function (victim, attacker, inflictorName, attackerName)
		Msg (tostring(victim) .. "|" .. tostring(attacker) .. "|" ..tostring(inflictorName) .. "|" .. tostring(attackerName).. ".\n")
		if victim == attacker then
			if inflictorName then
				self.Log:AddItem (CAdmin.Messages.FormatTime () .. " " .. victim:Name () .. " killed themself with " .. inflictorName .. ".")
			else
				self.Log:AddItem (CAdmin.Messages.FormatTime () .. " " .. victim:Name () .. " committed suicide.")
			end
		else
			self.Log:AddItem (CAdmin.Messages.FormatTime () .. " " .. victim:Name () .. " was killed by " .. attackerName .. ".")
		end
	end)
end

function TAB:PerformLayout (firstTime, ...)
	self.Log:SetPos (self:GetPadding (), self:GetPadding ())
	self.Log:SetSize (self:GetWide () - 2 * self:GetPadding (), self:GetTall () - 2 *self:GetPadding ())
end