local OBJ = CAdmin.Objects.Register ("Fallback Command", "Command")

function OBJ:__init (toggle)
	self.GetToggleState = nil
	self.SuppressLog = false
	self.FallbackType = CAdmin.FALLBACK_DEFAULT
	
	self.ToggleStateOveridden = false
end

function OBJ:CanExecute (ply, ...)
	return false
end

function OBJ:GetConsoleCommand ()
	if not CAdmin.Commands.Command [self.CommandID] then
		return nil
	end
	return CAdmin.Commands.Command [self.CommandID].ConsoleCommand
end

function OBJ:GetFallbackType ()
	return self.FallbackType
end

function OBJ:IsToggleStateOveridden ()
	return self.ToggleStateOveridden
end

function OBJ:SetConsoleCommand (cmd)
	return self
end

function OBJ:SetFallbackType (type)
	self.FallbackType = type
	return self
end

function OBJ:SetGetToggleState (getToggleState)
	self.GetToggleState = getToggleState
	self.ToggleStateOveridden = true
end

function OBJ:SetReverseConsoleCommand (cmd)
	return self
end

function OBJ:SetSuppressLog (suppress)
	self.SuppressLog = suppress
	return self
end

function OBJ:ShouldSuppressLog ()
	return self.SuppressLog
end