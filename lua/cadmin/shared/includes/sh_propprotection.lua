--[[
	Provides functions for managing player prop rights.
	
	Files:
		
	Datastreams:
	
	Hooks:
]]
CAdmin.RequireInclude ("sh_hooks")
CAdmin.RequireInclude ("sh_usermessage")

CAdmin.PropProtection = CAdmin.PropProtection or {}
local PropProtection = CAdmin.PropProtection
PropProtection.Enabled = false
PropProtection.Entities = {}
--[[
	This is an array of tables of the form:
	{
		entity Owner		- Owner player
		string OwnerName	- Name of owner
	}
]]

local function UpdateEntity (ent, entOwner, entOwnerName)
	local info = PropProtection.GetEntityInfo (ent)
	info.Owner = entOwner or info.Owner
	info.OwnerName = entOwnerName or info.OwnerName
	ent.CAdminPropProtection = true
end

local function ValidatePropProtection (entity)
	if not entity.CAdminPropProtection then
		if type (entity) == "Player" then
			UpdateEntity (entity, entity, entity:Name ())
		else
			PropProtection.Entities [entity:EntIndex ()] = nil
		end
	end
	if PropProtection.Entities [entity:EntIndex ()] then
		local info = PropProtection.GetEntityInfo (entity)
		if info.Owner and
		   not info.Owner:IsValid () then
			info.Owner = nil
		end
	end
end

function PropProtection.CanPlayerSpawnProp (ply, model)
	return true
end

function PropProtection.GetEntityInfo (entity)
	if not PropProtection.Entities [entity:EntIndex ()] then
		PropProtection.Entities [entity:EntIndex ()] = {}
	end
	return PropProtection.Entities [entity:EntIndex ()]
end

function PropProtection.GetOwner (entity)
	ValidatePropProtection (entity)
	local info = PropProtection.GetEntityInfo (entity)
	if not info or not info.Owner then
		-- Force a recalculation of owner.
		PropProtection.GetOwnerName (entity)
	end
	info = PropProtection.GetEntityInfo (entity)
	if not info or (not info.Owner and not info.OwnerName) then
		return nil
	end
	if not info.Owner then
		if info.OwnerName ~= "World" then
			info.Owner = CAdmin.Players.GetUniquePlayerByName (info.OwnerName)
		end
	end
	return info.Owner
end

function PropProtection.GetOwnerName (entity)
	ValidatePropProtection (entity)
	local info = PropProtection.GetEntityInfo (entity)
	if info and info.OwnerName then
		return info.OwnerName
	end
	local ownerFound = false
	local entityOwner = nil
	local entityOwnerName = nil
	if PropProtection.Enabled then
		if info.Owner then
			return info.Owner:Name ()
		end
		return info.OwnerName
	else
		if entity:GetClass () == "player" then
			entityOwner = entity
			entityOwnerName = entity:Name ()
			ownerFound = true
		end

		-- Weapons.
		if not ownerFound then
			if entity.Owner and entity.Owner:IsValid () then
				entityOwner = entity.Owner
				entityOwnerName = entity.Owner:Name ()
				ownerFound = true
			end
		end

		-- Tooltip owners
		if not ownerFound then
			if entity.GetPlayerName then
				if entity:GetPlayerName () ~= "" then
					entityOwnerName = entity:GetPlayerName ()
					ownerFound = true
				end
			end
		end

		-- Wiremod Holograms
		if not ownerFound then
			local ownerID = entity:GetNetworkedInt ("ownerid")
			if ownerID > 0 then
				entityOwner = CAdmin.Players.GetPlayerByUserID (ownerID)
				if entityOwner then
					entityOwnerName = entityOwner:Name ()
					ownerFound = true
				end
			end
		end
		
		-- Simple Prop Protection
		if not ownerFound then
			entityOwner = entity:GetNetworkedEntity ("OwnerObj", false)
			if entityOwner and entityOwner:IsValid () and entityOwner:IsPlayer() then
				entityOwnerName = entityOwner:Name ()
				ownerFound = true
			else
				local owner = entity:GetNetworkedString ("Owner", "")
				if type (owner) == "string" then
					if owner:len () > 0 then
						entityOwnerName = owner
						ownerFound = true
					end
				elseif owner.ValidEntity and owner:ValidEntity () and owner.Name then
					entityOwner = owner
					entityOwnerName = owner:Name ()
					ownerFound = true
				end
			end
		end
		
		-- Modified Simple Prop Protection
		if not ownerFound then
			if SPropProtection and SPropProtection.CLProps then
				local Props = SPropProtection.CLProps
				if Props [entity:EntIndex ()] then
					entityOwnerName = Props [entity:EntIndex ()]
					ownerFound = true
				end
			end
		end

		-- UPS owner
		if not ownerFound then
			if entity.UOwn then
				entityOwnerName = UPS.nameFromID (entity.UOwn)
				ownerFound = true
			end
		end

		-- ASSMod owner
		if not ownerFound then
			local ASSOwner = entity:GetNetworkedEntity ("ASS_Owner")
			if not ASSOwner or not ASSOwner:IsValid () then
				if entity.Player and entity.Player:IsValid () and entity.Player:GetClass () == "player" then
					ASSOwner = entity.Player
				elseif entity.GetPlayer then
					ASSOwner = entity:GetPlayer ()
				end
			end
			if ASSOwner then
				if not ASSOwner:IsValid () or ASSOwner:GetClass () ~= "player" then
					ASSOwner = nil
				end
			end
			if ASSOwner then
				entityOwner = ASSOwner
				entityOwnerName = ASSOwner:Name ()
				ownerFound = true
			end
		end
	end
	if entityOwner and not entityOwner:IsValid () then
		entityOwner = nil
	end
	if ownerFound then
		UpdateEntity (entity, entityOwner, entityOwnerName)
	end
	if entityOwner then
		return entityOwner:Name ()
	end
	return entityOwnerName
end

if CLIENT then
	CAdmin.Usermessages.Hook ("CAdmin.PropProtection.Owner", function (umsg)
		local entity = umsg:ReadEntity ()
		local ownerName = umsg:ReadString ()
		local ownerEntity = umsg:ReadEntity ()
		UpdateEntity (entity, ownerEntity, ownerName)
	end)

	CAdmin.Usermessages.AddInterceptHook ("FPP_Owner", "CAdmin.PropProtection.FPPOwner", function (type, umsg)
		local entity = umsg:ReadEntity ()
		local CanTouchLookingAt = umsg:ReadBool ()
		local owner = umsg:ReadString ()
		UpdateEntity (entity, nil, owner)
	end)
end

CAdmin.Hooks.Add ("CAdminInitialize", "CAdmin.PropProtection.Initialize", function ()
	CAdmin.Hooks.Add ("PlayerSpawnProp", "CAdmin.PropProtection.PlayerSpawnProp", function (ply, model)
		if not PropProtection.CanPlayerSpawnProp (ply, model) then
			return false
		end
	end)
	
	CAdmin.Hooks.Add ("PlayerSpawnedProp", "CAdmin.PropProtection.PlayerSpawnProp", function (ply, model, entity)
		UpdateEntity (entity, ply, ply:Name ())
	end)
end)