local OBJ = CAdmin.Objects.Register ("Type")

function OBJ:__init (name, basetypeName)
	self.TypeName = name
	self.BaseTypeName = basetypeName

	self.AutocompleteObj = nil
	self.Converters = {}
	self.Serializer = nil
	self.Validator = nil
	
	self.CompleterClass = "CArgumentCompleter"
end

function OBJ:__uninit (name, basetype)
	self.AutocompleteObj = nil
	self.Converters = nil
end

--[[
	The autocomplete function should return a table of strings that can be
	used as the argument.
]]
function OBJ:Autocomplete (...)
	if self.AutocompleteObj then
		if type (self.AutocompleteObj) == "function" then
			local autocompleteTable = self.AutocompleteObj (...)
			table.sort (autocompleteTable)
			return autocompleteTable
		end
		return self.AutocompleteObj
	end
	return nil
end

function OBJ:CanAutocomplete ()
	if self.AutocompleteObj then
		return true
	end
	return false
end

--[[
	A converter converts an object of the given type to this type.
	It may return multiple objects in a table.
	
	srcTypeName is the type of the given object.
]]
function OBJ:Convert (ply, srcTypeName, obj, usedForLog, ...)
	local converted, reason = nil, nil
	if self.Converters [srcTypeName] then
		converted, reason = self.Converters [srcTypeName] (ply, obj, usedForLog, ...)
	elseif self.TypeName == "String" then
		converted, reason = CAdmin.Commands.GetType (srcTypeName):Serialize (ply, obj, usedForLog, ...)
	elseif self.TypeName == srcTypeName then
		CAdmin.Debug.PrintStackTrace ()
		converted = obj
	else
		reason = "No converters available for type \"" .. srcTypeName .. "\" to \"" .. self.TypeName .. "\"."
	end
	if not converted and not reason then
		reason = "Failed to convert argument from a \"" .. srcTypeName .. "\" to a \"" .. self.TypeName .. "\"."
	end
	return converted, reason
end

function OBJ:GetConverters ()
	return self.Converters
end

function OBJ:GetName ()
	return self.TypeName
end

function OBJ:GetBaseTypeName ()
	return self.BaseTypeName
end

function OBJ:GetCompleter ()
	return self.CompleterClass
end

function OBJ:GetType ()
	return "Type"
end

function OBJ:IsBaseType (typeName)
	local baseTypeName = self.BaseTypeName
	while baseTypeName do
		if typeName == baseTypeName then
			return true
		end
		baseTypeName = CAdmin.Commands.GetType (baseTypeName):GetBaseTypeName ()
	end
	return false
end

function OBJ:RegisterConverter (srcType, conversionFunc)
	self.Converters [srcType] = conversionFunc
end

function OBJ:Serialize (ply, obj, usedForLog, ...)
	if self.Serializer then
		return self.Serializer (ply, obj, usedForLog, ...)
	end
	if self.BaseTypeName then
		return CAdmin.Commands.GetType (self.BaseTypeName):Serialize (ply, obj, usedForLog, ...)
	end
	return nil
end

function OBJ:SetAutocomplete (autocomplete)
	self.AutocompleteObj = autocomplete
end

function OBJ:SetBaseType (type)
	self.BaseType = type
end

function OBJ:SetCompleter (completerClass)
	self.CompleterClass = completerClass
end

function OBJ:SetName (name)
	self.TypeName = name
end

function OBJ:SetSerializer (serializerFunc)
	self.Serializer = serializerFunc
end

function OBJ:Validate (argumentData, argument)
	if self.Validator then
		return self.Validator (argumentData, argument)
	end
	return true
end