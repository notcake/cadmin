local OBJ = CAdmin.Objects.Register ("Communications Pipe")

function OBJ:__init (targetPlayer)
	self.targetPlayer = targetPlayer
end