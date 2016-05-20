CAdmin.RequireInclude ("sh_lua")

CAdmin.Objects = CAdmin.Objects or {}
local Objects = CAdmin.Objects

Objects.Tables = {}
Objects.Inheritance = {}

Objects.BaseObject = {}
Objects.BaseObject.__index = Objects.BaseObject

function Objects.BaseObject:__init (...)
end

function Objects.BaseObject:__uninit (...)
end

local function CallInitTree (self, ...)
	for i = #self.__initTree, 1, -1 do
		self.__initTree [i] (self, ...)
	end
end

local function CallUninitTree (self, ...)
	for _, uninit in pairs (self.__uninitTree) do
		uninit (self, ...)
	end
end

local function FixObjectInheritance (objectType)
	local objectInfo = Objects.Inheritance [objectType]
	if not objectInfo or objectInfo.Inherited then
		return
	end
	local objectTable = Objects.Tables [objectType]
	local baseTable = Objects.Tables [objectInfo.Base]
	if baseTable then
		setmetatable (objectTable, baseTable)
		objectInfo.Inherited = true

		if not baseTable.Inherited then
			FixObjectInheritance (objectInfo.Base)
		end
	end

	--[[
		Now generate the constructor and destructor stack.
	]]

	local initTree = {}
	local uninitTree = {}
	while objectType do
		baseTable = Objects.Tables [objectType]
		if baseTable.__init then
			table.insert (initTree, baseTable.__init)
		end
		if baseTable.__uninit then
			table.insert (uninitTree, baseTable.__uninit)
		end
		objectType = Objects.Inheritance [objectType]
		if objectType then
			objectType = objectType.Base
		end
	end
	objectTable.__initTree = initTree
	objectTable.__uninitTree = uninitTree
end

function Objects.Create (objectType, ...)
	local objectTable = Objects.Tables [objectType]
	if not objectTable then
		print ("CAdmin: Attempted to construct an unknown class (" .. objectType .. ").")
		CAdmin.Debug.PrintStackTrace ()
		return nil
	end
	CAdmin.Profiler.EnterFunction ("CAdmin.Objects.Create", objectType)
	
	local objectInfo = Objects.Inheritance [objectType]
	if objectInfo and not objectInfo.Inherited then
		FixObjectInheritance (objectType)
	end

	local obj = {
		__init = CallInitTree,
		__uninit = CallUninitTree
	}
	setmetatable (obj, objectTable)

	obj:__init (...)

	CAdmin.Profiler.ExitFunction ()
	return obj
end

function Objects.GetBaseClass (name)
	local info = Objects.Inheritance [name]
	if info then
		return info.Base
	end
	return nil
end

function Objects.GetTable (name)
	return Objects.Tables [name]
end

function Objects.Register (name, base)
	if Objects.Tables [name] then
		print ("CAdmin: Attempted to reregister a class (" .. name .. ").")
		CAdmin.Debug.PrintStackTrace ()
		return Objects.Tables [name]
	end

	local tbl = {}
	tbl.__index = tbl
	
	base = base or "Object Base"
	if base and base ~= name then
		Objects.Inheritance [name] = {
			Base = base,
			Inherited = false
		}
	end
	Objects.Tables [name] = tbl

	return tbl
end


function Objects.RegisterExisting (name, table, base)
	if Objects.Tables [name] then
		print ("CAdmin: Attempted to reregister a class (" .. name .. ").")
		CAdmin.Debug.PrintStackTrace ()
		return Objects.Tables [name]
	end

	table.__index = table
	base = base or "Object Base"
	if base and base ~= name then
		Objects.Inheritance [name] = {
			Base = base,
			Inherited = false
		}
	end
	Objects.Tables [name] = table

	return table
end

Objects.RegisterExisting ("Object Base", Objects.BaseObject)

CAdmin.Lua.IncludeFolder ("shared/includes/objects")