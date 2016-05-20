local OBJ = CAdmin.Objects.Register ("Group")

function OBJ:__init (groupName, displayName, baseGroup)
	self.Name = displayName
	self.DisplayName = displayName
	
	self.Base = baseGroup
	self.UserGroup = nil
	self.Icon = nil
	
	self.Console = false
	self.Default = false
	
	self.Allow = {}
end

function OBJ:GetDisplayName ()
	return self.DisplayName or self.Name
end

function OBJ:GetName ()
	return self.Name
end