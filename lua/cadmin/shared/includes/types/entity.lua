local TYPE = CAdmin.Commands.RegisterType ("Entity")

TYPE:SetAutocomplete (function (entityID)
	local validEntities = {}
	local entityIDLength = entityID:len ()
	for _, v in pairs (ents.GetAll ()) do
		local entIndex = tostring (v:EntIndex ())
		
		-- Check if the entity index matches.
		if entIndex:sub (1, entityIDLength) == entityID then
			validEntities [#validEntities + 1] = tostring (v:EntIndex ())
		end
		if type (v) == "Player" then
			-- Check if a player name fragment was given.
			if v:Name ():lower ():find (entityID:lower (), 1, true) then
				validEntities [#validEntities + 1] = v:Name ()
			end
		end
	end
	return validEntities
end)

TYPE:SetSerializer (function (ply, entity, usedForLog)
	if usedForLog then
		return "entity " .. tostring (entity:EntIndex ())
	end
	return tostring (entity:EntIndex ())
end)

TYPE:RegisterConverter ("Number", function (ply, entityID)
	local entity = ents.GetByIndex (entityID)
	if entity and entity:IsValid () then
		return entity
	end
	return nil, "No entity with that index exists."
end)

TYPE:RegisterConverter ("String", function (ply, entityID)
	-- Try to use the given value as an entity index.
	if tostring (tonumber (entityID)) == entityID then
		local entity = ents.GetByIndex (tonumber (entityID))
		if tonumber (entityID) == 0 or entity:IsValid () then
			return entity
		end
	end
	
	-- Check if a player name was given.
	local player = CAdmin.Players.GetPlayerByName (entityID)
	if player then
		return player
	end
	player = CAdmin.Players.GetPlayerBySteamID (entityID)
	if player then
		return player
	end
	local entities = ents.FindByClass (entityID:lower())
	if #entities > 0 then
		return entities
	end
	return nil, "No entity with that index, name or class exists."
end)