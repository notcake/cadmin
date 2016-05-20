local OBJ = CAdmin.Objects.Register ("Argument")

function OBJ:__init (argumentTypeName)
	self.ArgumentTypeName = argumentTypeName

	self.Name = nil
	self.Optional = nil

	self.AutocompleteObj = nil
	self.AllowMultiple = true
	self.AllowSelf = true
	
	self.Parameters = nil
	
	self.PromptText = nil
	self.ReversePromptText = nil
	
	self.LastValue = nil
	self.ValidateFunc = nil
end

function OBJ:__uninit ()
	self.AutocompleteObj = nil
	self.Optional = nil
	self.LastValue = nil
	self.ValidateFunc = nil
end

function OBJ:AddFlag (flag)
	self.Parameters = self.Parameters or {}
	self.Parameters [flag] = true
	
	return self
end

function OBJ:Autocomplete (...)
	if self.AutocompleteObj then
		if type (self.AutocompleteObj) == "function" then
			return self.AutocompleteObj (...)
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

function OBJ:GetArgumentTypeName ()
	return self.ArgumentTypeName
end

function OBJ:GetArgumentType ()
	return CAdmin.Commands.GetType (self.ArgumentTypeName)
end

function OBJ:GetDefaultValue ()
	if type (self.Optional) == "function" then
		return self.Optional ()
	else
		return self.Optional
	end
end

function OBJ:GetLastValue ()
	return self.LastValue
end

function OBJ:GetName ()
	return self.Name
end

function OBJ:GetParameter (name)
	if not self.Parameters then
		return nil
	end
	return self.Parameters [name]
end

function OBJ:GetPromptText ()
	return self.PromptText
end

function OBJ:GetReversePromptText ()
	return self.ReversePromptText or self.PromptText
end

function OBJ:HasFlag (flag)
	if not self.Parameters or not self.Parameters [flag] then
		return false
	end
	return true
end

function OBJ:IsOptional ()
	return self.Optional ~= nil
end

function OBJ:SetArgumentType (argumentTypeName)
	self.ArgumentTypeName = argumentTypeName
	return self
end

function OBJ:SetAutocomplete (autocomplete)
	self.AutocompleteObj = autocomplete
	return self
end

function OBJ:SetLastValue (value)
	self.LastValue = value
	return self
end

function OBJ:SetName (name)
	self.Name = name
	return self
end

function OBJ:SetOptional (optional, default)
	if optional then
		if default == nil then
			self.Optional = 0
		else
			self.Optional = default
		end
	else
		self.Optional = nil
	end
	return self
end

function OBJ:SetParameter (name, value)
	self.Parameters = self.Parameters or {}
	self.Parameters [name] = value
	return self
end

function OBJ:SetPromptText (promptText)
	if CLIENT then
		self.PromptText = promptText
	end
	return self
end

function OBJ:SetReversePromptText (reversePromptText)
	if CLIENT then
		self.ReversePromptText = reversePromptText
	end
	return self
end

function OBJ:SetValidate (validateFunc)
	self.ValidateFunc = validateFunc
end

function OBJ:Validate (ply, value)
	local argumentType = self:GetArgumentType ()
	local valid, errorMessage = true, nil
	if self.ValidateFunc then
		valid, errorMessage = self:ValidateFunc (ply, value)
	end
	if argumentType then
		valid, errorMessage = argumentType:Validate (self, ply, value)
		if not valid then
			return valid, errorMessage
		end
	end
	return true, "Valid argument"
end