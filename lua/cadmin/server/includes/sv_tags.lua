CAdmin.Tags = CAdmin.Tags or {}
CAdmin.Tags.Added = {}
CAdmin.Tags.Tags = {}

local function ReadTags (newTags)
	local tags = string.Explode (",", newTags)
	local tagtbl = {}
	for _, v in pairs (tags) do
		tagtbl [v:Trim ()] = true
	end
	return tagtbl
end

local function ReadTagsFromConVar ()
	return ReadTags (GetConVar ("sv_tags"):GetString ())
end

local function UpdateTagString ()
	local tagList = {}
	for k, _ in pairs (CAdmin.Tags.Tags) do
		tagList [#tagList + 1] = k
	end
	table.sort (tagList)
	local sv_tags = nil
	for _, v in ipairs (tagList) do
		if sv_tags then
			sv_tags = sv_tags .. "," .. v
		else
			sv_tags = v
		end
	end
	RunConsoleCommand ("sv_tags", sv_tags or "")
end

local function OnTagsChanged ()
	local changed = false
	for k, _ in pairs (CAdmin.Tags.Added) do
		if not CAdmin.Tags.Tags [k] then
			CAdmin.Tags.Tags [k] = true
			changed = true
		end
	end
	if changed then
		UpdateTagString ()
	end
end

function CAdmin.Tags.Add (tag)
	CAdmin.Tags.Tags [tag] = true
	CAdmin.Tags.Added [tag] = true
	UpdateTagString ()
end

function CAdmin.Tags.GetTags ()
	return CAdmin.Tags.Tags
end

function CAdmin.Tags.IsTagPresent (tag)
	if CAdmin.Tags.Tags [tag] then
		return true
	end
	return false
end

function CAdmin.Tags.Remove (tag)
	CAdmin.Tags.Tags [tag] = nil
	CAdmin.Tags.Added [tag] = nil
end

CAdmin.Tags.Tags = ReadTagsFromConVar ()

CAdmin.Hooks.Add ("CAdminInitialize", "CAdmin.Tags.Initialize", function ()
	CAdmin.Console.AddChangeCallback ("sv_tags", function (convarName, oldValue, newValue)
		CAdmin.Tags.Tags = ReadTags (newValue)
		OnTagsChanged (newValue)
	end)
end)