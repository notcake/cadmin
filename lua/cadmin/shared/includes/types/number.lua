local TYPE = CAdmin.Commands.RegisterType ("Number")
TYPE:SetCompleter ("CAdmin.NumberCompleter")

TYPE:RegisterConverter ("String", function (ply, number)
	return tonumber (number)
end)

TYPE:SetSerializer (function (ply, value)
	return tostring (value)
end)