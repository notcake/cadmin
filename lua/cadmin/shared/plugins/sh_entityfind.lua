local PLUGIN = CAdmin.Plugins.Create ("Find Entities")
PLUGIN:SetAuthor ("!cake")
PLUGIN:SetDescription ("Entity Finder.")

local Classnames = {}

function PLUGIN:Initialize ()
	local command = CAdmin.Commands.Create ("aim_ent", "Sandbox", "Aim at Entity")
		:SetConsoleCommand ("ent_aim")
		:SetAuthenticationRequired (false)
		:SetRunLocation (CAdmin.RUN_BOTH)
	command:AddArgument ("Entity", "Entity")
		:SetPromptText ("Select the entity at which you want to aim:")
	command:SetExecute (function (ply, entity)
		local entityPos = entity:LocalToWorld (Vector (0, 0, 0))
		local eyeAttachmentID = entity:LookupAttachment ("eyes") or 0
		if eyeAttachmentID > 0 then
			entityPos = entity:GetAttachment (eyeAttachmentID).Pos
		end
		local eyeAngles = (entityPos - LocalPlayer ():GetShootPos ()):Angle ()
		LocalPlayer ():SetEyeAngles (eyeAngles)
	end)

	command = CAdmin.Commands.Create ("find_ent", "Sandbox", "Find Entities")
		:SetConsoleCommand ("ent_find")
		:SetAuthenticationRequired (false)
		:SetRunLocation (CAdmin.Commands.RUN_LOCAL)
	command:AddArgument ("Classname", "Classname", "*")
		:SetPromptText ("Enter the classname of the entities you want to find:")
	command:SetExecute (function (ply, class)
		local playerPos = Vector (0, 0, 0)
		if CLIENT then
			playerPos = LocalPlayer ():GetPos ()
		end

		local entities = ents.FindByClass (class)

		print ("Found " .. tostring (#entities) .. " " .. class .. "(s).")
		PLUGIN:PrintEntityTable (entities, playerPos)
	end)

	command = CAdmin.Commands.Create ("find_ent_model", "Sandbox", "Find Entities By Model")
		:SetConsoleCommand ("ent_find_mdl")
		:SetAuthenticationRequired (false)
		:SetRunLocation (CAdmin.Commands.RUN_LOCAL)
	command:AddArgument ("String", "Model path")
		:SetPromptText ("Enter the model path of the entities you want to find:")
	command:AddArgument ("Classname", "Classname", "*")
		:SetPromptText ("Enter the classname of the entities you want to find:")		
	command:SetExecute (function (ply, mdl, class)
		local playerPos = Vector (0, 0, 0)
		if CLIENT then
			playerPos = LocalPlayer ():GetPos ()
		end

		class = class or "*"

		local allentities = ents.FindByClass (class)
		local entities = {}

		for _, v in pairs (allentities) do
			if v:GetModel () then
				if mdl ~= "" and v:GetModel ():lower ():find (mdl, 1, true) then
					table.insert (entities, v)
				end
			else
				if mdl == "" then
					table.insert (entities, v)
				end
			end
		end

		print ("Found " .. tostring (#entities) .. " entities.")
		PLUGIN:PrintEntityTable (entities, playerPos)
	end)

	command = CAdmin.Commands.Create ("find_ent_owner", "Sandbox", "Find Entities By Owner")
		:SetConsoleCommand ("ent_find_ply")
		:SetAuthenticationRequired (false)
		:SetRunLocation (CAdmin.Commands.RUN_LOCAL)
	command:AddArgument ("String", "Owner", false, function (targply)
		local names = CAdmin.Commands.AutocompleteType (targply, "Player")
		table.insert (names, "World")
		return names
	end)
		:SetPromptText ("Select the owner of the entities you want to find:")
	command:AddArgument ("Classname", "Classname", "*")
		:SetPromptText ("Enter the classname of the entities you want to find:")
	command:SetExecute (function (ply, owner, class)
		local playerPos = Vector (0, 0, 0)
		if CLIENT then
			playerPos = LocalPlayer ():GetPos ()
		end

		class = class or "*"
		if owner == "^" then
			owner = ply:Name ()
		end

		local allentities = ents.FindByClass (class)
		local entities = {}

		for _, v in pairs (allentities) do
			local propowner = CAdmin.PropProtection.GetOwnerName (v)
			if propowner then
				if owner ~= "" and (propowner:lower ():find (owner:lower (), 1, true) or owner == "*") then
					table.insert (entities, v)
				end
			else
				if owner == "" then
					table.insert (entities, v)
				end
			end
		end

		print ("Found " .. tostring (#entities) .. " entities.")
		PLUGIN:PrintEntityTable (entities, playerPos)
	end)

	command = CAdmin.Commands.Create ("find_invisible_ent", "Sandbox", "Find Invisible Entities")
		:SetConsoleCommand ("ent_find_invis")
		:SetAuthenticationRequired (false)
		:SetRunLocation (CAdmin.Commands.RUN_LOCAL)
	command:AddArgument ("Classname", "Classname", "*")
		:SetPromptText ("Enter the classname of the entities you want to find:")
	command:SetExecute (function (ply, class)
		local playerPos = Vector (0, 0, 0)
		if CLIENT then
			playerPos = LocalPlayer ():GetPos ()
		end

		local allentities = ents.FindByClass (class)
		local entities = {}

		for _, v in pairs (allentities) do
			local color = {
				v:GetColor ()
			}
			if color [4] < 128 then
				table.insert (entities, v)
			elseif v:GetMaterial () == "models/effects/vol_light001" then
				table.insert (entities, v)
			end
		end

		print ("Found " .. tostring (#entities) .. " invisible entities.")
		PLUGIN:PrintEntityTable (entities, playerPos)
	end)
end

local function SortEntityFunction (a, b)
	return a:EntIndex () < b:EntIndex ()
end

function PLUGIN:PrintEntityTable (entities, playerPos)
	if #entities == 0 then
		return
	end
	table.sort (entities, SortEntityFunction)
	print ("Index  Class                       Distance Owner                   Model")
	for k, v in pairs (entities) do
		local idx = tostring (v:EntIndex ())
		idx = string.rep (" ", 4 - idx:len ()) .. idx

		local class = tostring (v:GetClass ())
		class = class .. string.rep (" ", 27 - class:len ())

		local distance = string.format ("%.2f", (v:GetPos () - playerPos):Length ())
		distance = string.rep (" ", 8 - distance:len ()) .. distance

		local owner = CAdmin.PropProtection.GetOwnerName (v) or "N / A"
		owner = owner .. string.rep (" ", 24 - CAdmin.Util.GetStringWidth (owner))

		print ("[" .. idx .. "] " .. class .. " " .. distance .. " " .. owner .. (v:GetModel () or "<no model>"))
	end
end